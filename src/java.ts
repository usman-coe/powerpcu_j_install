import { spawn } from "node:child_process";
import { err, ok } from "./ui";

// JHCIS needs JRE 1.8 (8u191 recommended); Java Update would move it off that.
// Policy is read by jusched.exe for both 64-bit and 32-bit (WOW6432Node) Java.
const ROOTS = ["HKLM\\SOFTWARE", "HKLM\\SOFTWARE\\WOW6432Node"];

function reg(args: string[]): Promise<number> {
  return new Promise((resolve) => {
    const child = spawn("reg", args, { stdio: "ignore", windowsHide: true });
    child.on("error", () => resolve(-1));
    child.on("exit", (code) => resolve(code ?? -1));
  });
}

export async function disableJavaUpdate(): Promise<boolean> {
  let failed = 0;
  for (const root of ROOTS) {
    const policy = `${root}\\JavaSoft\\Java Update\\Policy`;
    for (const name of ["EnableJavaUpdate", "EnableAutoUpdateCheck", "NotifyDownload", "NotifyInstall"]) {
      if ((await reg(["add", policy, "/v", name, "/t", "REG_DWORD", "/d", "0", "/f"])) !== 0) failed++;
    }
    // Stop the scheduler from starting at logon; missing value is fine.
    await reg(["delete", `${root}\\Microsoft\\Windows\\CurrentVersion\\Run`, "/v", "SunJavaUpdateSched", "/f"]);
  }
  if (failed) {
    err(`ปิด Java auto-update ไม่สำเร็จ ${failed} รายการ (ต้องใช้สิทธิ์ Administrator)`);
    return false;
  }
  ok("ปิด Java auto-update แล้ว (คง JRE 1.8 ไว้สำหรับ JHCIS)");
  return true;
}
