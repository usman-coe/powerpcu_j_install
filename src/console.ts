import { spawnSync } from "node:child_process";

export function ensureUtf8Console(): void {
  if (process.platform !== "win32") return;
  try {
    spawnSync("chcp", ["65001"], { stdio: "ignore", windowsHide: true });
  } catch {
    // ignore — best effort; UAC manifest's activeCodePage UTF-8 is the primary mechanism
  }
}
