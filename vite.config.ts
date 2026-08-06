import { defineConfig } from "vite";
import { vitePlugin as remix } from "@remix-run/dev";
import path from "node:path";

export default defineConfig({
  plugins: [remix()],
  resolve: {
    alias: {
      "~": path.resolve(__dirname, "app"),
    },
  },
});
