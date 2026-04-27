import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import path from "node:path";
import { err, info, ok, warn } from "./ui";

export interface RunResult {
  ok: boolean;
  exitCode: number;
}

export function resolveBaseDir(): string {
  // When compiled with `bun build --compile`, process.execPath is the .exe path.
  // When running via `bun run`, use cwd.
  const exePath = process.execPath;
  const isCompiled = !exePath.toLowerCase().endsWith("bun.exe");
  return isCompiled ? path.dirname(exePath) : process.cwd();
}

export function findFile(relativeCandidates: string[]): string | null {
  const base = resolveBaseDir();
  const cwd = process.cwd();
  const roots = [base, cwd, path.join(base, ".."), path.join(cwd, "..")];
  for (const root of roots) {
    for (const rel of relativeCandidates) {
      const full = path.resolve(root, rel);
      if (existsSync(full)) return full;
    }
  }
  return null;
}

export function findClientInstaller(): string | null {
  return findFile([
    "JHCIS-install-jre_jdk_64\\jHCIS-All-PCU\\jhcis-install-client-jre8-0-191_64.exe",
    "jHCIS-All-PCU\\jhcis-install-client-jre8-0-191_64.exe",
    "jhcis-install-client-jre8-0-191_64.exe",
  ]);
}

export function findUpdater(): string | null {
  return findFile(["JHCIS_Update.exe", "..\\JHCIS_Update.exe"]);
}

export function runProcess(exePath: string, args: string[] = []): Promise<RunResult> {
  return new Promise((resolve) => {
    info(`กำลังรัน: ${exePath} ${args.join(" ")}`.trim());
    const child = spawn(exePath, args, {
      stdio: "inherit",
      windowsHide: false,
      cwd: path.dirname(exePath),
    });
    child.on("error", (e) => {
      err(`รันไม่สำเร็จ: ${e.message}`);
      resolve({ ok: false, exitCode: -1 });
    });
    child.on("exit", (code) => {
      const exitCode = code ?? -1;
      if (exitCode === 0) ok(`เสร็จสิ้น (exit ${exitCode})`);
      else warn(`Process จบด้วย exit code = ${exitCode}`);
      resolve({ ok: exitCode === 0, exitCode });
    });
  });
}

export async function runClientInstaller(): Promise<RunResult> {
  const exe = findClientInstaller();
  if (!exe) {
    err(
      "ไม่พบไฟล์ jhcis-install-client-jre8-0-191_64.exe\n" +
        "  กรุณาวางไฟล์ .exe ตัวนี้ไว้ในโฟลเดอร์เดียวกับ JHCIS-install-jre_jdk_64",
    );
    return { ok: false, exitCode: -1 };
  }
  return runProcess(exe);
}

export async function runUpdater(): Promise<RunResult> {
  const exe = findUpdater();
  if (!exe) {
    err("ไม่พบไฟล์ JHCIS_Update.exe");
    return { ok: false, exitCode: -1 };
  }
  return runProcess(exe);
}
