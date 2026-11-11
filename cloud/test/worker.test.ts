import { exports } from "cloudflare:workers";
import { afterEach, describe, expect, it, vi } from "vitest";
import { CLOUDFLARE_STUN, TURN_API } from "../src/index";
import { MAX_GUESTS, sha256Hex } from "../src/room";

const BASE = "https://frecu.test";

let counter = 0;
/** Un id de sala nuevo por prueba (32 hex). */
function newRoomId(): string {
  counter += 1;
  return `${Date.now().toString(16)}${counter.toString(16)}`
    .padStart(32, "0")
    .slice(-32);
}

function worker(): Fetcher {
  return exports.default as unknown as Fetcher;
}

/** Socket de prueba con cola de mensajes y de cierre. */
class TestSocket {
  readonly messages: string[] = [];
  private waiters: Array<() => void> = [];
  closed: { code: number; reason: string } | undefined;

  constructor(readonly ws: WebSocket) {
    ws.accept();
    ws.addEventListener("message", (e) => {
      this.messages.push(e.data as string);
      this.wake();
    });
    ws.addEventListener("close", (e) => {
      this.closed = { code: e.code, reason: e.reason };
      this.wake();
    });
  }

  send(data: string | object): void {
    this.ws.send(typeof data === "string" ? data : JSON.stringify(data));
  }

  /** Espera el siguiente mensaje (texto). */
  async next(): Promise<string> {
    await this.until(() => this.messages.length > 0, "un mensaje");
    return this.messages.shift()!;
  }

  async nextJson(): Promise<Record<string, unknown>> {
    return JSON.parse(await this.next());
  }

  async waitClosed(): Promise<{ code: number; reason: string }> {
    await this.until(() => this.closed !== undefined, "el cierre");
    return this.closed!;
  }

  private wake(): void {
    const ws = this.waiters;
    this.waiters = [];
    for (const w of ws) w();
  }

  private async until(cond: () => boolean, what: string): Promise<void> {
    const deadline = Date.now() + 2000;
    while (!cond()) {
      if (Date.now() > deadline) throw new Error(`Se esperaba ${what}`);
      await new Promise<void>((resolve) => {
        this.waiters.push(resolve);
        setTimeout(resolve, 50);
      });
    }
  }
}

async function upgrade(
  path: string,
  headers: Record<string, string> = {},
): Promise<Response> {
  return worker().fetch(`${BASE}${path}`, {
    headers: { Upgrade: "websocket", ...headers },
  });
}

async function connectHost(id: string, secret = "secreto"): Promise<TestSocket> {
  const res = await upgrade(`/rooms/${id}/host?secret=${secret}`);
  expect(res.status).toBe(101);
  return new TestSocket(res.webSocket!);
}

async function connectGuest(
  id: string,
  ip = "203.0.113.7",
): Promise<TestSocket> {
  const res = await upgrade(`/rooms/${id}/guest`, { "CF-Connecting-IP": ip });
  expect(res.status).toBe(101);
  return new TestSocket(res.webSocket!);
}

/** Conecta un invitado y devuelve también su id `c` según el anfitrión. */
async function joinGuest(
  id: string,
  host: TestSocket,
  ip?: string,
): Promise<{ guest: TestSocket; c: string }> {
  const guest = await connectGuest(id, ip);
  const open = await host.nextJson();
  expect(open.t).toBe("open");
  return { guest, c: open.c as string };
}

