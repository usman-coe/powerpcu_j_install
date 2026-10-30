# เขียนใหม่: JHCIS Client Installer เป็น PowerShell + WinForms

วันที่: 2026-10-30
สถานะ: รอ approve

## 1. เจตนาและเหตุผล

ตัวติดตั้งปัจจุบัน (TypeScript, compile ด้วย Bun) ได้ไฟล์ `dist/jhcis-installer.exe` ขนาด **588 MB** เพราะ

| ส่วนประกอบ | ขนาด |
|---|---|
| `jhcis-install-client-jre8-0-191_64.exe` (ฝังไว้ใน exe) | 407 MB |
| `JHCIS_Update.exe` (ฝังไว้ใน exe) | 41 MB |
| Bun runtime + sourcemap | ~140 MB |
| code ของโปรเจกต์เอง | < 1 MB |

นอกจากนี้ยังเป็น console app ซึ่งแสดงสระ/วรรณยุกต์ไทยเพี้ยนใน conhost จนต้องมี logic relaunch ไปเปิดใน Windows Terminal

เป้าหมายของการเขียนใหม่: **เล็กลง (ไม่ถึง 1 MB), ง่ายขึ้น (ไฟล์เดียว ไม่มี runtime), และมีหน้าต่าง UI** โดยพฤติกรรมการติดตั้งทั้ง 6 ขั้นตอนคงเดิม

## 2. Goals / Non-goals / Anti-goals

**Goals**
- exe ขนาดไม่ถึง 1 MB รันได้บน Windows 10/11 โดยไม่ต้องติดตั้งอะไรเพิ่ม
- หน้าต่าง WinForms ภาษาไทย แบบหน้าเดียว (layout "B" ดูหัวข้อ 5)
- ไฟล์ติดตั้งของกรมฯ อยู่บน GitHub Releases ดาวน์โหลดหน้างาน ครั้งเดียวต่อ flash drive
- 6 ขั้นตอนเดิมทำงานเหมือนเดิมทุกประการ (หัวข้อ 6)

**Non-goals**
- ไม่ติดตั้งเครื่องแม่ (JHCIS Server / MySQL) เหมือนเดิม
- ไม่ทำให้ NSIS installer ของกรมฯ เป็น silent install ยังรันแบบ wizard ให้ผู้ใช้กรอก ODBC เองเหมือนเดิม
- ไม่แกะ/แพ็ก installer ของกรมฯ ใหม่
- ไม่รองรับภาษาอื่นนอกจากไทย
- ไม่มีไอคอนโปรแกรม

**Anti-goals (ถ้าเกิดถือว่าล้มเหลวแม้โปรแกรมจะ "ทำงาน")**
- ถอน Java บนเครื่องที่มี JHCIS-Server ติดตั้งอยู่
- รันตัวติดตั้งจากไฟล์ที่ดาวน์โหลดมาไม่ครบ/เสียหาย
- หน้าต่างค้าง (Not Responding) ระหว่างสแกน/ดาวน์โหลด/รอ installer

## 3. ข้อจำกัด

- Windows 10/11 64-bit, Windows PowerShell 5.1, .NET Framework 4.x (มีมากับเครื่องทุกเครื่อง) ห้ามพึ่ง PowerShell 7 หรือ .NET Core
- ต้องรันด้วยสิทธิ์ Administrator (icacls, msiexec, reg add HKLM, NSIS installer)
- เครื่องหน้างานอาจมีอินเทอร์เน็ตช้า หรือไม่มีเลยถ้าโหลดไฟล์ไว้แล้ว โปรแกรมต้องทำงานได้ทั้งสองกรณี
- ห้ามใช้ module/dependency ภายนอกตอน runtime (ps2exe ใช้เฉพาะตอน build)
- antivirus ที่ รพ.สต. อาจไม่ไว้ใจ exe จาก ps2exe จึงต้องแจก `.ps1` + `.cmd` ควบไปด้วยเสมอ

