# PowerPCU JHCIS Installer

โปรแกรมช่วยติดตั้ง **JHCIS Client** บนเครื่องลูกข่าย (Windows) เขียนด้วย PowerShell 5.1 + WinForms ไฟล์เดียว (`jhcis-installer.ps1`) และ build เป็น `jhcis-installer.exe` ด้วย ps2exe

## โปรแกรมนี้ทำอะไร

ทำ 7 ขั้นตอนต่อเนื่องในหน้าต่างเดียว:

1. ค้นหา MySQL server ในวงแลน (port 3333)
2. ถอน JHCIS Client / Java ตัวเดิม
3. ติดตั้ง JHCIS Client
4. ตั้ง permission โฟลเดอร์ (`icacls` ให้ Users/Administrators เป็น Full Control)
5. อัปเดต version ใหม่ (`JHCIS_Update.exe`)
6. วาง `getdown.txt` และปิด Java auto-update
7. สร้าง shortcut JHCIS บน Desktop: `JHCIS` เปิดทันที, `JHCIS (ตรวจอัปเดต)` เช็ค version ก่อน; ลบ shortcut เดิมที่ชี้เข้าโฟลเดอร์ jhcis-client บน Desktop

ใช้กับเครื่อง client เท่านั้น ถ้าตรวจพบ JHCIS-Server ในเครื่อง โปรแกรมจะเตือน

## วิธีใช้หน้างาน

1. โหลด `jhcis-installer.exe` จาก release `vX.Y.Z` ล่าสุด
2. คัดลอกใส่ flash drive แล้วนำไปที่เครื่องปลายทาง
3. ดับเบิลคลิก แล้วกด Yes ที่ UAC (ถ้า Windows SmartScreen เตือนครั้งแรก ให้กด "ข้อมูลเพิ่มเติม" → "เรียกใช้ต่อไป")
4. ครั้งแรกโปรแกรมจะดาวน์โหลดไฟล์ติดตั้ง ~450 MB เก็บไว้ข้าง exe และตรวจ SHA256 ครั้งต่อไปใช้ไฟล์เดิม
   - ไม่มีอินเทอร์เน็ตที่เครื่องปลายทาง: โหลด 2 ไฟล์จาก https://github.com/usman-coe/powerpcu_j_install/releases/tag/payload-2026-10 ไว้ก่อน แล้ววางไว้โฟลเดอร์เดียวกับ exe
5. ถ้า antivirus ไม่ให้รัน exe ให้ใช้ `run.cmd` + `jhcis-installer.ps1` แทน (วางไว้โฟลเดอร์เดียวกัน)

ค่า ODBC ที่โปรแกรมถาม: IP จากผลการสแกน, Port `3333`, user `root`, password `123456`, database `jhcisdb`

Log อยู่ที่ `jhcis-installer.log` ข้าง exe (ถ้าโฟลเดอร์ของ exe เขียนไม่ได้ เช่นรันจากแผ่น CD หรือแชร์แบบอ่านอย่างเดียว log และไฟล์ที่ดาวน์โหลดจะไปอยู่ที่ `%TEMP%` แทน)

## Build

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

ผลลัพธ์อยู่ใน `dist\` (`jhcis-installer.exe`, `jhcis-installer.ps1`, `run.cmd`) build.ps1 รัน self-test ก่อน และพยายามติดตั้ง ps2exe ให้อัตโนมัติถ้ายังไม่มี ถ้าติดตั้งไม่สำเร็จหรือมีข้อความถามค้าง ให้รัน `Install-Module ps2exe -Scope CurrentUser` เองครั้งเดียวก่อน

## ทดสอบ

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\jhcis-installer.ps1 -SelfTest   # รัน assert ในตัว แล้วออก (พิมพ์ "N failed") ต้องสั่งแบบนี้เพราะ policy ปกติของ Windows (Restricted) ไม่ให้รัน .ps1 ตรงๆ
.\jhcis-installer.ps1 -NoElevate   # เปิดหน้าต่างโดยไม่ขอ UAC (สำหรับเครื่อง dev)
```

## ออก release โปรแกรม

```powershell
gh release create vX.Y.Z dist\jhcis-installer.exe dist\jhcis-installer.ps1 dist\run.cmd --title "vX.Y.Z" --notes "..."
```

## อัปเดต payload เมื่อกรมฯ ออกไฟล์ใหม่

payload ปัจจุบัน: tag `payload-2026-10` มี `jhcis-install-client-jre8-0-191_64.exe` (426,366,287 bytes) และ `JHCIS_Update.exe` (41,472,028 bytes)

1. สร้าง tag ใหม่ `payload-YYYY-MM` (**ห้ามอัปโหลดทับ tag เดิม** เพราะโปรแกรมรุ่นเก่ายังต้องตรวจ hash ผ่าน):
   `gh release create payload-YYYY-MM <client exe> <JHCIS_Update.exe> --title ... --notes ...`
2. แก้ในสคริปต์: `$Script:PayloadTag`, และ `Name`/`Size`/`Sha256` ของ `$Script:Payload.Client` / `.Updater` (หา hash ด้วย `Get-FileHash -Algorithm SHA256`)
3. bump `$Script:Version`
4. build แล้วออก release โปรแกรมใหม่

## เอกสารออกแบบ

- [Spec](docs/superpowers/specs/2026-10-30-powershell-winforms-rewrite-design.md)
- [Plan](docs/superpowers/plans/2026-10-30-powershell-winforms-rewrite.md)

## Credit

พัฒนาโดย PowerPCU (usman kareemee) · github.com/usman-coe/powerpcu_j_install
