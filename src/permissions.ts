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

// Well-known SIDs - language-independent (*S-1-... is the icacls syntax for SIDs).
// BUILTIN\Users (everyone who can log on locally) - what shows up as "Users" in
// the Security tab regardless of Windows display language.
const SID_BUILTIN_USERS = "*S-1-5-32-545";
const SID_BUILTIN_ADMINISTRATORS = "*S-1-5-32-544";

export async function grantFullPermissions(installPath: string): Promise<boolean> {
  if (!existsSync(installPath)) {
    err(`ไม่พบโฟลเดอร์: ${installPath}`);
    return false;
  }
  const user = process.env.USERNAME ?? "";
  info(`อัปเดท permission สำหรับ ${installPath}`);

  const grants = [
    `${SID_BUILTIN_USERS}:(OI)(CI)F`,          // Users group - Full Control
    `${SID_BUILTIN_ADMINISTRATORS}:(OI)(CI)F`, // Administrators - Full Control
  ];
  if (user) grants.push(`${user}:(OI)(CI)F`);  // Current user - Full Control

  const args = [installPath, "/T", "/C", "/Q"];
  for (const g of grants) {
    args.push("/grant", g);
  }

  const code = await runIcacls(args);
  if (code === 0) {
    ok(`อัปเดท permission สำเร็จ - Users / Administrators${user ? ` / ${user}` : ""} ได้ Full Control`);
    return true;
  }

  err(`ไม่สามารถอัปเดท permission ได้ (exit code = ${code})`);
  return false;
}
