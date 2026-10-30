import { spawn, spawnSync } from "node:child_process";
import path from "node:path";
import { err, info, ok, warn } from "./ui";

export interface InstalledApp {
  name: string;
  version: string;
  uninstall: string;
  kind: "java" | "client" | "server";
}

const UNINSTALL_KEYS = [
  "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*",
  "HKLM:\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*",
];

function classify(name: string): InstalledApp["kind"] | null {
  if (/^JHCIS-Client/i.test(name)) return "client";
  if (/^JHCIS-Server/i.test(name)) return "server";
  // "Java 8 Update 191 (64-bit)", "Java SE Development Kit 8 ..."; not "Java Auto Updater"
  if (/^Java(\(TM\))? (\d|SE)/i.test(name)) return "java";
  return null;
}

export function findInstalled(): InstalledApp[] {
  const ps =
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" +
    `ConvertTo-Json -Compress -InputObject @(Get-ItemProperty ${UNINSTALL_KEYS.map((k) => `'${k}'`).join(",")} -ErrorAction SilentlyContinue | ` +
    "Where-Object { $_.DisplayName -and $_.UninstallString } | Select-Object DisplayName,DisplayVersion,UninstallString)";
  const r = spawnSync("powershell", ["-NoProfile", "-NonInteractive", "-Command", ps], {
    encoding: "utf8",
    windowsHide: true,
  });
  if (r.status !== 0) {
    warn("อ่านรายการโปรแกรมที่ติดตั้งไม่ได้ - ข้ามการตรวจของเดิม");
    return [];
  }
  const rows = JSON.parse(r.stdout || "[]") as {
    DisplayName: string;
    DisplayVersion?: string;
    UninstallString: string;
  }[];
  const apps: InstalledApp[] = [];
  for (const row of rows) {
    const kind = classify(row.DisplayName);
    if (kind) {
      apps.push({ name: row.DisplayName, version: row.DisplayVersion ?? "", uninstall: row.UninstallString, kind });
    }
  }
  return apps;
}

/** Build the silent uninstall command line, or null if the uninstaller type is unknown. */
export function silentUninstallCommand(uninstall: string): string | null {
  // MSI (Oracle Java): MsiExec.exe /X{GUID}
  const guid = uninstall.match(/msiexec.*?(\{[0-9A-F-]+\})/i)?.[1];
  if (guid) return `msiexec /x ${guid} /qb /norestart`;
  // NSIS (JHCIS): uninst.exe. _?= makes it wait instead of re-spawning from %TEMP%,
  // and must be last and unquoted even with spaces.
  const exe = uninstall.replace(/"/g, "").trim();
  if (/\.exe$/i.test(exe)) return `"${exe}" /S _?=${path.dirname(exe)}`;
  return null;
}

// 1605 = product not installed, 3010 = success, reboot required
const OK_CODES = new Set([0, 1605, 3010]);

export function uninstallApp(app: InstalledApp): Promise<boolean> {
  const cmd = silentUninstallCommand(app.uninstall);
  if (!cmd) {
    err(`ไม่รู้วิธีถอน ${app.name} (${app.uninstall}) - กรุณาถอนเองใน Control Panel`);
    return Promise.resolve(false);
  }
  info(`กำลังถอนการติดตั้ง ${app.name} ...`);
  return new Promise((resolve) => {
    // shell: cmd /s /c keeps the quoted exe path and the unquoted _?= arg as written
    const child = spawn(cmd, { shell: true, stdio: "inherit", windowsHide: true });
    child.on("error", (e) => {
      err(`ถอน ${app.name} ไม่สำเร็จ: ${e.message}`);
      resolve(false);
    });
    child.on("exit", (code) => {
      if (OK_CODES.has(code ?? -1)) {
        ok(`ถอน ${app.name} แล้ว${code === 3010 ? " (ควร restart เครื่องภายหลัง)" : ""}`);
        resolve(true);
      } else {
        err(`ถอน ${app.name} ไม่สำเร็จ (exit ${code})`);
        resolve(false);
      }
    });
  });
}

if (import.meta.main) {
  const eq = (a: unknown, b: unknown) => console.assert(a === b, `${a} !== ${b}`);
  eq(classify("Java 8 Update 191 (64-bit)"), "java");
  eq(classify("Java SE Development Kit 8 Update 191 (64-bit)"), "java");
  eq(classify("Java Auto Updater"), null);
  eq(classify("JHCIS-Client-JRE-8.0.191_64bit 3.0.0"), "client");
  eq(classify("JHCIS-Server-JRE-8.0.191_64bit 3.0.0"), "server");
  eq(
    silentUninstallCommand("MsiExec.exe /X{26A24AE4-039D-4CA4-87B4-2F64180191F0}"),
    "msiexec /x {26A24AE4-039D-4CA4-87B4-2F64180191F0} /qb /norestart",
  );
  eq(
    silentUninstallCommand("C:\\Program Files\\jhcis-client\\uninst.exe"),
    '"C:\\Program Files\\jhcis-client\\uninst.exe" /S _?=C:\\Program Files\\jhcis-client',
  );
  console.log(findInstalled());
}
