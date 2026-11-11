// AC11: CUANDO el anfitrión de una frecu por internet, conectado con su turno (`?term=N`), se cae ENTONCES el Worker no cierra a los invitados durante la gracia (10 s) y les envía `{"t":"host_lost"}`. Acepta como anfitrión a quien presenta el mismo secreto con un turno igual o mayor, y si hay uno conectado con un turno menor lo retira (4000) y cierra a sus invitados. Rechaza con 409 a quien llega con un turno menor que el vigente. Si nadie toma la frecu en la gracia, cierra a los invitados (1001) y no admite invitados nuevos (404). Un anfitrión sin turno (app anterior) sigue como hoy: al caer, se cierran sus invitados.
import { env, exports } from "cloudflare:workers";
import { runDurableObjectAlarm } from "cloudflare:test";
import { describe, expect, it } from "vitest";
import { HOST_GRACE_MS } from "../src/room";

const BASE = "https://frecu.test";

let counter = 0;
/** Un id de sala nuevo por prueba (32 hex). */
function newRoomId(): string {
  counter += 1;
  return `${Date.now().toString(16)}ab${counter.toString(16)}`
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

  send(data: string): void {
    this.ws.send(data);
  }

  async nextJson(): Promise<Record<string, unknown>> {
    await this.until(() => this.messages.length > 0, "un mensaje");
    return JSON.parse(this.messages.shift()!);
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

async function upgrade(path: string): Promise<Response> {
  return worker().fetch(`${BASE}${path}`, {
    headers: { Upgrade: "websocket", "CF-Connecting-IP": "203.0.113.9" },
  });
}

function hostPath(id: string, term?: number | string, secret = "mio"): string {
  const t = term === undefined ? "" : `&term=${term}`;
  return `/rooms/${id}/host?secret=${secret}${t}`;
}

async function connectHost(id: string, term?: number): Promise<TestSocket> {
  const res = await upgrade(hostPath(id, term));
  expect(res.status).toBe(101);
  return new TestSocket(res.webSocket!);
}

/** Conecta un invitado y espera su `open` en [host]. */
async function joinGuest(id: string, host: TestSocket): Promise<TestSocket> {
  const res = await upgrade(`/rooms/${id}/guest`);
  expect(res.status).toBe(101);
  const guest = new TestSocket(res.webSocket!);
  expect((await host.nextJson()).t).toBe("open");
  return guest;
}

/** Espera a que la sala marque su gracia antes de correr su alarma. */
async function settle(): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, 100));
}

function stub(id: string): DurableObjectStub {
  return env.ROOMS.get(env.ROOMS.idFromName(id));
}

describe("traspaso por internet", () => {
  it("AC11: la gracia dura unos 10 s", () => {
    expect(HOST_GRACE_MS).toBe(10_000);
  });

  it("AC11: al caer un anfitrión con turno, sus invitados siguen abiertos y reciben host_lost", async () => {
    const id = newRoomId();
    const host = await connectHost(id, 1);
    const a = await joinGuest(id, host);
    const b = await joinGuest(id, host);

    host.ws.close(1000, "se fue");
    expect(await a.nextJson()).toEqual({ t: "host_lost" });
    expect(await b.nextJson()).toEqual({ t: "host_lost" });
    expect(a.closed).toBeUndefined();
    expect(b.closed).toBeUndefined();
    // Sin anfitrión no entran invitados nuevos.
    expect((await upgrade(`/rooms/${id}/guest`)).status).toBe(404);
  });

  it("AC11: el sucesor con el mismo secreto y un turno mayor toma la sala en la gracia", async () => {
    const id = newRoomId();
    const host = await connectHost(id, 1);
    const waiting = await joinGuest(id, host);
    host.ws.close(1000, "se fue");
    expect(await waiting.nextJson()).toEqual({ t: "host_lost" });

    const heir = await connectHost(id, 2);
    // Quien esperaba vuelve a entrar por su socket de invitado.
    expect((await waiting.waitClosed()).code).toBe(1012);
    const guest = await joinGuest(id, heir);
    guest.send("hola");
    expect(await heir.nextJson()).toMatchObject({ t: "msg", d: "hola" });

    // La gracia terminó: la alarma ya no cierra a nadie.
    await runDurableObjectAlarm(stub(id));
    await settle();
    expect(guest.closed).toBeUndefined();
  });

  it("AC11: un turno mayor retira al anfitrión conectado y cierra a sus invitados", async () => {
    const id = newRoomId();
    const host = await connectHost(id, 1);
    const guest = await joinGuest(id, host);

    await connectHost(id, 2);
    expect((await host.waitClosed()).code).toBe(4000);
    expect((await guest.waitClosed()).code).toBe(1012);
  });

  it("AC11: el mismo turno reemplaza la conexión, como al reconectar", async () => {
    const id = newRoomId();
    const first = await connectHost(id, 1);
    await connectHost(id, 1);
    expect((await first.waitClosed()).code).toBe(4000);
  });

  it("AC11: rechaza con 409 a quien vuelve con un turno menor", async () => {
    const id = newRoomId();
    const old = await connectHost(id, 1);
    const heir = await connectHost(id, 2);
    await old.waitClosed();

    expect((await upgrade(hostPath(id, 1))).status).toBe(409);
    // Sin turno cuenta como el más bajo.
    expect((await upgrade(hostPath(id))).status).toBe(409);
    expect(heir.closed).toBeUndefined();

    // También sin anfitrión conectado.
    heir.ws.close(1000, "se fue");
    await heir.waitClosed();
    await settle();
    expect((await upgrade(hostPath(id, 1))).status).toBe(409);
    expect((await upgrade(hostPath(id, 3))).status).toBe(101);
  });

  it("AC11: un turno mal formado responde 400", async () => {
    const id = newRoomId();
    for (const bad of ["0", "-1", "uno", "1.5", ""]) {
      expect((await upgrade(hostPath(id, bad))).status).toBe(400);
    }
  });

  it("AC11: si nadie toma la sala en la gracia, se cierran los invitados", async () => {
    const id = newRoomId();
    const host = await connectHost(id, 1);
    const guest = await joinGuest(id, host);
    host.ws.close(1000, "se fue");
    expect(await guest.nextJson()).toEqual({ t: "host_lost" });
    await settle();

    expect(await runDurableObjectAlarm(stub(id))).toBe(true);
    expect((await guest.waitClosed()).code).toBe(1001);
    expect((await upgrade(`/rooms/${id}/guest`)).status).toBe(404);
    // El reclamo sigue: la sala olvida su secreto más tarde, como siempre.
    expect((await upgrade(hostPath(id, 1, "ajeno"))).status).toBe(403);
  });

  it("AC11: un anfitrión sin turno (app anterior) sigue como hoy", async () => {
    const id = newRoomId();
    const host = await connectHost(id);
    const guest = await joinGuest(id, host);
    host.ws.close(1000, "se fue");
    expect((await guest.waitClosed()).code).toBe(1001);
    expect(guest.messages).toEqual([]);
  });
});