## 4. สิ่งที่ตัดสินใจแล้ว ("how it gets made")

| เรื่อง | ตัดสินใจ | โดย |
|---|---|---|
| ภาษา/UI | PowerShell 5.1 + System.Windows.Forms ไฟล์เดียว `jhcis-installer.ps1` | ผู้ใช้ |
| แพ็ก exe | ps2exe → `dist/jhcis-installer.exe` (`-noConsole -requireAdmin -x64`) | Claude |
| fallback | แจก `jhcis-installer.ps1` + `run.cmd` (`powershell -NoProfile -ExecutionPolicy Bypass -File`) คู่กัน ตัว ps1 self-elevate เองถ้าไม่ใช่ admin | Claude |
| ที่ฝากไฟล์กรมฯ | GitHub Releases ของ repo นี้ เปลี่ยน repo เป็น **public** | ผู้ใช้ |
| ที่เก็บไฟล์ที่โหลด | โฟลเดอร์เดียวกับ exe (ถ้าเขียนไม่ได้ → `%TEMP%`) | Claude |
| ตรวจไฟล์ | SHA256 ต้องตรงกับค่าในสคริปต์ ไม่ตรง = ลบแล้วโหลดใหม่ | Claude |
| หน้าต่าง | layout "B" หน้าเดียว (หัวข้อ 5) | ผู้ใช้ |
| log | แสดงในหน้าต่าง และ append ลง `jhcis-installer.log` ข้าง exe | Claude |
| code เดิม | ลบ TypeScript/Bun ทิ้งทั้งหมด ไม่เก็บคู่กัน | Claude |
| getdown.txt สำรอง | ฝังเป็น here-string ในสคริปต์ (6.9 KB) | Claude |

### 4.1 Payload บน GitHub Releases

Release tag **`payload-2026-10`** (tag มีเดือน/ปีของชุดไฟล์ ไม่ผูกกับ version ของโปรแกรม) มี asset 2 ไฟล์

| ไฟล์ | ขนาด (bytes) | SHA256 |
|---|---|---|
| `jhcis-install-client-jre8-0-191_64.exe` | 426,366,287 | `ded0373a4a185f02714808ad96f8a423223809706cf45a1952ff962de74b9e19` |
| `JHCIS_Update.exe` | 41,472,028 | `644a9581ff6d61db2e2f7d1b8aaa05d2863579f9b51d8a06f691f038a06e2313` |

URL: `https://github.com/usman-coe/powerpcu_j_install/releases/download/<tag>/<ไฟล์>`

ค่า tag, ชื่อไฟล์, SHA256 hardcode ไว้ในบล็อก config ด้านบนสุดของสคริปต์ เมื่อกรมฯ ออก installer ใหม่: **สร้าง release tag ใหม่** (เช่น `payload-2027-03`) อัปโหลดไฟล์ชุดใหม่ แก้ tag/ชื่อไฟล์/SHA256 ในสคริปต์ แล้วออก release โปรแกรมใหม่ ไม่อัปโหลดทับ tag เดิม เพื่อให้สำเนาโปรแกรมเวอร์ชันเก่าที่กระจายไปแล้วยังโหลดไฟล์ที่ hash ตรงได้

Release ของโปรแกรมใช้ tag `vX.Y.Z` มี asset `jhcis-installer.exe`, `jhcis-installer.ps1`, `run.cmd`

การเปลี่ยน repo เป็น public และสร้าง release `payload-2026-10` เป็นขั้นตอนหนึ่งใน plan ทำผ่าน `gh` โดยขอให้ผู้ใช้ยืนยันอีกครั้งตอนจะรันจริง (ย้อนกลับยาก) ตรวจแล้วว่าใน git history ไม่มีความลับ

### 4.2 ลำดับหาไฟล์ติดตั้ง

