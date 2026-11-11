import { DurableObject } from "cloudflare:workers";

/** Tamaño máximo de un mensaje de texto, en bytes. */
export const MAX_MESSAGE_BYTES = 64 * 1024;

/** Tope de conexiones de invitado simultáneas por sala. */
export const MAX_GUESTS = 16;

/** Tiempo sin anfitrión tras el cual la sala olvida su secreto. */
export const IDLE_CLEANUP_MS = 24 * 60 * 60 * 1000;

/**
 * Gracia tras caer un anfitrión con turno: los invitados siguen abiertos
 * mientras el sucesor toma la sala.
 */
export const HOST_GRACE_MS = 10 * 1000;

/** Aviso a los invitados de que el anfitrión se cayó y empieza la gracia. */
const HOST_LOST = JSON.stringify({ t: "host_lost" });

/** Turno: entero de 1 en adelante. */
const TERM = /^[1-9][0-9]{0,8}$/;

const HOST_TAG = "host";
const GUEST_TAG = "guest";
const SECRET_KEY = "secretHash";
const TERM_KEY = "term";
const GRACE_KEY = "grace";

type Attachment =
  | { role: "host"; retired?: boolean; term?: number }
  | { role: "guest"; c: string; closing?: boolean };

/**
 * Una sala: relé en estrella entre un anfitrión y sus invitados.
 *
 * El anfitrión es la autoridad de la frecu (valida el código, asigna ids,
 * enruta). Aquí solo se guarda el SHA-256 del secreto del anfitrión y se
 * pasan sobres `open` / `msg` / `close`. Los invitados nunca se hablan entre
 * sí.
 *
 * El anfitrión que se conecta con su turno (`term`) admite traspaso: si se
 * cae, sus invitados esperan [HOST_GRACE_MS] a que otro con el mismo secreto
 * y un turno mayor tome la sala. Un turno menor que el vigente se rechaza.
 */
export class Room extends DurableObject<Env> {
  /** Si la sala tiene un anfitrión conectado. */
  async hasHost(): Promise<boolean> {
    return this.currentHost() !== undefined;
  }

  override async fetch(request: Request): Promise<Response> {
    const role = new URL(request.url).pathname.split("/").pop();
    if (role === "host") return this.acceptHost(request);
    if (role === "guest") return this.acceptGuest(request);
    return new Response("No encontrado", { status: 404 });
  }

  private async acceptHost(request: Request): Promise<Response> {
    const params = new URL(request.url).searchParams;
    const claim = parseHostClaim(params.get("secret"), params.get("term"));
    if (claim instanceof Response) return claim;
    const refused =
      (await this.checkSecret(claim.secret)) ?? (await this.checkTerm(claim.term));
    if (refused !== undefined) return refused;

    // Un anfitrión que reconecta, o el sucesor que toma la sala, reemplaza
    // la conexión anterior; los invitados se cierran (volverán a entrar).
    for (const old of this.ctx.getWebSockets(HOST_TAG)) {
      old.serializeAttachment({ role: "host", retired: true });
      safeClose(old, 4000, "Anfitrión reemplazado");
    }
    this.closeAllGuests(1012, "Anfitrión reconectado");

    const [client, server] = Object.values(new WebSocketPair());
    this.ctx.acceptWebSocket(server, [HOST_TAG]);
    server.serializeAttachment({ role: "host", term: claim.term } satisfies Attachment);
    await this.ctx.storage.delete(GRACE_KEY);
    await this.ctx.storage.deleteAlarm();
    return new Response(null, { status: 101, webSocket: client });
  }

  /** El primero reclama la sala con su secreto; otro secreto → 403. */
  private async checkSecret(secret: string): Promise<Response | undefined> {
    const hash = await sha256Hex(secret);
    const stored = await this.ctx.storage.get<string>(SECRET_KEY);
    if (stored === undefined) {
      await this.ctx.storage.put(SECRET_KEY, hash);
    } else if (stored !== hash) {
      return new Response("La sala pertenece a otro anfitrión", {
        status: 403,
      });
    }
    return undefined;
  }

