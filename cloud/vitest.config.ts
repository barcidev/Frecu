import { cloudflareTest } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

// Secretos de prueba (wrangler los toma de process.env).
process.env.TURN_KEY_ID = "clave-de-prueba";
process.env.TURN_KEY = "secreto-de-prueba";

export default defineConfig({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: "./wrangler.toml" },
    }),
  ],
});