1. โฟลเดอร์เดียวกับ exe/ps1
2. `JHCIS-install-jre_jdk_64\jHCIS-All-PCU\` ใต้โฟลเดอร์นั้น (รองรับโครงสร้างเดิมของแผ่นกรมฯ)
3. ดาวน์โหลดจาก URL ใน config → `<ชื่อไฟล์>.part` → ตรวจ SHA256 → rename

**กฎเมื่อ SHA256 ไม่ตรง**
- ไฟล์ที่เจอในข้อ 1-2 (ผู้ใช้วางเอง): log ! แล้วถามผู้ใช้ (MessageBox) ว่าจะใช้ต่อหรือโหลดใหม่
- ไฟล์ที่เพิ่งดาวน์โหลด: ลบ `.part` แล้วโหลดใหม่ **อีก 1 ครั้ง** เท่านั้น ถ้ายังไม่ตรง → ลบ, log ✗ "ไฟล์ที่โหลดมาไม่ตรงกับที่โปรแกรมรู้จัก โปรแกรมเวอร์ชันนี้อาจเก่า กรุณาโหลดโปรแกรมเวอร์ชันใหม่" แล้วหยุดเฉพาะขั้นตอนนั้น ไม่มีตัวเลือก "ใช้ต่อ" สำหรับไฟล์ที่โหลดมา (anti-goal)

**ไม่ทำ resume** ดาวน์โหลดล้มเหลวกลางทาง = ลบ `.part` แล้วเริ่มใหม่ในครั้งถัดไป (`# ponytail: no resume; add HttpWebRequest Range resume if site downloads keep failing`) เหตุผล: โหลดครั้งเดียวต่อ flash drive และ WebClient ทำได้ในบรรทัดเดียว

## 5. หน้าต่าง (layout "B")

หน้าต่างเดียว ขนาดคงที่ประมาณ 560×680 px ไม่ย่อขยาย เปิดกลางจอ ชื่อหน้าต่าง `ติดตั้ง JHCIS Client v<version>` ฟอนต์ Segoe UI 10pt หรือ Tahoma