  /**
   * Un turno menor que el vigente → 409; uno mayor pasa a ser el vigente.
   * Sin turno (app anterior) cuenta como 0.
   */
  private async checkTerm(term: number | undefined): Promise<Response | undefined> {
    const current = (await this.ctx.storage.get<number>(TERM_KEY)) ?? 0;
    if ((term ?? 0) < current) {
      return new Response("Otro anfitrión lleva la sala con un turno mayor", {
        status: 409,
      });
    }
    if (term !== undefined && term > current) {
      await this.ctx.storage.put(TERM_KEY, term);
    }
    return undefined;
  }

  private async acceptGuest(request: Request): Promise<Response> {
    const host = this.currentHost();
    if (host === undefined) {
      return new Response("La sala no tiene anfitrión", { status: 404 });
    }
    if (this.openGuests().length >= MAX_GUESTS) {
      return new Response("Sala llena", { status: 503 });
    }

    const c = randomId();
    const ip = request.headers.get("CF-Connecting-IP") ?? "";
    const k = (await sha256Hex(ip)).slice(0, 16);

    const [client, server] = Object.values(new WebSocketPair());
    this.ctx.acceptWebSocket(server, [GUEST_TAG, guestTag(c)]);
    server.serializeAttachment({ role: "guest", c } satisfies Attachment);
    host.send(JSON.stringify({ t: "open", c, k }));
    return new Response(null, { status: 101, webSocket: client });
  }

  override async webSocketMessage(
    ws: WebSocket,
    message: string | ArrayBuffer,
  ): Promise<void> {
    const att = attachmentOf(ws);
    if (att === undefined) return;

    if (typeof message !== "string") {
      // Solo texto: el protocolo de Frecu es JSON.
      if (att.role === "guest") this.dropGuest(ws, 1003, "Solo texto");
      return;
    }
    if (utf8Length(message) > MAX_MESSAGE_BYTES) {
      if (att.role === "guest") this.dropGuest(ws, 1009, "Mensaje demasiado grande");
      return;
    }

    if (att.role === "guest") {
      if (att.closing) return;
      this.currentHost()?.send(JSON.stringify({ t: "msg", c: att.c, d: message }));
      return;
    }

    if (att.retired) return;
    let envelope: unknown;
    try {
      envelope = JSON.parse(message);
    } catch {
      return;
    }
    if (typeof envelope !== "object" || envelope === null) return;
    const { t, c, d } = envelope as Record<string, unknown>;
    if (typeof c !== "string") return;
    const guest = this.guestById(c);
    if (guest === undefined) return;
    if (t === "msg" && typeof d === "string") {
      try {
        guest.send(d);
      } catch {
        // El invitado ya se fue; su cierre llegará por webSocketClose.
      }
    } else if (t === "close") {
      this.dropGuest(guest, 1000, "Cerrado por el anfitrión", false);
    }
  }

  override async webSocketClose(
    ws: WebSocket,
    code: number,
    reason: string,
  ): Promise<void> {
    safeClose(ws, code === 1005 || code === 1006 ? 1000 : code, reason);
    await this.onGone(ws);
  }

  override async webSocketError(ws: WebSocket): Promise<void> {
    safeClose(ws, 1011, "Error");
    await this.onGone(ws);
  }

  override async alarm(): Promise<void> {
    if (this.currentHost() !== undefined) return;
    if (await this.ctx.storage.get<boolean>(GRACE_KEY)) {
      // Nadie tomó la sala en la gracia: se cierra como sin traspaso.
      await this.ctx.storage.delete(GRACE_KEY);
      this.closeAllGuests(1001, "El anfitrión no volvió");
      await this.ctx.storage.setAlarm(Date.now() + IDLE_CLEANUP_MS);
      return;
    }
    await this.ctx.storage.deleteAll();
  }

