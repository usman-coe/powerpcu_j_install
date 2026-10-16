import { $ } from "bun";
import { rcedit } from "rcedit";
import { resolve } from "node:path";
import { existsSync } from "node:fs";

const required = [
  "JHCIS-install-jre_jdk_64/jHCIS-All-PCU/jhcis-install-client-jre8-0-191_64.exe",
  "JHCIS_Update.exe",
];
const missing = required.filter((f) => !existsSync(f));
if (missing.length) {
  console.error(
    `✘ ไม่พบไฟล์ติดตั้ง (ดาวน์โหลดจาก https://jhcis.moph.go.th/download/):\n` +
      missing.map((f) => `  - ${f}`).join("\n"),
  );
  process.exit(1);
}

const exePath = resolve("dist/jhcis-installer.exe");
const manifest = resolve("app.manifest");

console.log("→ Compiling exe...");
await $`bun build --compile --target=bun-windows-x64 --minify --sourcemap --outfile ${exePath} ./index.ts`;

console.log("→ Embedding UAC manifest...");
await rcedit(exePath, { "application-manifest": manifest });

console.log(`✔ Built ${exePath} (requires admin, UTF-8 active codepage)`);
