import { spawn } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import clientInstallerEmbed from "../JHCIS-install-jre_jdk_64/jHCIS-All-PCU/jhcis-install-client-jre8-0-191_64.exe" with {
  type: "file",
};
import updaterEmbed from "../JHCIS_Update.exe" with { type: "file" };
import getdownEmbed from "./getdown.txt" with { type: "text" };
import { err, info, ok, warn } from "./ui";

export interface RunResult {
  ok: boolean;
  exitCode: number;
}

export function resolveBaseDir(): string {
  const exePath = process.execPath;
  const isCompiled = !exePath.toLowerCase().endsWith("bun.exe");
  return isCompiled ? path.dirname(exePath) : process.cwd();
}

function findExternalFile(relativeCandidates: string[]): string | null {
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

let extractDir: string | null = null;
function getExtractDir(): string {
  if (extractDir) return extractDir;
  extractDir = path.join(os.tmpdir(), `jhcis-installer-${process.pid}`);
  mkdirSync(extractDir, { recursive: true });
  return extractDir;
}

async function extractEmbedded(embeddedPath: string, fileName: string): Promise<string> {
  const outDir = getExtractDir();
  const outPath = path.join(outDir, fileName);
  if (existsSync(outPath)) return outPath;
  info(`กำลังเตรียมไฟล์ติดตั้ง: ${fileName} ...`);
  await Bun.write(outPath, Bun.file(embeddedPath));
  return outPath;
}

export async function locateClientInstaller(): Promise<string> {
  const external = findExternalFile([
    "JHCIS-install-jre_jdk_64\\jHCIS-All-PCU\\jhcis-install-client-jre8-0-191_64.exe",
    "jHCIS-All-PCU\\jhcis-install-client-jre8-0-191_64.exe",
    "jhcis-install-client-jre8-0-191_64.exe",
  ]);
  if (external) return external;
  return await extractEmbedded(clientInstallerEmbed, "jhcis-install-client-jre8-0-191_64.exe");
}

export async function locateUpdater(): Promise<string> {
  const external = findExternalFile(["JHCIS_Update.exe", "..\\JHCIS_Update.exe"]);
  if (external) return external;
  return await extractEmbedded(updaterEmbed, "JHCIS_Update.exe");
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
  try {
    const exe = await locateClientInstaller();
    return runProcess(exe);
  } catch (e) {
    err(`เตรียมตัวติดตั้งไม่สำเร็จ: ${(e as Error).message}`);
    return { ok: false, exitCode: -1 };
  }
}

// ประกาศ 26 ก.พ. 69: วิธีอัปเดตใหม่ทำให้บางเครื่องเปิด JHCIS ไม่ได้ แก้โดยวาง getdown.txt นี้ทับในโฟลเดอร์ติดตั้ง
const GETDOWN_URL = "https://jhcis.moph.go.th/files/getdown.txt";

export async function fixGetdown(installPath: string): Promise<boolean> {
  if (!existsSync(installPath)) {
    err(`ไม่พบโฟลเดอร์: ${installPath}`);
    return false;
  }
  let text = getdownEmbed;
  try {
    const r = await fetch(GETDOWN_URL, { signal: AbortSignal.timeout(10_000) });
    const remote = r.ok ? await r.text() : "";
    if (remote.includes("appbase")) text = remote;
    else warn("ไฟล์ getdown.txt จากเว็บไม่ถูกต้อง - ใช้ไฟล์ที่แนบมากับโปรแกรมแทน");
  } catch {
    warn("ดาวน์โหลด getdown.txt ไม่ได้ (ไม่มีอินเทอร์เน็ต?) - ใช้ไฟล์ที่แนบมากับโปรแกรมแทน");
  }
  const target = path.join(installPath, "getdown.txt");
  try {
    if (existsSync(target)) copyFileSync(target, `${target}.bak`);
    writeFileSync(target, text);
    ok(`วาง getdown.txt ที่ ${target} แล้ว`);
    return true;
  } catch (e) {
    err(`เขียน getdown.txt ไม่สำเร็จ: ${(e as Error).message}`);
    return false;
  }
}

export async function runUpdater(): Promise<RunResult> {
  try {
    const exe = await locateUpdater();
    return runProcess(exe);
  } catch (e) {
    err(`เตรียม updater ไม่สำเร็จ: ${(e as Error).message}`);
    return { ok: false, exitCode: -1 };
  }
}
