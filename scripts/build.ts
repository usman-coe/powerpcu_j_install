import { $ } from "bun";
import { rcedit } from "rcedit";
import { resolve } from "node:path";

const exePath = resolve("dist/jhcis-installer.exe");
const manifest = resolve("app.manifest");

console.log("→ Compiling exe...");
await $`bun build --compile --target=bun-windows-x64 --minify --sourcemap --outfile ${exePath} ./index.ts`;

console.log("→ Embedding UAC manifest...");
await rcedit(exePath, { "application-manifest": manifest });

console.log(`✔ Built ${exePath} (requires admin, UTF-8 active codepage)`);