/** Intercepta solo las llamadas a la API de TURN de Cloudflare. */
function mockTurnApi(reply: () => Response) {
  const realFetch = globalThis.fetch;
  return vi
    .spyOn(globalThis, "fetch")
    .mockImplementation(async (input, init) => {
      const url = input instanceof Request ? input.url : String(input);
      return url.startsWith(TURN_API) ? reply() : realFetch(input, init);
    });
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("ids de sala", () => {
  it("rechaza un id que no son 32 hex con 400", async () => {
    for (const bad of ["abc", "g".repeat(32), "A".repeat(32), "0".repeat(33)]) {
      expect((await upgrade(`/rooms/${bad}/host?secret=s`)).status).toBe(400);
      expect((await upgrade(`/rooms/${bad}/guest`)).status).toBe(400);
      const turn = await worker().fetch(`${BASE}/rooms/${bad}/turn`, {
        method: "POST",
      });
      expect(turn.status).toBe(400);
      expect((await worker().fetch(`${BASE}/j/${bad}`)).status).toBe(400);
    }
  });

  it("pide upgrade de WebSocket (426) en host y guest", async () => {
    const id = newRoomId();
    const res = await worker().fetch(`${BASE}/rooms/${id}/host?secret=s`);
    expect(res.status).toBe(426);
  });
});

describe("anfitrión", () => {
  it("el primero reclama la sala", async () => {
    const id = newRoomId();
    const host = await connectHost(id, "mio");
    expect(host.closed).toBeUndefined();
  });

  it("otro anfitrión con secreto ajeno recibe 403", async () => {
    const id = newRoomId();
    await connectHost(id, "mio");
    const res = await upgrade(`/rooms/${id}/host?secret=ajeno`);
    expect(res.status).toBe(403);
  });

  it("el reclamo sobrevive a la desconexión del anfitrión", async () => {
    const id = newRoomId();
    const host = await connectHost(id, "mio");
    host.ws.close(1000, "adiós");
    await host.waitClosed();
    const res = await upgrade(`/rooms/${id}/host?secret=ajeno`);
    expect(res.status).toBe(403);
  });

  it("sin secreto responde 400", async () => {
    const id = newRoomId();
    expect((await upgrade(`/rooms/${id}/host`)).status).toBe(400);
  });

  it("reconectar con el mismo secreto reemplaza la conexión anterior", async () => {
    const id = newRoomId();
    const first = await connectHost(id, "mio");
    const { guest: oldGuest } = await joinGuest(id, first);

    const second = await connectHost(id, "mio");
    expect((await first.waitClosed()).code).toBe(4000);
    await oldGuest.waitClosed();

    // El anfitrión nuevo sigue recibiendo invitados.
    const { guest, c } = await joinGuest(id, second);
    guest.send("hola");
    expect(await second.nextJson()).toEqual({ t: "msg", c, d: "hola" });
  });
});

describe("invitados", () => {
  it("sin anfitrión conectado reciben 404", async () => {
    const id = newRoomId();
    expect((await upgrade(`/rooms/${id}/guest`)).status).toBe(404);
  });

  it("el anfitrión recibe open con c y k", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    await connectGuest(id, "198.51.100.4");
    const open = await host.nextJson();
    const k = (await sha256Hex("198.51.100.4")).slice(0, 16);
    expect(open).toEqual({ t: "open", c: expect.any(String), k });
    expect((open.c as string).length).toBeGreaterThan(0);
  });

  it("cada invitado tiene su propio c", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    const a = await joinGuest(id, host);
    const b = await joinGuest(id, host);
    expect(a.c).not.toBe(b.c);
  });

  it("los mensajes del invitado llegan al anfitrión en un sobre msg", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    const { guest, c } = await joinGuest(id, host);
    const text = JSON.stringify({ type: "hello", name: "Ana" });
    guest.send(text);
    expect(await host.nextJson()).toEqual({ t: "msg", c, d: text });
  });

  it("el anfitrión le habla a un invitado concreto con d tal cual", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    const a = await joinGuest(id, host);
    const b = await joinGuest(id, host);
    host.send({ t: "msg", c: b.c, d: '{"type":"welcome"}' });
    expect(await b.guest.next()).toBe('{"type":"welcome"}');
    // a no recibe nada: los invitados no se oyen entre sí.
    a.guest.send("ping");
    expect(await host.nextJson()).toEqual({ t: "msg", c: a.c, d: "ping" });
    expect(a.guest.messages).toEqual([]);
  });

  it("el anfitrión cierra a un invitado con close", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    const { guest, c } = await joinGuest(id, host);
    host.send({ t: "close", c });
    await guest.waitClosed();
  });

  it("al irse un invitado el anfitrión recibe close", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    const { guest, c } = await joinGuest(id, host);
    guest.ws.close(1000, "me voy");
    expect(await host.nextJson()).toEqual({ t: "close", c });
  });

  it("si cae el anfitrión se cierran todos los invitados", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    const a = await joinGuest(id, host);
    const b = await joinGuest(id, host);
    host.ws.close(1000, "fin");
    expect((await a.guest.waitClosed()).code).toBe(1001);
    expect((await b.guest.waitClosed()).code).toBe(1001);
    expect((await upgrade(`/rooms/${id}/guest`)).status).toBe(404);
  });

  it("cierra al invitado que manda más de 64 KB", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    const { guest, c } = await joinGuest(id, host);
    guest.send("x".repeat(64 * 1024 + 1));
    expect((await guest.waitClosed()).code).toBe(1009);
    expect(await host.nextJson()).toEqual({ t: "close", c });
  });

  it(`admite como máximo ${MAX_GUESTS} invitados a la vez`, async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    for (let i = 0; i < MAX_GUESTS; i++) await joinGuest(id, host);
    expect((await upgrade(`/rooms/${id}/guest`)).status).toBe(503);
  });
});