  private async onGone(ws: WebSocket): Promise<void> {
    const att = attachmentOf(ws);
    if (att === undefined) return;
    if (att.role === "guest") {
      if (att.closing) return;
      ws.serializeAttachment({ ...att, closing: true } satisfies Attachment);
      this.currentHost()?.send(JSON.stringify({ t: "close", c: att.c }));
      return;
    }
    if (att.retired) return;
    ws.serializeAttachment({ ...att, retired: true } satisfies Attachment);
    if (att.term === undefined) {
      this.closeAllGuests(1001, "El anfitrión se desconectó");
      await this.ctx.storage.setAlarm(Date.now() + IDLE_CLEANUP_MS);
      return;
    }
    // Con turno hay traspaso: los invitados esperan al sucesor.
    for (const guest of this.openGuests()) {
      try {
        guest.send(HOST_LOST);
      } catch {
        // El invitado ya se fue; su cierre llegará por webSocketClose.
      }
    }
    await this.ctx.storage.put(GRACE_KEY, true);
    await this.ctx.storage.setAlarm(Date.now() + HOST_GRACE_MS);
  }

  /** El anfitrión vigente (no reemplazado y con el socket abierto). */
  private currentHost(): WebSocket | undefined {
    return this.ctx.getWebSockets(HOST_TAG).find((ws) => {
      const att = attachmentOf(ws);
      return att?.role === "host" && !att.retired && ws.readyState === WebSocket.OPEN;
    });
  }

  private openGuests(): WebSocket[] {
    return this.ctx.getWebSockets(GUEST_TAG).filter((ws) => {
      const att = attachmentOf(ws);
      return att?.role === "guest" && !att.closing && ws.readyState === WebSocket.OPEN;
    });
  }

  private guestById(c: string): WebSocket | undefined {
    return this.ctx.getWebSockets(guestTag(c)).find((ws) => {
      const att = attachmentOf(ws);
      return att?.role === "guest" && !att.closing;
    });
  }

  private closeAllGuests(code: number, reason: string): void {
    for (const ws of this.ctx.getWebSockets(GUEST_TAG)) {
      this.dropGuest(ws, code, reason, false);
    }
  }

  /**
   * Cierra a un invitado. Con [notifyHost] avisa al anfitrión con un sobre
   * `close`; si el cierre lo pidió el anfitrión (o se fue), no hace falta.
   */
  private dropGuest(ws: WebSocket, code: number, reason: string, notifyHost = true): void {
    const att = attachmentOf(ws);
    if (att?.role !== "guest" || att.closing) return;
    ws.serializeAttachment({ ...att, closing: true } satisfies Attachment);
    safeClose(ws, code, reason);
    if (notifyHost) {
      this.currentHost()?.send(JSON.stringify({ t: "close", c: att.c }));
    }
  }
}

/** El secreto y el turno de un anfitrión que llega, o el 400 si no valen. */
function parseHostClaim(
  secret: string | null,
  term: string | null,
): { secret: string; term?: number } | Response {
  if (secret === null || secret.length === 0 || secret.length > 256) {
    return new Response("Secreto inválido", { status: 400 });
  }
  if (term !== null && !TERM.test(term)) {
    return new Response("Turno inválido", { status: 400 });
  }
  return { secret, term: term === null ? undefined : Number(term) };
}

function guestTag(c: string): string {
  return `c:${c}`;
}

function attachmentOf(ws: WebSocket): Attachment | undefined {
  return (ws.deserializeAttachment() as Attachment | null) ?? undefined;
}

function safeClose(ws: WebSocket, code: number, reason: string): void {
  try {
    ws.close(code, reason);
  } catch {
    // Ya estaba cerrado.
  }
}

function randomId(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  return toHex(bytes);
}

function utf8Length(text: string): number {
  // Atajo: cada unidad UTF-16 ocupa a lo sumo 3 bytes en UTF-8.
  if (text.length * 3 <= MAX_MESSAGE_BYTES) return text.length;
  return new TextEncoder().encode(text).byteLength;
}

export async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return toHex(new Uint8Array(digest));
}

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}