```
┌ ติดตั้ง JHCIS Client v2.0.0 ───────────────────────────── ─ □ ✕ ┐
│ ┌ เครื่องแม่ (MySQL Server) ──────────────────────────────────┐ │
│ │ IP   [192.168.1.10 (5.6.45-log)        ▾]  [ สแกนใหม่ ]      │ │
│ │ Port [3333 ]   ค่าที่ต้องกรอกตอน installer ถาม ODBC:          │ │
│ │                user=root  password=123456  database=jhcisdb │ │
│ └─────────────────────────────────────────────────────────────┘ │
│ ┌ ขั้นตอน ────────────────────────────────────────────────────┐ │
│ │ [✓] ถอน JHCIS Client / Java ตัวเดิม  (พบ 2 รายการ)           │ │
│ │ [✓] ติดตั้ง JHCIS Client                                     │ │
│ │ [✓] ตั้ง permission โฟลเดอร์  [C:\Program Files\jhcis-client] │ │
│ │ [✓] อัปเดต JHCIS เป็น version ใหม่ (JHCIS_Update.exe)        │ │
│ │ [✓] วาง getdown.txt (แก้ปัญหาเปิด JHCIS ไม่ได้)              │ │
│ │ [✓] ปิด Java auto-update (JHCIS ต้องใช้ JRE 1.8)             │ │
│ └─────────────────────────────────────────────────────────────┘ │
│ [            ▶  เริ่มติดตั้ง            ]        [ ปิด ]        │
│ [████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] │
│ ┌ log (อ่านอย่างเดียว, เลื่อนได้) ─────────────────────────────┐ │
│ │ 10:21:03 ✓ พบ MySQL ที่ 192.168.1.10:3333 (5.6.45-log)       │ │
│ │ 10:21:40 ✓ ถอน Java 8 Update 311 (64-bit) แล้ว               │ │
│ │ 10:21:41 → กำลังดาวน์โหลด jhcis-install-client... 142/407 MB │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**พฤติกรรม**
- เปิดโปรแกรม → เริ่มสแกน LAN อัตโนมัติทันที (ไม่บล็อก UI) ผลขึ้นใน ComboBox เป็น `ip (version)` ถ้าเจอ 1 เครื่องเลือกให้เลย เจอหลายเครื่องเลือกเครื่องแรก ผู้ใช้เปลี่ยนได้ ComboBox เป็นแบบพิมพ์เองได้ (DropDown) สำหรับกรณีไม่เจอ
- เปลี่ยน Port แล้วกด "สแกนใหม่" → สแกน port นั้น
- checkbox "ถอนของเดิม": แสดงจำนวนที่พบ ถ้าไม่พบ → uncheck + disable + ข้อความ "(ไม่พบของเดิม)"
- ช่อง path ติดตั้ง: เติมจากการตรวจหาโฟลเดอร์ (รายการใน 6.3) ไม่เจอใช้ `C:\Program Files\jhcis-client`
- ปุ่ม "เริ่มติดตั้ง" กดได้ตลอด (ไม่ต้องรอสแกนเสร็จ) ถ้า IP ว่าง → log เตือนว่าต้องกรอก ODBC เอง แล้วทำต่อ
- ระหว่างทำงาน: disable ทุก input/checkbox/ปุ่มเริ่ม ปุ่ม "ปิด" และ X กดได้แต่ถามยืนยัน ถ้ายืนยัน: **ไม่ kill โปรแกรมลูกที่กำลังรัน** (msiexec, uninst.exe, NSIS installer, JHCIS_Update.exe ปล่อยให้ทำจนจบเองเพื่อไม่ให้ระบบอยู่ในสภาพถอน/ติดตั้งครึ่งๆ กลางๆ) ลบ `.part` ที่ค้าง log บอกว่าปิดกลางคัน แล้วปิดหน้าต่าง
- ทำครบ → MessageBox "การติดตั้งเสร็จสิ้น เปิด JHCIS จาก shortcut บน Desktop ได้เลย" แล้ว enable ทุกอย่างกลับ
- progress bar: ระหว่างสแกน = จำนวน ip ที่สแกนแล้ว/254, ระหว่างดาวน์โหลด = bytes, ขั้นตอนอื่น = marquee
- log แต่ละบรรทัดมีเวลา สัญลักษณ์ ✓ (เขียว) ✗ (แดง) ! (เหลือง) → (ปกติ) และเขียนลงไฟล์ `jhcis-installer.log` ข้าง exe ด้วย (append, มีบรรทัดคั่น run ใหม่พร้อมวันที่และ version)
- ถ้าตรวจพบ JHCIS-Server ติดตั้งอยู่ (6.2) → MessageBox เตือนทันทีตอนเปิดโปรแกรม ให้เลือก "ดำเนินการต่อ/ยกเลิก" ถ้ายกเลิกปิดโปรแกรม ถ้าต่อ Java จะไม่อยู่ในรายการถอน

## 6. ขั้นตอนการติดตั้ง (คงจากเดิมทุกข้อ)

ทำตามลำดับ ข้ามข้อที่ไม่ได้ติ๊ก ข้อที่ล้มเหลวให้ log ✗ แล้ว **ทำข้อถัดไปต่อ** (ไม่หยุดทั้งกระบวนการ) ยกเว้นข้อ 6.4 ที่ถ้าหาไฟล์ติดตั้งไม่ได้ให้หยุดเฉพาะข้อนั้น

### 6.1 สแกนหา MySQL ในวงแลน
- ทุก interface IPv4 ที่ไม่ใช่ loopback → สแกน `/24` ของแต่ละอัน (x.y.z.1-254 ยกเว้น ip ตัวเอง)
- ต่อ TCP แบบขนาน connect timeout 800 ms รอ handshake 1500 ms
- ถือว่าเป็น MySQL เมื่อ byte[4] ของ packet แรก = `0x0A` (protocol v10) version = string จาก byte 5 ถึง NUL
- ไม่ต้อง login ไม่ต้องรู้รหัสผ่าน

### 6.2 ตรวจโปรแกรมที่ติดตั้งอยู่
- อ่าน `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*` และ `...\WOW6432Node\...\Uninstall\*` เอาเฉพาะที่มี DisplayName และ UninstallString
- จำแนกด้วย regex (case-insensitive) บน DisplayName
  - `^JHCIS-Client` → client
  - `^JHCIS-Server` → server
  - `^Java(\(TM\))? (\d|SE)` → java (ตัดสินใจไว้แล้วว่า "Java Auto Updater" ต้องไม่ match)
- รายการถอน = client ทั้งหมด + java ทั้งหมด (java เฉพาะเมื่อไม่ใช่เครื่องแม่) **ถอน client ก่อน java** เพราะ uninstaller ของ client อาจต้องใช้ JRE

### 6.3 ถอนแบบเงียบ
- MSI (Java ของ Oracle): UninstallString มี `MsiExec` + `{GUID}` → `msiexec /x {GUID} /qb /norestart`
- NSIS (JHCIS): UninstallString เป็น `...\uninst.exe` → `"<path>\uninst.exe" /S _?=<โฟลเดอร์ของ uninst.exe>` (`_?=` ต้องอยู่ท้ายสุดและไม่มี quote แม้ path มีช่องว่าง เพื่อให้รอจนเสร็จแทนที่จะ copy ตัวเองไป %TEMP% แล้วรันต่อ)
- exit code ที่ถือว่าสำเร็จ: 0, 1605 (ไม่ได้ติดตั้งอยู่แล้ว), 3010 (สำเร็จ ควร restart ภายหลัง → log บอก)
- รูปแบบอื่นที่ไม่รู้จัก → log ✗ "กรุณาถอนเองใน Control Panel" แล้วทำต่อ

### 6.4 ติดตั้ง JHCIS Client
- หาไฟล์ตามลำดับ 4.2 ดาวน์โหลดถ้าจำเป็น (TLS 1.2, แสดง progress, ยกเลิกไม่ได้กลางคัน)
- ก่อนรัน แสดง MessageBox สรุปค่า ODBC ที่ต้องกรอก (IP, Port, user=root, password=123456, database=jhcisdb) เพราะหน้าต่าง NSIS จะบังหน้าต่างเรา
- รัน installer แบบปกติ (มี GUI) รอจนจบ exit code ≠ 0 → log ! "อาจปิด installer ก่อนเสร็จ" แล้วทำต่อ
- หลังจบ ตรวจหาโฟลเดอร์ติดตั้งใหม่อีกครั้ง ถ้าช่อง path ยังเป็นค่า default และเจอโฟลเดอร์จริง → อัปเดตช่อง path

โฟลเดอร์ที่ใช้ตรวจหา (เรียงตามลำดับ): `C:\Program Files\jhcis-client`, `C:\Program Files (x86)\jhcis-client`, `C:\JHCIS`, `C:\jhcis`, `C:\JHCIS-Client`, `C:\Program Files\JHCIS`, `C:\Program Files (x86)\JHCIS`

### 6.5 ตั้ง permission
- `icacls "<path>" /T /C /Q /grant *S-1-5-32-545:(OI)(CI)F /grant *S-1-5-32-544:(OI)(CI)F /grant <USERNAME>:(OI)(CI)F`
- ใช้ SID แทนชื่อ (Users / Administrators) เพื่อไม่ขึ้นกับภาษา Windows
- ถ้าโฟลเดอร์ไม่มี → log ✗ ข้าม

### 6.6 อัปเดต version ใหม่
- หา/ดาวน์โหลด `JHCIS_Update.exe` ตาม 4.2 → รัน รอจนจบ

### 6.7 วาง getdown.txt (ต้องทำ **หลัง** 6.6 เพราะ updater อาจเขียน getdown.txt ของมันเอง)
- ลองดาวน์โหลด `https://jhcis.moph.go.th/files/getdown.txt` (timeout 10 s) ใช้ได้ต่อเมื่อเนื้อหามีคำว่า `appbase` ไม่งั้นใช้ตัวที่ฝังในสคริปต์
- ถ้ามี `<path>\getdown.txt` อยู่แล้ว → copy เป็น `getdown.txt.bak` ก่อน แล้วเขียนทับ