describe("TURN", () => {
  it("responde 404 si la sala no tiene anfitrión", async () => {
    const id = newRoomId();
    const res = await worker().fetch(`${BASE}/rooms/${id}/turn`, {
      method: "POST",
    });
    expect(res.status).toBe(404);
  });

  it("pide credenciales a Cloudflare y añade el STUN", async () => {
    const id = newRoomId();
    await connectHost(id);
    const turn = {
      urls: ["turn:turn.cloudflare.com:3478?transport=udp"],
      username: "u",
      credential: "p",
    };
    const spy = mockTurnApi(() => Response.json({ iceServers: [turn] }));

    const res = await worker().fetch(`${BASE}/rooms/${id}/turn`, {
      method: "POST",
    });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({
      iceServers: [turn, { urls: [CLOUDFLARE_STUN] }],
    });

    const call = spy.mock.calls.find(([input]) =>
      String(input instanceof Request ? input.url : input).startsWith(TURN_API),
    )!;
    expect(String(call[0])).toBe(
      `${TURN_API}/clave-de-prueba/credentials/generate`,
    );
    const init = call[1]!;
    expect(new Headers(init.headers).get("Authorization")).toBe(
      "Bearer secreto-de-prueba",
    );
    expect(JSON.parse(init.body as string)).toEqual({ ttl: 86400 });
  });

  it("no duplica el STUN si Cloudflare ya lo trae", async () => {
    const id = newRoomId();
    await connectHost(id);
    const servers = [
      { urls: [CLOUDFLARE_STUN, "turn:turn.cloudflare.com:3478"], username: "u", credential: "p" },
    ];
    mockTurnApi(() => Response.json({ iceServers: servers }));
    const res = await worker().fetch(`${BASE}/rooms/${id}/turn`, {
      method: "POST",
    });
    expect(await res.json()).toEqual({ iceServers: servers });
  });

  it("responde 502 si Cloudflare falla", async () => {
    const id = newRoomId();
    await connectHost(id);
    mockTurnApi(() => new Response("no", { status: 500 }));
    const res = await worker().fetch(`${BASE}/rooms/${id}/turn`, {
      method: "POST",
    });
    expect(res.status).toBe(502);
  });
});

describe("página /j", () => {
  it("sirve HTML en español con el botón hacia frecu://join", async () => {
    const id = newRoomId();
    const res = await worker().fetch(`${BASE}/j/${id}`);
    expect(res.status).toBe(200);
    expect(res.headers.get("Content-Type")).toContain("text/html");
    expect(res.headers.get("Referrer-Policy")).toBe("no-referrer");
    const html = await res.text();
    expect(html).toContain('lang="es"');
    expect(html).toContain("Abrir en Frecu");
    expect(html).toContain("frecu://join?");
    expect(html).toContain(`q.set("x", "${id}")`);
    // El código sale del fragmento, nunca de la URL que ve el servidor.
    expect(html).toContain("location.hash");
    for (const key of ['"c"', '"n"', '"name"']) expect(html).toContain(key);
  });
});
