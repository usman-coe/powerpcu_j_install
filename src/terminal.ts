import { spawn, spawnSync } from "node:child_process";

const WT_RELAUNCH_FLAG = "--wt-relaunched";

export function isInWindowsTerminal(): boolean {
  return !!process.env.WT_SESSION;
}

export function alreadyRelaunchedInWt(): boolean {
  return process.argv.includes(WT_RELAUNCH_FLAG);
}

export function hasWindowsTerminal(): boolean {
  if (process.platform !== "win32") return false;
  const r = spawnSync("where.exe", ["wt.exe"], { stdio: "ignore", windowsHide: true });
  return r.status === 0;
}

/**
 * Spawn wt.exe with the current exe as a detached child.
 * conhost can't shape Thai combining marks; Windows Terminal can.
 * Caller must exit after this returns.
 */
export function relaunchInWindowsTerminal(): void {
  const args = process.argv.slice(2).filter((a) => a !== WT_RELAUNCH_FLAG);
  const child = spawn(
    "wt.exe",
    ["--", process.execPath, ...args, WT_RELAUNCH_FLAG],
    { detached: true, stdio: "ignore", windowsHide: false },
  );
  child.unref();
}