### 6.8 ปิด Java auto-update
- สำหรับ root ทั้ง `HKLM\SOFTWARE` และ `HKLM\SOFTWARE\WOW6432Node`:
  - `<root>\JavaSoft\Java Update\Policy` ตั้ง DWORD = 0: `EnableJavaUpdate`, `EnableAutoUpdateCheck`, `NotifyDownload`, `NotifyInstall`
  - ลบค่า `SunJavaUpdateSched` ใน `<root>\Microsoft\Windows\CurrentVersion\Run` (ไม่มีก็ไม่เป็นไร)

## 7. โครงไฟล์ใน repo หลังเปลี่ยน

```
jhcis-installer.ps1      # ทั้งโปรแกรม: config, ฟังก์ชัน, UI, -SelfTest
run.cmd                  # powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0jhcis-installer.ps1"
build.ps1                # รัน -SelfTest → ps2exe → dist/ (ติดตั้ง module ps2exe ให้ถ้ายังไม่มี)
README.md                # วิธี build, วิธีอัปโหลด payload/release, วิธีใช้หน้างาน
.gitignore               # ปรับ: ตัดของ bun/node, คง dist/, payload ของกรมฯ, .superpowers/
docs/superpowers/specs/  # เอกสารนี้
```

**ลบทิ้ง**: `index.ts`, `src/`, `scripts/build.ts`, `package.json`, `bun.lock`, `tsconfig.json`, `app.manifest`, `node_modules/`

