/**
 * Página mínima para unirse a una frecu desde un enlace.
 *
 * El código de la frecu viaja en el fragmento (`#c=…&n=…&name=…`): el
 * navegador nunca lo manda al servidor, así que no llega a los registros del
 * Worker. El script de la página arma `frecu://join?x=<id>&c=…`.
 *
 * [id] ya viene validado (32 hex), así que se puede incrustar sin escapar.
 */
export function joinPage(id: string): Response {
  const html = `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
<meta name="robots" content="noindex">
<title>Unirse a una frecu</title>
<style>
  :root { color-scheme: light dark; --bg: #f6f6f1; --fg: #15160f; --muted: #5b5e4f; --accent: #c4e05c; }
  @media (prefers-color-scheme: dark) { :root { --bg: #121310; --fg: #eef0e6; --muted: #a3a796; } }
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: var(--bg); color: var(--fg);
         font: 16px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 420px; padding: 24px 16px; text-align: center; }
  h1 { font-size: 1.5rem; margin: 0 0 8px; }
  p { color: var(--muted); margin: 0 0 24px; }
  a.btn { display: inline-block; padding: 14px 28px; border-radius: 999px; background: var(--accent); color: #15160f;
          font-weight: 600; text-decoration: none; }
  a.btn[aria-disabled="true"] { opacity: .5; pointer-events: none; }
  small { display: block; margin-top: 24px; color: var(--muted); }
</style>
</head>
<body>
<main>
  <h1 id="title">Te invitaron a una frecu</h1>
  <p id="hint">Abre el enlace en el teléfono que tiene Frecu instalada.</p>
  <a class="btn" id="open" href="#" aria-disabled="true">Abrir en Frecu</a>
  <small>¿No tienes Frecu? Instálala y vuelve a abrir este enlace.</small>
</main>
<script>
(function () {
  var frag = new URLSearchParams(location.hash.slice(1));
  var c = frag.get("c");
  var btn = document.getElementById("open");
  if (!c) {
    document.getElementById("hint").textContent = "Al enlace le falta el código de la frecu.";
    return;
  }
  var q = new URLSearchParams();
  q.set("x", "${id}");
  q.set("c", c);
  var n = frag.get("n");
  if (n) q.set("n", n);
  var name = frag.get("name");
  if (name) {
    q.set("name", name);
    document.getElementById("title").textContent = "Te invitaron a " + name;
  }
  btn.href = "frecu://join?" + q.toString();
  btn.removeAttribute("aria-disabled");
})();
</script>
</body>
</html>
`;
  return new Response(html, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=3600",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
      "Content-Security-Policy":
        "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
    },
  });
}
