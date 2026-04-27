import { existsSync } from "node:fs";
import { spawn } from "node:child_process";
import { err, info, ok } from "./ui";

export const DEFAULT_INSTALL_PATH = "C:\\Program Files\\jhcis-client";

export const DEFAULT_INSTALL_PATHS = [
  DEFAULT_INSTALL_PATH,
  "C:\\Program Files (x86)\\jhcis-client",
  "C:\\JHCIS",
  "C:\\jhcis",
  "C:\\JHCIS-Client",
  "C:\\Program Files\\JHCIS",
  "C:\\Program Files (x86)\\JHCIS",
];

export function detectInstallPath(): string | null {
  for (const p of DEFAULT_INSTALL_PATHS) {
    if (existsSync(p)) return p;
  }
  return null;
}

function runIcacls(args: string[]): Promise<number> {
  return new Promise((resolve) => {
    const child = spawn("icacls", args, { stdio: "inherit", windowsHide: true });
    child.on("error", () => resolve(-1));
    child.on("exit", (code) => resolve(code ?? -1));
  });
}

export async function grantFullPermissions(installPath: string): Promise<boolean> {
  if (!existsSync(installPath)) {
    err(`ไม่พบโฟลเดอร์: ${installPath}`);
    return false;
  }
  const user = process.env.USERNAME ?? "Users";
  info(`อัปเดท permission สำหรับ ${installPath} (user: ${user})`);

  const code = await runIcacls([installPath, "/grant", `${user}:(OI)(CI)F`, "/T", "/C", "/Q"]);
  if (code === 0) {
    ok(`อัปเดท permission สำหรับ user "${user}" สำเร็จ (Full Control)`);
    return true;
  }

  err(`ไม่สามารถอัปเดท permission ได้ (exit code = ${code})`);
  return false;
}
