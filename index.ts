import { ensureElevated, isCompiledExe } from "./src/elevation";
import { fixGetdown, runClientInstaller, runUpdater } from "./src/installer";
import {
  DEFAULT_INSTALL_PATH,
  detectInstallPath,
  grantFullPermissions,
} from "./src/permissions";
import { scanLan, type MysqlServer } from "./src/scanner";
import { disableJavaUpdate } from "./src/java";
import { findInstalled, uninstallApp } from "./src/uninstall";
import { ensureUtf8Console } from "./src/console";
import {
  alreadyRelaunchedInWt,
  hasWindowsTerminal,
  isInWindowsTerminal,
  relaunchInWindowsTerminal,
} from "./src/terminal";
import { ask, banner, color, confirm, err, info, ok, pause, step, warn } from "./src/ui";

const DEFAULT_PORT = 3333;
const DEFAULT_PASSWORD = "123456";
const TOTAL_STEPS = 6;

async function main(): Promise<number> {
  ensureUtf8Console();

  // conhost can't shape Thai combining marks. If we're in conhost and Windows
  // Terminal is available, relaunch there so สระ/วรรณยุกต์ stack correctly.
  if (
    isCompiledExe() &&
    !isInWindowsTerminal() &&
    !alreadyRelaunchedInWt() &&
    hasWindowsTerminal()
  ) {
    process.stdout.write("Opening Windows Terminal for Thai display...\n");
    relaunchInWindowsTerminal();
    return 0;
  }

  banner();

  if (!(await ensureElevated())) {
    // A new elevated process has been launched; exit this one quietly.
    return 0;
  }

  console.log(
    `\n${color.dim}โปรแกรมนี้จะ:${color.reset}\n` +
      `  1. ค้นหา MySQL server ของ JHCIS ในวงแลน (port ${DEFAULT_PORT})\n` +
      `  2. ถอน JHCIS Client / Java ตัวเดิม (ถ้ามี) แล้วติดตั้ง JHCIS Client ใหม่\n` +
      `  3. อัปเดท permission ของโฟลเดอร์ที่ติดตั้ง\n` +
      `  4. (ถ้าต้องการ) อัปเดท version ใหม่ของ JHCIS\n` +
      `  5. วาง getdown.txt แก้ปัญหาเปิดโปรแกรมไม่ได้\n` +
      `  6. ปิด Java auto-update (JHCIS ต้องใช้ JRE 1.8)\n`,
  );

  if (!(await confirm("เริ่มกระบวนการติดตั้ง?", true))) {
    warn("ยกเลิกโดยผู้ใช้");
    await pause();
    return 0;
  }

  const installed = findInstalled();
  const isServerMachine = installed.some((a) => a.kind === "server");
  if (isServerMachine) {
    warn(
      `เครื่องนี้มี ${color.bold}JHCIS Server${color.reset} ติดตั้งอยู่ - โปรแกรมนี้ใช้กับเครื่องลูกเท่านั้น ` +
        "(จะไม่ถอน Java เพราะเครื่องแม่ต้องใช้)",
    );
    if (!(await confirm("ดำเนินการต่อจริงหรือไม่?", false))) {
      warn("ยกเลิกโดยผู้ใช้");
      await pause();
      return 0;
    }
  }

  // ── Step 1: Discover server ───────────────────────────────────────
  step(1, TOTAL_STEPS, "ค้นหา JHCIS Server ในวงแลน");
  const portStr = await ask(`Port ของ MySQL บนเครื่องแม่:`, String(DEFAULT_PORT));
  const port = parseInt(portStr, 10) || DEFAULT_PORT;
  let servers: MysqlServer[] = [];
  try {
    servers = await scanLan(port);
  } catch (e) {
    err(`สแกนล้มเหลว: ${(e as Error).message}`);
  }

  let serverIp: string | null = null;
  if (servers.length === 0) {
    warn("ไม่พบ MySQL server ในวงแลน");
    const manual = await ask("กรอก IP เครื่องแม่เอง (หรือ Enter เพื่อข้าม):");
    if (manual) serverIp = manual;
  } else if (servers.length === 1) {
    serverIp = servers[0]!.host;
    ok(`เลือก server อัตโนมัติ: ${color.bold}${serverIp}${color.reset}`);
  } else {
    console.log(`\nพบ MySQL server ${servers.length} เครื่อง:`);
    servers.forEach((s, i) => {
      const v = s.versionHint ? ` ${color.gray}(${s.versionHint})${color.reset}` : "";
      console.log(`  ${color.cyan}${i + 1}${color.reset}) ${s.host}:${s.port}${v}`);
    });
    const choice = await ask(`เลือกหมายเลข server:`, "1");
    const idx = (parseInt(choice, 10) || 1) - 1;
    serverIp = servers[idx]?.host ?? servers[0]!.host;
  }

  if (serverIp) {
    info(
      `ค่าที่จะใช้กับ JHCIS Client: ${color.cyan}IP=${serverIp}${color.reset} ` +
        `${color.cyan}Port=${port}${color.reset} ${color.cyan}Password=${DEFAULT_PASSWORD}${color.reset}`,
    );
    info(
      `เมื่อ installer ถามค่า ODBC ให้ใส่ค่าด้านบน (user="root", database="jhcisdb")`,
    );
  }

  // ── Step 2: Run client installer ──────────────────────────────────
  step(2, TOTAL_STEPS, "ติดตั้ง JHCIS Client");
  // Client before Java, so the client uninstaller still has a JRE if it needs one.
  const old = [
    ...installed.filter((a) => a.kind === "client"),
    ...(isServerMachine ? [] : installed.filter((a) => a.kind === "java")),
  ];
  if (old.length > 0) {
    console.log(`\nพบโปรแกรมเดิมที่ติดตั้งอยู่:`);
    old.forEach((a) => console.log(`  - ${a.name} ${color.gray}${a.version}${color.reset}`));
    if (await confirm("ถอนการติดตั้งของเดิมทั้งหมดก่อนติดตั้งใหม่?", true)) {
      for (const a of old) await uninstallApp(a);
    } else {
      info("ไม่ถอนของเดิม - ติดตั้งทับ");
    }
  } else {
    ok("ไม่พบ JHCIS Client / Java ตัวเดิม");
  }

  if (await confirm("รันตัวติดตั้ง JHCIS Client เลยหรือไม่?", true)) {
    const r = await runClientInstaller();
    if (!r.ok) {
      warn(
        "ตัวติดตั้งจบโดยไม่สำเร็จ - ดำเนินการต่อ (อาจเป็นเพราะปิด installer ก่อนติดตั้งเสร็จ)",
      );
    }
  } else {
    warn("ข้ามขั้นตอนการติดตั้ง");
  }

  // ── Step 3: Permissions ───────────────────────────────────────────
  step(3, TOTAL_STEPS, "อัปเดท permission ของโฟลเดอร์ที่ติดตั้ง");
  const detected = detectInstallPath();
  const installPath = await ask(
    `Path ที่ติดตั้ง JHCIS:`,
    detected ?? DEFAULT_INSTALL_PATH,
  );
  await grantFullPermissions(installPath);

  // ── Step 4: Optional update ───────────────────────────────────────
  step(4, TOTAL_STEPS, "อัปเดท version ใหม่ (ถ้าต้องการ)");
  if (await confirm("ต้องการอัปเดท JHCIS เป็น version ใหม่?", true)) {
    await runUpdater();
  } else {
    info("ข้ามการอัปเดท");
  }

  // ── Step 5: getdown.txt fix ───────────────────────────────────────
  // After the updater, since it may write its own getdown.txt.
  step(5, TOTAL_STEPS, "วาง getdown.txt (แก้ปัญหาเปิด JHCIS ไม่ได้)");
  await fixGetdown(installPath);

  // ── Step 6: Disable Java auto-update ──────────────────────────────
  step(6, TOTAL_STEPS, "ปิด Java auto-update");
  await disableJavaUpdate();

  console.log(
    `\n${color.bold}${color.green}✔ การติดตั้งเสร็จสิ้น${color.reset}\n` +
      `${color.gray}คุณสามารถเปิดโปรแกรม JHCIS จาก shortcut บน Desktop ได้เลย${color.reset}`,
  );
  await pause();
  return 0;
}

main()
  .then((code) => process.exit(code))
  .catch((e) => {
    err(`เกิดข้อผิดพลาด: ${(e as Error).stack ?? e}`);
    pause().finally(() => process.exit(1));
  });