**คงไว้ (ไม่อยู่ใน git)**: `JHCIS-install-jre_jdk_64/`, `JHCIS_Update.exe` เป็นต้นฉบับสำหรับอัปโหลดขึ้น release `payload-2026-10`

logic เดิมทั้งหมดอยู่ใน git history ถึง commit `26773d1` (เวอร์ชัน TypeScript สุดท้าย รวม uninstall แล้ว) จึงลบไฟล์ได้โดยไม่เสียอะไร

## 8. การทดสอบ

- `jhcis-installer.ps1 -SelfTest` รัน assert กับฟังก์ชันที่ไม่แตะระบบ แล้ว exit 0/1: จำแนกชื่อโปรแกรม (6.2), สร้างคำสั่งถอน (6.3), แยก version จาก MySQL handshake bytes (6.1), เลือก getdown.txt จากเนื้อหา (6.7), ตรวจ SHA256 กับไฟล์ชั่วคราว
- `build.ps1` ต้องรัน `-SelfTest` ก่อนและหยุดถ้าไม่ผ่าน
- การทดสอบจริงบนเครื่องลูกเป็นหน้าที่ผู้ใช้ (ไม่มี CI สำหรับ UI)

## 9. ปล่อยให้ผู้สร้างตัดสินใจ

- วิธีทำให้ UI ไม่ค้าง แนะนำ single-thread + loop รอที่เรียก `[Windows.Forms.Application]::DoEvents()` ร่วมกับ API แบบ async ของ .NET (`TcpClient.ConnectAsync`, `WebClient.DownloadFileAsync`, `Process.HasExited`) ถ้าไม่พอจึงใช้ background runspace
- ขนาด/ตำแหน่ง control ที่แน่นอน สี ฟอนต์
- รูปแบบข้อความ log ที่แน่นอน
- โครงสร้างฟังก์ชันภายในสคริปต์
- วิธีจัดการกรณี `%TEMP%` ก็เขียนไม่ได้ (log ✗ แล้วให้ผู้ใช้วางไฟล์เอง เป็นแนวทางที่พอใช้ได้)
