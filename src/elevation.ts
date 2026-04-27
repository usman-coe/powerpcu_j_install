import { spawn } from "node:child_process";
import { err, info, warn } from "./ui";

const ELEVATED_FLAG = "--elevated";

export function isElevated(): Promise<boolean> {
  // `net session` returns 0 when run as admin, non-zero otherwise.
  return new Promise((resolve) => {
    const child = spawn("net", ["session"], {
      stdio: "ignore",
      windowsHide: true,
    });
    child.on("error", () => resolve(false));
    child.on("exit", (code) => resolve(code === 0));
  });
}

export function isCompiledExe(): boolean {
  return !process.execPath.toLowerCase().endsWith("bun.exe");
}

export function alreadyRelaunched(): boolean {
  return process.argv.includes(ELEVATED_FLAG);
}

function quoteForPwsh(s: string): string {
  return `'${s.replace(/'/g, "''")}'`;
}

export function relaunchAsAdmin(): Promise<void> {
  return new Promise((resolve, reject) => {
    const exePath = process.execPath;
    const baseArgs = isCompiledExe() ? [] : [process.argv[1] ?? ""];
    const userArgs = process.argv.slice(2).filter((a) => a !== ELEVATED_FLAG);
    const passArgs = [...baseArgs, ...userArgs, ELEVATED_FLAG].filter(Boolean);

    const argList =
      passArgs.length > 0 ? ` -ArgumentList @(${passArgs.map(quoteForPwsh).join(",")})` : "";

    const psCommand =
      `try { Start-Process -FilePath ${quoteForPwsh(exePath)} -Verb RunAs${argList}; exit 0 } ` +
      `catch { exit 1 }`;

    info("กำลังขอสิทธิ์ Administrator (Windows จะแสดงหน้าต่าง UAC)...");

    const child = spawn("powershell", ["-NoProfile", "-NonInteractive", "-Command", psCommand], {
      stdio: "ignore",
      windowsHide: true,
    });
    child.on("error", (e) => reject(e));
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`UAC ถูกยกเลิก (exit ${code})`));
    });
  });
}

/**
 * Ensures the current process runs with admin rights.
 * Returns true to continue execution, false if the caller should exit.
 */
export async function ensureElevated(): Promise<boolean> {
  if (await isElevated()) return true;

  warn("โปรแกรมยังไม่ได้รันด้วยสิทธิ์ Administrator");
  info("ตัวติดตั้ง JHCIS และคำสั่ง icacls ต้องการสิทธิ์ Administrator");

  try {
    await relaunchAsAdmin();
    info("เปิดหน้าต่างใหม่ในโหมด Admin แล้ว - หน้าต่างนี้จะปิดตัวเอง");
    return false;
  } catch (e) {
    err(`ขอสิทธิ์ Administrator ไม่สำเร็จ: ${(e as Error).message}`);
    warn("จะดำเนินการต่อโดยไม่มีสิทธิ์ Admin (อาจติดตั้งไม่สำเร็จ)");
    return true;
  }
}
