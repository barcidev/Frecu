import { joinPage } from "./join_page";

export { Room } from "./room";

/** Id de sala: 32 hex (128 bits). */
const ROOM_ID = /^[0-9a-f]{32}$/;

export const TURN_API = "https://rtc.live.cloudflare.com/v1/turn/keys";
export const CLOUDFLARE_STUN = "stun:stun.cloudflare.com:3478";
const TURN_TTL_SECONDS = 86400;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const parts = url.pathname.split("/").filter((p) => p.length > 0);

    if (parts[0] === "j" && parts.length === 2) {
      if (request.method !== "GET" && request.method !== "HEAD") {
        return methodNotAllowed("GET");
      }
      const id = parts[1];
      if (!ROOM_ID.test(id)) return badRequest();
      return joinPage(id);
    }

    if (parts[0] === "rooms" && parts.length === 3) {
      const [, id, action] = parts;
      if (!ROOM_ID.test(id)) return badRequest();
      const room = env.ROOMS.get(env.ROOMS.idFromName(id));

      if (action === "host" || action === "guest") {
        if (request.method !== "GET") return methodNotAllowed("GET");
        if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
          return new Response("Se esperaba un WebSocket", { status: 426 });
        }
        return room.fetch(request);
      }

      if (action === "turn") {
        if (request.method !== "POST") return methodNotAllowed("POST");
        if (!(await room.hasHost())) {
          return new Response("La sala no tiene anfitrión", { status: 404 });
        }
        return turnCredentials(env);
      }
    }

    return new Response("No encontrado", { status: 404 });
  },
} satisfies ExportedHandler<Env>;

async function turnCredentials(env: Env): Promise<Response> {
  if (!env.TURN_KEY_ID || !env.TURN_KEY) {
    return new Response("TURN no configurado", { status: 503 });
  }
  let upstream: Response;
  try {
    upstream = await fetch(
      `${TURN_API}/${encodeURIComponent(env.TURN_KEY_ID)}/credentials/generate`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${env.TURN_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ ttl: TURN_TTL_SECONDS }),
      },
    );
  } catch {
    return new Response("TURN no disponible", { status: 502 });
  }
  if (!upstream.ok) {
    return new Response("TURN no disponible", { status: 502 });
  }

  let body: { iceServers?: unknown };
  try {
    body = await upstream.json();
  } catch {
    return new Response("TURN no disponible", { status: 502 });
  }
  // Cloudflare puede responder un objeto o una lista; la app recibe lista.
  const raw = body.iceServers;
  const iceServers: unknown[] = Array.isArray(raw)
    ? [...raw]
    : raw !== undefined && raw !== null
      ? [raw]
      : [];
  if (!iceServers.some(hasCloudflareStun)) {
    iceServers.push({ urls: [CLOUDFLARE_STUN] });
  }
  return Response.json(
    { iceServers },
    { headers: { "Cache-Control": "no-store" } },
  );
}

function hasCloudflareStun(server: unknown): boolean {
  if (typeof server !== "object" || server === null) return false;
  const urls = (server as { urls?: unknown }).urls;
  const list = Array.isArray(urls) ? urls : [urls];
  return list.some(
    (u) => typeof u === "string" && u.split("?")[0] === CLOUDFLARE_STUN,
  );
}

function badRequest(): Response {
  return new Response("Id de sala inválido", { status: 400 });
}

function methodNotAllowed(allow: string): Response {
  return new Response("Método no permitido", {
    status: 405,
    headers: { Allow: allow },
  });
}
