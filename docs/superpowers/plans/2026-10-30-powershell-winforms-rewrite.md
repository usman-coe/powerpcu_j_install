# JHCIS Client Installer (PowerShell + WinForms) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** แทนที่ตัวติดตั้ง TypeScript/Bun ขนาด 588 MB ด้วยสคริปต์ PowerShell ไฟล์เดียวที่มีหน้าต่าง WinForms แพ็กเป็น exe ไม่ถึง 1 MB และดาวน์โหลดไฟล์ติดตั้งของกรมฯ จาก GitHub Releases หน้างาน

**Architecture:** ทุกอย่างอยู่ใน `jhcis-installer.ps1` เรียงเป็น region ตามลำดับตายตัว: config → pure helpers → system actions → `-SelfTest` → elevation → UI ฟังก์ชันที่ไม่แตะระบบทดสอบด้วย `-SelfTest` (assert ในไฟล์เดียวกัน) UI เป็น single-thread ใช้ `Wait-UiUntil` (loop `DoEvents`) รองานยาวทุกชนิด (child process, download task, TCP connect tasks) จึงไม่มี runspace/thread

**Tech Stack:** Windows PowerShell 5.1, .NET Framework 4.x (System.Windows.Forms, System.Net.WebClient, System.Net.Sockets.TcpClient), ps2exe (build เท่านั้น), GitHub CLI `gh` (release)

**Spec:** `docs/superpowers/specs/2026-10-30-powershell-winforms-rewrite-design.md`

## Global Constraints

- รันได้บน Windows PowerShell 5.1 + .NET Framework 4.x เท่านั้น ห้ามใช้ syntax/cmdlet ของ PowerShell 7 (ไม่มี `??`, ternary, `-Parallel`, `ConvertFrom-Json -AsHashtable`)
- ไม่มี module/dependency ตอน runtime; ps2exe ใช้เฉพาะใน `build.ps1`
- `jhcis-installer.ps1` ต้องบันทึกเป็น **UTF-8 with BOM** (ไม่งั้น PowerShell 5.1 อ่านสตริงไทยเพี้ยน) `build.ps1` ต้องตรวจและ fail ถ้าไม่มี BOM
- ห้าม `Write-Host`/`Write-Output`/`Write-Warning` นอกบล็อก `-SelfTest` (ps2exe `-noConsole` จะแปลงเป็น MessageBox) ทุก log ผ่าน `Write-Log`
- เขียนไฟล์ข้อความทุกไฟล์ด้วย UTF-8 (`-Encoding UTF8` หรือ `[IO.File]::WriteAllText(..., UTF8)`)
- ค่าคงที่จาก spec ใช้ตามนี้ตรงตัว: tag `payload-2026-10`; URL base `https://github.com/usman-coe/powerpcu_j_install/releases/download/payload-2026-10`; `jhcis-install-client-jre8-0-191_64.exe` ขนาด 426366287 SHA256 `ded0373a4a185f02714808ad96f8a423223809706cf45a1952ff962de74b9e19`; `JHCIS_Update.exe` ขนาด 41472028 SHA256 `644a9581ff6d61db2e2f7d1b8aaa05d2863579f9b51d8a06f691f038a06e2313`; port 3333; password `123456`; path default `C:\Program Files\jhcis-client`; getdown URL `https://jhcis.moph.go.th/files/getdown.txt`
- ชื่อหน้าต่าง `ติดตั้ง JHCIS Client v<version>` version เริ่มที่ `2.0.0`
- ทำงานบน branch `rewrite-powershell` (สร้างจาก `main` ที่ `26773d1`) ไฟล์ payload ของกรมฯ อยู่ที่ main checkout `C:\Users\usman\repo\powerpcu_j_install\` (ไม่อยู่ใน git) ใช้เฉพาะ Task 9
- ทุก commit ลงท้ายด้วย `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`

## Review Focus

1. **ช่อง Port พิมพ์ค่าเพี้ยน** (`''`, `abc`, `70000`) → ใช้ 3333 ไม่ error (ทดสอบใน Task 2: `ConvertTo-Port`)
2. **ComboBox server มี version ต่อท้าย** `192.168.1.10 (5.6.45-log)` → ค่าที่โชว์ให้กรอก ODBC ต้องเป็น IP ล้วน (Task 2: `Get-IpFromServerText`)
3. **รันจากสื่ออ่านอย่างเดียว / โฟลเดอร์ที่เขียนไม่ได้** → ดาวน์โหลดและ log ไปที่ `%TEMP%` แทน ไม่ crash (Task 3: `Get-WritableDir`)
4. **เว็บกรมฯ ตอบ 200 แต่เป็นหน้า HTML error** → ต้องใช้ getdown.txt ที่ฝังมา ไม่เขียน HTML ทับไฟล์จริง (Task 2: `Test-GetdownContent`, Task 6: `Get-GetdownText`)
5. **UninstallString มี quote / มี argument ต่อท้าย / GUID ตัวเล็ก** → สร้างคำสั่งถูก หรือคืน `$null` ให้ผู้ใช้ถอนเองแทนที่จะรันคำสั่งผิด (Task 2: `Get-SilentUninstallCommand`)

---

### Task 1: โครงสคริปต์, config, Write-Log, SelfTest harness, run.cmd

**Files:**
- Create: `jhcis-installer.ps1`
- Create: `run.cmd`

**Interfaces:**
- Produces: ตัวแปร `$Script:Version`, `$Script:PayloadTag`, `$Script:PayloadBase` (= `https://github.com/usman-coe/powerpcu_j_install/releases/download/$PayloadTag`), `$Script:Payload` (hashtable `Client`/`Updater` แต่ละอันมี `Name`,`Size`,`Sha256`), `$Script:DefaultPort`, `$Script:DefaultPassword`, `$Script:DefaultInstallPath`, `$Script:InstallPathCandidates`, `$Script:GetdownUrl`, `$Script:GetdownFallback`, `$Script:BaseDir`, `$Script:LogBox = $null` (Strict Mode ต้องประกาศก่อน Task 7 จะใส่ RichTextBox)
- Produces: `Write-Log([ValidateSet('ok','err','warn','info')][string]$Level, [string]$Message)` ใน Task นี้เขียนแค่ console (เมื่อ `$SelfTest`) และไฟล์; Task 7 เพิ่ม RichTextBox
- Produces: `Assert-Equal($Actual, $Expected, [string]$Name)`, `Assert-True($Condition, [string]$Name)`, `Invoke-SelfTest` (รัน assert ทั้งหมด พิมพ์ `N failed` แล้ว `exit` 0/1)

- [ ] **Step 1: สร้างไฟล์ตามลำดับ region**

```powershell
#requires -Version 5.1
param([switch]$SelfTest)
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#region Config      (ค่าตาม Global Constraints; $GetdownFallback = here-string เนื้อหา src/getdown.txt ทั้งไฟล์)
#region Base paths  ($Script:BaseDir = $PSScriptRoot ถ้ามี ไม่งั้น Split-Path ([Environment]::GetCommandLineArgs()[0]))
#region Log         (Write-Log)
#region Pure        (Task 2)
#region System      (Task 3-6)
#region SelfTest    (Assert-*, Invoke-SelfTest; ปิดด้วย  if ($SelfTest) { Invoke-SelfTest })
#region Elevation   (Task 7)
#region UI          (Task 7)
```

`Write-Log`: บรรทัด = `"{0:HH:mm:ss} {1} {2}" -f (Get-Date), สัญลักษณ์ (ok=`✓` err=`✗` warn=`!` info=`→`), $Message`; ถ้า `$SelfTest` → `Write-Host`; เสมอ → `Add-Content -Encoding UTF8 $Script:LogFile` ภายใน try/catch (log พังต้องไม่ล้มโปรแกรม) `$Script:LogFile` กำหนดใน Task 3 ตอนมี `Get-WritableDir`; ใน Task นี้ตั้งเป็น `Join-Path $Script:BaseDir 'jhcis-installer.log'`

`Invoke-SelfTest`: เริ่มด้วย `Assert-Equal (Write-Log info 'selftest' ; 1) 1 'Write-Log does not throw'` และ `Assert-True ($Script:Payload.Client.Sha256.Length -eq 64) 'config sha length'`

- [ ] **Step 2: สร้าง `run.cmd` (ASCII)**

```bat
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0jhcis-installer.ps1" %*
```

- [ ] **Step 3: บังคับ BOM**

Run: `powershell -NoProfile -Command "$p='jhcis-installer.ps1'; $t=[IO.File]::ReadAllText($p); [IO.File]::WriteAllText($p,$t,(New-Object Text.UTF8Encoding $true)); (Get-Content $p -Encoding Byte -TotalCount 3) -join ','"`
Expected: `239,187,191`

- [ ] **Step 4: รัน SelfTest**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\jhcis-installer.ps1 -SelfTest; echo "exit=$LASTEXITCODE"`
Expected: บรรทัด `ok   Write-Log does not throw`, `ok   config sha length`, `0 failed`, `exit=0` และมีไฟล์ `jhcis-installer.log` เกิดขึ้น

- [ ] **Step 5: Commit**

```bash
git checkout -b rewrite-powershell
git add jhcis-installer.ps1 run.cmd
git commit -m "feat: PowerShell installer skeleton with config, logging and self-test harness"
```

---

### Task 2: Pure helpers

**Files:**
- Modify: `jhcis-installer.ps1` region Pure + asserts ใน `Invoke-SelfTest`

**Interfaces:**
- Produces:
  - `Get-AppKind([string]$DisplayName)` → `'client'|'server'|'java'|$null`
  - `Get-SilentUninstallCommand([string]$UninstallString)` → `[pscustomobject]@{FilePath; Arguments}` หรือ `$null`
  - `Get-MysqlVersionFromHandshake([byte[]]$Bytes)` → version string หรือ `$null`
  - `Test-GetdownContent([string]$Text)` → bool
  - `Test-FileSha256([string]$Path, [string]$Expected)` → bool (ใช้ `Get-FileHash -Algorithm SHA256`, เทียบแบบไม่สนตัวพิมพ์)
  - `ConvertTo-Port([string]$Text)` → int (1..65535 ไม่งั้น `$Script:DefaultPort`)
  - `Get-IpFromServerText([string]$Text)` → string (token แรกก่อนช่องว่าง, trim)
  - `Get-LanHosts([string]$Base, [string]$LocalIp)` → string[] 253 ตัว (`$Base1..254` ตัด `$LocalIp`)

- [ ] **Step 1: เพิ่ม assert ใน `Invoke-SelfTest`**

```powershell
Assert-Equal (Get-AppKind 'Java 8 Update 191 (64-bit)') 'java' 'kind java'
Assert-Equal (Get-AppKind 'Java SE Development Kit 8 Update 191 (64-bit)') 'java' 'kind jdk'
Assert-Equal (Get-AppKind 'Java(TM) 8 Update 191') 'java' 'kind java(tm)'
Assert-Equal (Get-AppKind 'Java Auto Updater') $null 'kind auto updater excluded'
Assert-Equal (Get-AppKind 'JHCIS-Client-JRE-8.0.191_64bit 3.0.0') 'client' 'kind client'
Assert-Equal (Get-AppKind 'JHCIS-Server-JRE-8.0.191_64bit 3.0.0') 'server' 'kind server'
Assert-Equal (Get-AppKind 'MySQL Server 5.6') $null 'kind other'

$u = Get-SilentUninstallCommand 'MsiExec.exe /X{26A24AE4-039D-4CA4-87B4-2F64180191F0}'
Assert-Equal $u.FilePath 'msiexec.exe' 'msi filepath'
Assert-Equal $u.Arguments '/x {26A24AE4-039D-4CA4-87B4-2F64180191F0} /qb /norestart' 'msi args'
$u = Get-SilentUninstallCommand 'msiexec /i{26a24ae4-039d-4ca4-87b4-2f64180191f0}'
Assert-Equal $u.Arguments '/x {26a24ae4-039d-4ca4-87b4-2f64180191f0} /qb /norestart' 'msi lowercase guid'
$u = Get-SilentUninstallCommand '"C:\Program Files\jhcis-client\uninst.exe"'
Assert-Equal $u.FilePath 'C:\Program Files\jhcis-client\uninst.exe' 'nsis filepath unquoted'
Assert-Equal $u.Arguments '/S _?=C:\Program Files\jhcis-client' 'nsis args'
Assert-Equal (Get-SilentUninstallCommand 'C:\x\uninst.exe /S') $null 'nsis with trailing args -> null'
Assert-Equal (Get-SilentUninstallCommand 'rundll32 something') $null 'unknown -> null'

$hs = [byte[]](0x4A,0,0,0,0x0A) + [Text.Encoding]::ASCII.GetBytes('5.6.45-log') + [byte[]](0,1,2,3)
Assert-Equal (Get-MysqlVersionFromHandshake $hs) '5.6.45-log' 'handshake version'
Assert-Equal (Get-MysqlVersionFromHandshake ([Text.Encoding]::ASCII.GetBytes('HTTP/1.1 400'))) $null 'handshake non-mysql'
Assert-Equal (Get-MysqlVersionFromHandshake ([byte[]](1,2,3))) $null 'handshake too short'

Assert-True (Test-GetdownContent "# x`nappbase = https://7-sada.github.io/jhcis-update/`n") 'getdown ok'
Assert-True (-not (Test-GetdownContent '<html><body>404 Not Found</body></html>')) 'getdown html rejected'
Assert-True (-not (Test-GetdownContent '')) 'getdown empty rejected'

$tmp = Join-Path $env:TEMP ("sha-{0}.txt" -f [guid]::NewGuid()); [IO.File]::WriteAllText($tmp, 'abc')
Assert-True (Test-FileSha256 $tmp 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD') 'sha match (upper)'
Assert-True (Test-FileSha256 $tmp 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad') 'sha match (lower)'
Assert-True (-not (Test-FileSha256 $tmp ('0'*64))) 'sha mismatch'
Assert-True (-not (Test-FileSha256 "$tmp.missing" ('0'*64))) 'sha missing file -> false'
Remove-Item $tmp

Assert-Equal (ConvertTo-Port '3306') 3306 'port ok'
Assert-Equal (ConvertTo-Port '') 3333 'port empty'
Assert-Equal (ConvertTo-Port 'abc') 3333 'port text'
Assert-Equal (ConvertTo-Port '70000') 3333 'port out of range'
Assert-Equal (ConvertTo-Port '0') 3333 'port zero'

Assert-Equal (Get-IpFromServerText '192.168.1.10 (5.6.45-log)') '192.168.1.10' 'ip from combo text'
Assert-Equal (Get-IpFromServerText '  10.0.0.5  ') '10.0.0.5' 'ip trimmed'
Assert-Equal (Get-IpFromServerText '') '' 'ip empty'

$hosts = Get-LanHosts '192.168.1.' '192.168.1.37'
Assert-Equal $hosts.Count 253 'lan hosts count'
Assert-Equal $hosts[0] '192.168.1.1' 'lan first'
Assert-Equal $hosts[-1] '192.168.1.254' 'lan last'
Assert-True ($hosts -notcontains '192.168.1.37') 'lan excludes self'
```

- [ ] **Step 2: รัน SelfTest ให้ fail**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\jhcis-installer.ps1 -SelfTest`
Expected: error `Get-AppKind` is not recognized (exit ≠ 0)

- [ ] **Step 3: Implement ทั้ง 8 ฟังก์ชันใน region Pure**

- `Get-AppKind`: regex ตาม spec 6.2 ใช้ `-imatch` ตามลำดับ client, server, java
- `Get-SilentUninstallCommand`: ถ้า `-imatch 'msiexec.*?(\{[0-9A-F-]+\})'` → `msiexec.exe` + `"/x $guid /qb /norestart"`; ไม่งั้นลบ `"` ทั้งหมด trim ถ้า `-imatch '\.exe$'` → FilePath = สตริงนั้น Arguments = `"/S _?=" + (Split-Path $exe)`; อื่น → `$null`
- `Get-MysqlVersionFromHandshake`: ต้อง `Length -ge 6` และ `$Bytes[4] -eq 0x0A`; หา index ของ 0 ตั้งแต่ตำแหน่ง 5; ถ้าไม่พบหรือ `-le 5` → `$null`; คืน ASCII ของช่วง 5..(end-1)
- `Test-GetdownContent`: `$Text -match 'appbase\s*='` และไม่ `-match '<html'` (ไม่สนตัวพิมพ์)
- `ConvertTo-Port`: `[int]::TryParse`, ช่วง 1..65535
- `Get-LanHosts`: `1..254 | % { "$Base$_" } | ? { $_ -ne $LocalIp }`

- [ ] **Step 4: รัน SelfTest ให้ผ่าน**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\jhcis-installer.ps1 -SelfTest`
Expected: `0 failed`, exit 0

- [ ] **Step 5: Commit**

```bash
git add jhcis-installer.ps1
git commit -m "feat: pure helpers for app classification, uninstall command, MySQL handshake, sha256, port/ip parsing"
```

---

### Task 3: System queries, child process, Wait-UiUntil, writable dir

**Files:**
- Modify: `jhcis-installer.ps1` region System + asserts

**Interfaces:**
- Produces:
  - `Wait-UiUntil([scriptblock]$Condition, [int]$TimeoutMs = -1, [scriptblock]$OnTick = $null)` → bool (true = เงื่อนไขเป็นจริง, false = หมดเวลา) loop: `[Windows.Forms.Application]::DoEvents(); & $OnTick; Start-Sleep -Milliseconds 50`
  - `Invoke-Child([string]$FilePath, [string]$Arguments = '', [switch]$Hidden, [string]$WorkingDirectory = '')` → int exit code; `-1` ถ้า start ไม่ได้ (log err) ใช้ `Start-Process -PassThru` (+`-WindowStyle Hidden` เมื่อ `$Hidden`, ไม่ส่ง `-ArgumentList` เมื่อว่าง) แล้ว `Wait-UiUntil { $p.HasExited }`
  - `Get-WritableDir([string]$Preferred)` → `$Preferred` ถ้าสร้าง+ลบไฟล์ทดสอบได้ ไม่งั้น `$env:TEMP`
  - `Get-InstalledApps()` → `[pscustomobject[]]` `{Name, Version, Uninstall, Kind}` เฉพาะที่ `Get-AppKind` ไม่ใช่ `$null` อ่านจาก 2 registry path ใน spec 6.2 ด้วย `Get-ItemProperty -ErrorAction SilentlyContinue`
  - `Find-InstallPath()` → path แรกใน `$Script:InstallPathCandidates` ที่มี หรือ `$null`
  - `Get-SubnetBases()` → `[pscustomobject[]]` `{Base, LocalIp, Interface}` จาก `Get-NetIPAddress -AddressFamily IPv4` ตัด loopback (`127.*`) และ APIPA (`169.254.*`) และ `PrefixOrigin WellKnown`
- หลัง `Get-WritableDir` มีแล้ว: ตั้ง `$Script:WorkDir = Get-WritableDir $Script:BaseDir` และ `$Script:LogFile = Join-Path $Script:WorkDir 'jhcis-installer.log'` (ย้ายจาก Task 1)

- [ ] **Step 1: เพิ่ม assert**

```powershell
Assert-Equal (Invoke-Child 'cmd.exe' '/c exit 3' -Hidden) 3 'child exit code'
Assert-Equal (Invoke-Child 'C:\definitely\missing.exe' '' -Hidden) -1 'child missing -> -1'
$sw = [Diagnostics.Stopwatch]::StartNew()
Assert-True (-not (Wait-UiUntil { $false } 300)) 'wait timeout returns false'
Assert-True ($sw.ElapsedMilliseconds -ge 250) 'wait actually waited'
Assert-True (Wait-UiUntil { $true } 1000) 'wait condition true'
Assert-Equal (Get-WritableDir 'Z:\no\such\dir') $env:TEMP 'writable dir fallback'
Assert-Equal (Get-WritableDir $env:TEMP) $env:TEMP 'writable dir ok'
$apps = @(Get-InstalledApps)
Assert-True (@($apps | ? { $_.Kind -notin 'client','server','java' }).Count -eq 0) 'installed apps kinds filtered'
$subs = @(Get-SubnetBases)
Assert-True (@($subs | ? { $_.Base -notmatch '^\d+\.\d+\.\d+\.$' }).Count -eq 0) 'subnet base format'
Assert-True (@($subs | ? { $_.Base -like '127.*' -or $_.Base -like '169.254.*' }).Count -eq 0) 'subnet excludes loopback/apipa'
Assert-True ((Find-InstallPath) -eq $null -or (Test-Path (Find-InstallPath))) 'find install path sane'
```

- [ ] **Step 2: รันให้ fail** — Expected: `Invoke-Child` not recognized

- [ ] **Step 3: Implement ทั้ง 7 ฟังก์ชัน + ย้าย `$Script:LogFile`**

- [ ] **Step 4: รันให้ผ่าน** — Expected: `0 failed`

- [ ] **Step 5: Commit** — `git commit -am "feat: child process runner, UI-safe wait loop, installed app and subnet queries"`

---

### Task 4: LAN scan

**Files:**
- Modify: `jhcis-installer.ps1` region System + asserts

**Interfaces:**
- Consumes: `Wait-UiUntil`, `Get-SubnetBases`, `Get-LanHosts`, `Get-MysqlVersionFromHandshake`
- Produces:
  - `Read-MysqlHandshake([Net.Sockets.TcpClient]$Client)` → version string หรือ `$null` (`GetStream().ReadTimeout = 1500`, อ่านสูงสุด 256 bytes, try/catch → `$null`)
  - `Find-MysqlServers([int]$Port, [scriptblock]$OnProgress = $null)` → `[pscustomobject[]]` `{Host, Port, Version}` เรียกต่อ subnet: สร้าง `TcpClient` + `ConnectAsync` ทุก host พร้อมกัน → `Wait-UiUntil { ทุก task IsCompleted } 800 -OnTick { & $OnProgress $done $total $found }` → host ที่ `Connected` → `Read-MysqlHandshake` → ไม่ `$null` ก็เพิ่ม (ไม่ซ้ำ host) → `Dispose` ทุก client

- [ ] **Step 1: เพิ่ม assert (fake MySQL บน loopback)**

```powershell
$listener = New-Object Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, 0); $listener.Start()
$lport = $listener.LocalEndpoint.Port
$accept = $listener.AcceptTcpClientAsync()
$cli = New-Object Net.Sockets.TcpClient; $conn = $cli.ConnectAsync('127.0.0.1', $lport)
Assert-True (Wait-UiUntil { $conn.IsCompleted -and $accept.IsCompleted } 3000) 'fake mysql connected'
$srv = $accept.Result
$hs = [byte[]](0x4A,0,0,0,0x0A) + [Text.Encoding]::ASCII.GetBytes('5.6.45-test') + [byte[]](0,1,2,3)
$srv.GetStream().Write($hs, 0, $hs.Length)
Assert-Equal (Read-MysqlHandshake $cli) '5.6.45-test' 'read handshake from socket'
$cli.Dispose(); $srv.Dispose(); $listener.Stop()
$cli2 = New-Object Net.Sockets.TcpClient
Assert-Equal (Read-MysqlHandshake $cli2) $null 'read handshake unconnected -> null'
```

- [ ] **Step 2: รันให้ fail** — Expected: `Read-MysqlHandshake` not recognized

- [ ] **Step 3: Implement `Read-MysqlHandshake` และ `Find-MysqlServers`**

- [ ] **Step 4: รันให้ผ่าน** — Expected: `0 failed`

- [ ] **Step 5: ทดสอบสแกนจริงกับวงแลนเครื่อง dev**

เพิ่มใน `Invoke-SelfTest` (opt-in ถาวร): `if ($env:JHCIS_SCAN) { $sw=[Diagnostics.Stopwatch]::StartNew(); $r=@(Find-MysqlServers 3306); Write-Host "scan: $($r.Count) found in $($sw.ElapsedMilliseconds) ms: $($r | % { "$($_.Host) $($_.Version)" })" }`
Run: `$env:JHCIS_SCAN=1; powershell -NoProfile -ExecutionPolicy Bypass -File .\jhcis-installer.ps1 -SelfTest; Remove-Item Env:JHCIS_SCAN`
Expected: บรรทัด `scan: ...` ใช้เวลาไม่เกิน ~3000 ms ต่อ subnet (ไม่ค้าง 21 วินาทีต่อ host) จำนวนที่พบขึ้นกับเครื่องในวง เก็บบรรทัดนี้ไว้ได้ (เป็น opt-in)

- [ ] **Step 6: Commit** — `git commit -am "feat: parallel LAN scan for MySQL servers with handshake version"`

---

### Task 5: หา/ดาวน์โหลด payload

**Files:**
- Modify: `jhcis-installer.ps1` region System + asserts

**Interfaces:**
- Consumes: `Test-FileSha256`, `Wait-UiUntil`, `Write-Log`
- Produces: `Resolve-PayloadFile([string]$Name, [string]$Sha256, [long]$Size, [string]$Url, [string[]]$SearchDirs, [string]$DownloadDir, [scriptblock]$OnProgress = $null, [scriptblock]$ConfirmUseMismatch = $null)` → path หรือ `$null`
  - ลำดับ: ทุก `$SearchDirs` หา `Join-Path $dir $Name`; เจอ+sha ตรง → คืน; เจอ+ไม่ตรง → `& $ConfirmUseMismatch $path` (default = MessageBox YesNo ข้อความ `"ไฟล์ {0} มีอยู่แล้วแต่ไม่ตรงกับที่โปรแกรมรู้จัก ใช้ไฟล์นี้ต่อหรือไม่? (No = ดาวน์โหลดใหม่)"`) true → คืน path
  - ดาวน์โหลด: `$part = Join-Path $DownloadDir "$Name.part"`; ลบ `.part` เก่า; `WebClient.DownloadFileTaskAsync($Url, $part)`; `Wait-UiUntil { $task.IsCompleted } -OnTick { & $OnProgress (ขนาด .part ปัจจุบัน) $Size }`; `IsFaulted` → log err แล้วถือว่าล้ม; sha ตรง → `Move-Item $part (Join-Path $DownloadDir $Name) -Force` คืน path; ไม่ตรง → ลบ แล้วลองใหม่รวมสูงสุด **2 ครั้ง**; ยังไม่ตรง → ลบ, `Write-Log err 'ไฟล์ที่โหลดมาไม่ตรงกับที่โปรแกรมรู้จัก โปรแกรมเวอร์ชันนี้อาจเก่า กรุณาโหลดโปรแกรมเวอร์ชันใหม่'` คืน `$null`
  - `$OnProgress` รับ `($bytesDone, $bytesTotal)`

- [ ] **Step 1: เพิ่ม assert (ใช้ `file://` URL)**

```powershell
$src = Join-Path $env:TEMP ("payload-src-{0}.bin" -f [guid]::NewGuid())
$bytes = New-Object byte[] 1048576; (New-Object Random).NextBytes($bytes); [IO.File]::WriteAllBytes($src, $bytes)
$sha = (Get-FileHash $src -Algorithm SHA256).Hash
$url = ([Uri]$src).AbsoluteUri
$d1 = Join-Path $env:TEMP ("payload-d1-{0}" -f [guid]::NewGuid()); New-Item -ItemType Directory $d1 | Out-Null
$Script:TestProg = 0
$got = Resolve-PayloadFile -Name 'p.bin' -Sha256 $sha -Size $bytes.Length -Url $url -SearchDirs @($d1) -DownloadDir $d1 -OnProgress { param($a,$b) $Script:TestProg++ }
Assert-Equal $got (Join-Path $d1 'p.bin') 'payload downloaded to download dir'
Assert-True ($Script:TestProg -ge 1) 'payload progress callback called'
Assert-True (Test-FileSha256 $got $sha) 'payload downloaded sha ok'
Assert-True (-not (Test-Path "$got.part")) 'payload no .part left'
Assert-Equal (Resolve-PayloadFile -Name 'p.bin' -Sha256 $sha -Size $bytes.Length -Url 'file:///Z:/missing.bin' -SearchDirs @($d1) -DownloadDir $d1) $got 'payload found locally, no download'
$d2 = Join-Path $env:TEMP ("payload-d2-{0}" -f [guid]::NewGuid()); New-Item -ItemType Directory $d2 | Out-Null
Assert-Equal (Resolve-PayloadFile -Name 'p.bin' -Sha256 ('0'*64) -Size $bytes.Length -Url $url -SearchDirs @($d2) -DownloadDir $d2) $null 'payload bad sha -> null'
Assert-True (-not (Test-Path (Join-Path $d2 'p.bin')) -and -not (Test-Path (Join-Path $d2 'p.bin.part'))) 'payload bad sha leaves nothing'
Assert-Equal (Resolve-PayloadFile -Name 'p.bin' -Sha256 ('0'*64) -Size 1 -Url $url -SearchDirs @($d1) -DownloadDir $d1 -ConfirmUseMismatch { $true }) $got 'payload local mismatch, user accepts'
Assert-Equal (Resolve-PayloadFile -Name 'p.bin' -Sha256 $sha -Size 1 -Url 'file:///Z:/missing.bin' -SearchDirs @($d2) -DownloadDir $d2) $null 'payload download failure -> null'
Remove-Item $src, $d1, $d2 -Recurse -Force
```

- [ ] **Step 2: รันให้ fail** — Expected: `Resolve-PayloadFile` not recognized

- [ ] **Step 3: Implement `Resolve-PayloadFile`**

- [ ] **Step 4: รันให้ผ่าน** — Expected: `0 failed` (ทดสอบนี้ใช้เวลาไม่กี่วินาที)

- [ ] **Step 5: Commit** — `git commit -am "feat: locate or download payload with sha256 verification and single retry"`

---

### Task 6: Install actions

**Files:**
- Modify: `jhcis-installer.ps1` region System + asserts

**Interfaces:**
- Consumes: `Invoke-Child`, `Get-SilentUninstallCommand`, `Test-GetdownContent`, `Write-Log`
- Produces:
  - `Uninstall-App([pscustomobject]$App)` → bool; `$null` command → `Write-Log err "ไม่รู้วิธีถอน $($App.Name) - กรุณาถอนเองใน Control Panel"` false; รัน `Invoke-Child $cmd.FilePath $cmd.Arguments -Hidden`; สำเร็จเมื่อ exit ∈ {0,1605,3010} (3010 → log เพิ่ม "ควร restart เครื่องภายหลัง")
  - `Grant-FullPermissions([string]$Path)` → bool; `$Path = $Path.TrimEnd('\')`; ไม่มีโฟลเดอร์ → log err false; `Invoke-Child 'icacls.exe' "`"$Path`" /T /C /Q /grant *S-1-5-32-545:(OI)(CI)F /grant *S-1-5-32-544:(OI)(CI)F /grant `"$env:USERNAME`":(OI)(CI)F" -Hidden` exit 0 → true
  - `Get-GetdownText([string]$Url = $Script:GetdownUrl, [int]$TimeoutMs = 10000)` → string; ใช้ `Invoke-WebRequest -UseBasicParsing -TimeoutSec` (วินาที = ceil(ms/1000)) ใน try/catch; `Test-GetdownContent` ผ่าน → remote ไม่งั้น `$Script:GetdownFallback` (+ `Write-Log warn`)
  - `Set-GetdownFile([string]$InstallPath, [string]$Text)` → bool; ไม่มีโฟลเดอร์ → false; มี `getdown.txt` เดิม → `Copy-Item` เป็น `getdown.txt.bak` (ทับ); เขียน UTF-8 ไม่มี BOM (`[IO.File]::WriteAllText($t, $Text, (New-Object Text.UTF8Encoding $false))`)
  - `Disable-JavaUpdate()` → bool; ตาม spec 6.8 ผ่าน `Invoke-Child 'reg.exe' ... -Hidden`; `reg delete` ไม่นับ fail; `reg add` ล้ม ≥1 → log err false

- [ ] **Step 1: เพิ่ม assert**

```powershell
$gd = Join-Path $env:TEMP ("getdown-{0}" -f [guid]::NewGuid()); New-Item -ItemType Directory $gd | Out-Null
Assert-True (Set-GetdownFile $gd 'appbase = one') 'getdown write first'
Assert-True (Set-GetdownFile $gd 'appbase = two') 'getdown write second'
Assert-Equal (Get-Content (Join-Path $gd 'getdown.txt') -Raw) 'appbase = two' 'getdown current content'
Assert-Equal (Get-Content (Join-Path $gd 'getdown.txt.bak') -Raw) 'appbase = one' 'getdown backup content'
Assert-Equal ((Get-Content (Join-Path $gd 'getdown.txt') -Encoding Byte -TotalCount 3) -join ',') '97,112,112' 'getdown no BOM'
Assert-True (-not (Set-GetdownFile (Join-Path $gd 'missing') 'x')) 'getdown missing dir -> false'
Assert-Equal (Get-GetdownText 'http://127.0.0.1:9/getdown.txt' 1000) $Script:GetdownFallback 'getdown unreachable -> fallback'
Assert-True (Grant-FullPermissions $gd) 'icacls on temp dir'
Assert-True (Grant-FullPermissions "$gd\") 'icacls trailing backslash'
Assert-True (-not (Grant-FullPermissions (Join-Path $gd 'missing'))) 'icacls missing -> false'
Assert-True (-not (Uninstall-App ([pscustomobject]@{Name='X';Version='';Uninstall='rundll32 foo';Kind='client'}))) 'uninstall unknown -> false'
Remove-Item $gd -Recurse -Force
```

- [ ] **Step 2: รันให้ fail** — Expected: `Set-GetdownFile` not recognized

- [ ] **Step 3: Implement ทั้ง 5 ฟังก์ชัน**

- [ ] **Step 4: รันให้ผ่าน** — Expected: `0 failed`

- [ ] **Step 5: ทดสอบ `Disable-JavaUpdate` จริง (ต้องเป็น admin)**

Run (PowerShell ที่เปิดแบบ Run as administrator): `$env:JHCIS_JAVA=1; powershell -NoProfile -ExecutionPolicy Bypass -File .\jhcis-installer.ps1 -SelfTest` โดยเพิ่มใน `Invoke-SelfTest`: `if ($env:JHCIS_JAVA) { Assert-True (Disable-JavaUpdate) 'disable java update (admin)' }`
Then: `reg query "HKLM\SOFTWARE\JavaSoft\Java Update\Policy" /v EnableJavaUpdate`
Expected: `EnableJavaUpdate    REG_DWORD    0x0`

- [ ] **Step 6: Commit** — `git commit -am "feat: uninstall, icacls permissions, getdown.txt placement, Java auto-update disable"`

---

### Task 7: หน้าต่าง WinForms และ flow การติดตั้ง

**Files:**
- Modify: `jhcis-installer.ps1` region Log (เพิ่ม RichTextBox), Elevation, UI

**Interfaces:**
- Consumes: ทุกฟังก์ชันจาก Task 2-6
- Produces (ชื่อ control ใน scope script): `$Form`, `$CboServer` (ComboBox DropDown), `$BtnScan`, `$TxtPort`, `$LblOdbc`, `$ChkUninstall`, `$ChkInstall`, `$ChkPerm`, `$TxtInstallPath`, `$ChkUpdate`, `$ChkGetdown`, `$ChkJava`, `$BtnStart`, `$BtnClose`, `$Progress` (ProgressBar), `$LogBox` (RichTextBox ReadOnly) และ `$Script:Running` (bool), `$Script:InstalledApps`, `$Script:IsServerMachine`
- Produces: `Invoke-InstallFlow()` ทำขั้นตอนตาม checkbox ตามลำดับ spec 6.3→6.8 (Uninstall → Install → Perm → Update → Getdown → Java) แต่ละขั้นใน try/catch → `Write-Log err` แล้วทำต่อ
- Produces: `Start-Scan()` อัปเดต `$CboServer.Items` เป็น `"<Host> (<Version>)"` เลือก index 0; ไม่พบ → `Write-Log warn 'ไม่พบ MySQL server ในวงแลน - พิมพ์ IP เครื่องแม่เองในช่อง IP'`
- Produces: `Set-UiBusy([bool]$Busy)` disable/enable input ทั้งหมด + `$Progress.Style`

- [ ] **Step 1: Elevation (ps1 เท่านั้น)** ก่อน region UI: ถ้าไม่ใช่ admin (`WindowsPrincipal.IsInRole Administrator`) และ `$PSCommandPath` ไม่ว่าง → `Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""` แล้ว `exit`; ถ้าไม่ใช่ admin และ `$PSCommandPath` ว่าง (exe ไม่มี manifest) → ทำต่อแล้ว `Write-Log warn` หลังสร้างฟอร์ม

- [ ] **Step 2: สร้างฟอร์มตาม spec §5** `ClientSize 560x680`, `FormBorderStyle FixedSingle`, `MaximizeBox $false`, `StartPosition CenterScreen`, `Font 'Segoe UI',10`, `Text "ติดตั้ง JHCIS Client v$($Script:Version)"` สอง GroupBox ("เครื่องแม่ (MySQL Server)", "ขั้นตอน") ปุ่ม/progress/log ตามผัง ข้อความ checkbox ตรงตาม spec; `$TxtPort.Text = $Script:DefaultPort`; `$TxtInstallPath.Text = (Find-InstallPath) ?? default` (เขียนด้วย if); `$LblOdbc.Text = "ค่าที่ต้องกรอกตอน installer ถาม ODBC: user=root  password=$($Script:DefaultPassword)  database=jhcisdb"`

- [ ] **Step 3: `Write-Log` เพิ่ม UI** ถ้า `$Script:LogBox` มีค่า → `SelectionStart = TextLength; SelectionColor` (ok=Green, err=Red, warn=DarkOrange, info=Black); `AppendText(line + "`r`n")`; `ScrollToCaret()`

- [ ] **Step 4: Form `Shown` handler** → `$Script:InstalledApps = @(Get-InstalledApps)`; `$Script:IsServerMachine = มี Kind server`; ถ้าใช่ → MessageBox YesNo `"เครื่องนี้มี JHCIS Server ติดตั้งอยู่ - โปรแกรมนี้ใช้กับเครื่องลูกเท่านั้น (จะไม่ถอน Java เพราะเครื่องแม่ต้องใช้)`n`nดำเนินการต่อจริงหรือไม่?"` No → `$Form.Close()`; รายการถอน = client + (java ถ้าไม่ใช่เครื่องแม่); ตั้ง `$ChkUninstall.Text` เป็น `"ถอน JHCIS Client / Java ตัวเดิม  (พบ N รายการ)"` หรือ `"... (ไม่พบของเดิม)"` + `Checked=$false; Enabled=$false`; `Write-Log info` ชื่อแต่ละตัวที่พบ; แล้ว `Start-Scan`

- [ ] **Step 5: `Start-Scan`** `Set-UiBusy $true` (ยกเว้น `$BtnStart` ให้กดได้ตาม spec) → `Find-MysqlServers (ConvertTo-Port $TxtPort.Text) -OnProgress { $Progress.Value = done*100/total }` → เติม combo → `Set-UiBusy $false`; `$BtnScan.Click` เรียกอันเดียวกัน

- [ ] **Step 6: `Invoke-InstallFlow`** ลำดับและข้อความ log:
  1. ถ้า `$ChkUninstall.Checked` → `Uninstall-App` ทีละตัว client ก่อน java
  2. ถ้า `$ChkInstall.Checked` → `Resolve-PayloadFile` Client (`SearchDirs = @($Script:BaseDir, (Join-Path $Script:BaseDir 'JHCIS-install-jre_jdk_64\jHCIS-All-PCU'))`, `DownloadDir = $Script:WorkDir`, `OnProgress` → progress bar + log ทุก 10%); `$null` → ข้าม; มี → MessageBox OK `"เมื่อ installer ถามค่า ODBC ให้กรอก:`nIP = <ip>`nPort = <port>`nuser = root`npassword = 123456`ndatabase = jhcisdb"` (ip จาก `Get-IpFromServerText $CboServer.Text`, ว่าง → `"(ไม่พบ - กรอกเอง)"`) → `Invoke-Child $path` → exit ≠ 0 → `Write-Log warn 'ตัวติดตั้งจบโดยไม่สำเร็จ - ดำเนินการต่อ (อาจเป็นเพราะปิด installer ก่อนติดตั้งเสร็จ)'`; จบแล้ว ถ้า `$TxtInstallPath.Text -eq $Script:DefaultInstallPath` และ `Find-InstallPath` ไม่ `$null` → อัปเดตช่อง
  3. ถ้า `$ChkPerm.Checked` → `Grant-FullPermissions $TxtInstallPath.Text`
  4. ถ้า `$ChkUpdate.Checked` → `Resolve-PayloadFile` Updater (`SearchDirs = @($Script:BaseDir)`) → `Invoke-Child`
  5. ถ้า `$ChkGetdown.Checked` → `Set-GetdownFile $TxtInstallPath.Text (Get-GetdownText)`
  6. ถ้า `$ChkJava.Checked` → `Disable-JavaUpdate`
  จบ → `Write-Log ok 'การติดตั้งเสร็จสิ้น'` + MessageBox `"การติดตั้งเสร็จสิ้น`nเปิดโปรแกรม JHCIS จาก shortcut บน Desktop ได้เลย"`
  `$BtnStart.Click` → `$Script:Running=$true; Set-UiBusy $true; try { Invoke-InstallFlow } finally { Set-UiBusy $false; $Script:Running=$false }`

- [ ] **Step 7: ปิดกลางคัน** `$Form.add_FormClosing({ if ($Script:Running) { ถาม YesNo "กำลังติดตั้งอยู่ ปิดโปรแกรมจริงหรือไม่? (โปรแกรมติดตั้งที่เปิดอยู่จะทำงานต่อจนจบเอง)"; No → $_.Cancel=$true; Yes → Write-Log warn 'ผู้ใช้ปิดโปรแกรมกลางคัน'; Remove-Item (Join-Path $Script:WorkDir '*.part') -ErrorAction SilentlyContinue } })`; `$BtnClose.Click → $Form.Close()`; ท้ายไฟล์ `[Windows.Forms.Application]::EnableVisualStyles(); [Windows.Forms.Application]::Run($Form)`; `Write-Log info "=== เริ่มโปรแกรม v$Version $(Get-Date -Format s) ==="` ตอนฟอร์ม Shown (บรรทัดคั่น run)

- [ ] **Step 8: SelfTest ยังผ่าน** Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\jhcis-installer.ps1 -SelfTest` Expected: `0 failed` และไม่มีหน้าต่างเด้ง

- [ ] **Step 9: Smoke test หน้าต่าง (ไม่แตะ JHCIS จริง)**

Run: `.\run.cmd` (UAC เด้ง → Yes)
Expected ตรวจตามนี้:
  - หน้าต่างชื่อ `ติดตั้ง JHCIS Client v2.0.0` ภาษาไทยทุกตัวแสดงถูก (สระ/วรรณยุกต์ซ้อนถูกตำแหน่ง)
  - log มีบรรทัด `===`, รายการโปรแกรมที่พบ, บรรทัดสแกน progress bar วิ่ง หน้าต่างลากได้ระหว่างสแกน (ไม่ Not Responding)
  - checkbox ถอนของเดิมแสดง `(ไม่พบของเดิม)` หรือจำนวนจริง
  - สร้างโฟลเดอร์ `%TEMP%\jhcis-smoke` ใส่ path นี้ในช่อง path ติ๊กเฉพาะ "ตั้ง permission" + "วาง getdown.txt" กดเริ่ม → log ✓ ทั้งสอง มีไฟล์ `%TEMP%\jhcis-smoke\getdown.txt` (เนื้อหาจากเว็บหรือ fallback) และ MessageBox เสร็จสิ้น
  - ติ๊กเฉพาะ "อัปเดต version ใหม่" กดเริ่ม → log ✗ ดาวน์โหลดล้มเหลว (release ยังไม่มี) โปรแกรมไม่ crash ยังกดต่อได้
  - กด X ระหว่างสแกน → ไม่ถาม (ยังไม่ Running) ปิดได้ / กด X ระหว่างขั้นตอน → ถามยืนยัน
  - ไฟล์ `jhcis-installer.log` ข้างสคริปต์มีข้อความไทยอ่านได้ใน Notepad

- [ ] **Step 10: Commit** — `git commit -am "feat: WinForms single-window UI with scan, step checklist, install flow and log"`

---

### Task 8: build.ps1, README, ลบ TypeScript, .gitignore

**Files:**
- Create: `build.ps1`
- Modify: `README.md` (เขียนใหม่ทั้งไฟล์), `.gitignore` (เขียนใหม่ทั้งไฟล์)
- Delete: `index.ts`, `src/` (ทั้งโฟลเดอร์ รวม `getdown.txt` ที่ย้ายเข้าสคริปต์แล้ว), `scripts/build.ts` (และโฟลเดอร์ `scripts/` ถ้าว่าง), `package.json`, `bun.lock`, `tsconfig.json`, `app.manifest`, `node_modules/` (ไม่อยู่ใน git แค่ลบจากดิสก์)

**Interfaces:**
- Produces: `build.ps1` ลำดับ: (1) ตรวจ BOM ของ `jhcis-installer.ps1` ไม่มี → `throw`; (2) รัน `-SelfTest` ผ่าน `powershell -NoProfile -ExecutionPolicy Bypass -File` exit ≠ 0 → `throw`; (3) `Get-Module -ListAvailable ps2exe` ไม่มี → `Install-Module ps2exe -Scope CurrentUser -Force`; (4) อ่าน version จากบรรทัด `$Script:Version = '...'`; (5) `Invoke-ps2exe -inputFile .\jhcis-installer.ps1 -outputFile .\dist\jhcis-installer.exe -noConsole -requireAdmin -x64 -title 'JHCIS Client Installer' -product 'PowerPCU JHCIS Installer' -version "$version.0"`; (6) copy `jhcis-installer.ps1`, `run.cmd` ไป `dist\`; (7) ขนาด exe ≥ 1 MB → `throw`; พิมพ์ขนาดทุกไฟล์ใน `dist\`
- `.gitignore` ใหม่: `dist/`, `*.log`, `JHCIS-install-jre_jdk_64/`, `JHCIS_Update.exe`, `.superpowers/`, `.idea`, `.DS_Store`

- [ ] **Step 1: เขียน `build.ps1`**

- [ ] **Step 2: รัน build**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`
Expected: เห็น `0 failed` จาก SelfTest, ps2exe compile สำเร็จ, บรรทัดขนาด `dist\jhcis-installer.exe` น้อยกว่า 1,048,576 bytes, มี `dist\jhcis-installer.ps1`, `dist\run.cmd`

- [ ] **Step 3: Smoke test exe** Run: `.\dist\jhcis-installer.exe` (UAC → Yes) Expected: หน้าต่างเดิมเปิดขึ้น ไม่มี console เด้ง ไม่มี MessageBox แปลกๆ จาก Write-Host; log file เกิดที่ `dist\jhcis-installer.log`; ปิดหน้าต่าง

- [ ] **Step 4: ลบไฟล์เดิม + .gitignore**

```bash
git rm -r index.ts src scripts package.json bun.lock tsconfig.json app.manifest
rm -rf node_modules
```
เขียน `.gitignore` ใหม่ตาม Interfaces

- [ ] **Step 5: เขียน `README.md` ใหม่ (ไทย)** หัวข้อ: โปรแกรมนี้ทำอะไร (6 ขั้นตอน); วิธีใช้หน้างาน (โหลด `jhcis-installer.exe` จาก release ล่าสุด → ใส่ flash drive → ดับเบิลคลิก → Yes ที่ UAC; ถ้า antivirus ไม่ให้รัน exe ใช้ `run.cmd` + `jhcis-installer.ps1` แทน; โหลดครั้งแรกจะดาวน์โหลด ~450 MB เก็บไว้ข้าง exe); build (`.\build.ps1`); ทดสอบ (`-SelfTest`); ออก release โปรแกรม (`gh release create vX.Y.Z dist\jhcis-installer.exe dist\jhcis-installer.ps1 dist\run.cmd`); อัปเดต payload เมื่อกรมฯ ออกไฟล์ใหม่ (สร้าง tag `payload-YYYY-MM` ใหม่ → `gh release create payload-YYYY-MM <ไฟล์> --title ...` → แก้ `$Script:PayloadTag`/Name/Size/Sha256 ในสคริปต์ → bump version → ออก release ใหม่ ห้ามอัปโหลดทับ tag เดิม); ลิงก์ spec/plan

- [ ] **Step 6: ตรวจว่า repo สะอาด** Run: `git status --short; ls` Expected: ไม่มี .ts/.json ของ bun เหลือ; มี `jhcis-installer.ps1 run.cmd build.ps1 README.md .gitignore docs/`

- [ ] **Step 7: Commit** — `git add -A && git commit -m "chore: build script with ps2exe, rewrite README, remove TypeScript/Bun implementation"`

---

### Task 9: เผยแพร่ (repo public, payload release, program release)

**Files:** ไม่แก้ไฟล์ใน repo (เฉพาะ GitHub)

**Interfaces:**
- Consumes: ไฟล์ payload ที่ main checkout: `C:\Users\usman\repo\powerpcu_j_install\JHCIS-install-jre_jdk_64\jHCIS-All-PCU\jhcis-install-client-jre8-0-191_64.exe`, `C:\Users\usman\repo\powerpcu_j_install\JHCIS_Update.exe`; `dist\*` จาก Task 8

- [ ] **Step 1: ขอยืนยันจากผู้ใช้** ก่อนรันคำสั่งใดใน Task นี้ แจ้งว่าจะ (ก) เปลี่ยน repo เป็น public ถาวร (ข) อัปโหลด ~470 MB ขึ้น release สาธารณะ รอคำตอบ "ยืนยัน" เท่านั้น

- [ ] **Step 2: merge branch เข้า main และ push**

```bash
git checkout main && git merge --ff-only rewrite-powershell && git push origin main
```

- [ ] **Step 3: เปลี่ยน repo เป็น public**

Run: `gh repo edit usman-coe/powerpcu_j_install --visibility public --accept-visibility-change-consequences`
Then: `gh repo view --json visibility -q .visibility` Expected: `PUBLIC`

- [ ] **Step 4: สร้าง payload release**

Run: `gh release create payload-2026-10 "C:\Users\usman\repo\powerpcu_j_install\JHCIS-install-jre_jdk_64\jHCIS-All-PCU\jhcis-install-client-jre8-0-191_64.exe" "C:\Users\usman\repo\powerpcu_j_install\JHCIS_Update.exe" --title "JHCIS payload 2026-10" --notes "ไฟล์ติดตั้งจากกรมฯ (jhcis.moph.go.th) ชุดเดือน 10/2026 สำหรับ jhcis-installer ห้ามอัปโหลดทับ ให้สร้าง tag ใหม่เมื่อมีไฟล์ใหม่"` (ใช้เวลาอัปโหลดหลายนาที)

- [ ] **Step 5: ตรวจ URL และ hash ของจริง**

Run:
```powershell
$u='https://github.com/usman-coe/powerpcu_j_install/releases/download/payload-2026-10/JHCIS_Update.exe'
$t=Join-Path $env:TEMP 'JHCIS_Update.check.exe'; Invoke-WebRequest $u -OutFile $t; (Get-FileHash $t -Algorithm SHA256).Hash; (Get-Item $t).Length; Remove-Item $t
(Invoke-WebRequest 'https://github.com/usman-coe/powerpcu_j_install/releases/download/payload-2026-10/jhcis-install-client-jre8-0-191_64.exe' -Method Head).Headers['Content-Length']
```
Expected: `644A9581FF6D61DB2E2F7D1B8AAA05D2863579F9B51D8A06F691F038A06E2313`, `41472028`, `426366287`

- [ ] **Step 6: สร้าง program release**

Run: `gh release create v2.0.0 dist\jhcis-installer.exe dist\jhcis-installer.ps1 dist\run.cmd --title "jhcis-installer v2.0.0" --notes "เขียนใหม่เป็น PowerShell + WinForms ขนาดไม่ถึง 1 MB ดาวน์โหลดไฟล์ติดตั้งจาก release payload-2026-10 หน้างาน"`
Then: `gh release view v2.0.0 --json assets -q '.assets[].name'` Expected: 3 ชื่อไฟล์

- [ ] **Step 7: ทดสอบ end-to-end ดาวน์โหลดผ่านโปรแกรม (ไม่ติดตั้งจริง)** copy `dist\jhcis-installer.exe` ไปโฟลเดอร์ว่างใน `%TEMP%` → รัน → ติ๊กเฉพาะ "อัปเดต version ใหม่" → เริ่ม → log แสดง progress ดาวน์โหลด 41 MB → sha ตรง → หน้าต่าง JHCIS_Update.exe ของกรมฯ เปิดขึ้น → **ปิดหน้าต่าง updater ทันทีโดยไม่กดอะไร** → log ! exit ≠ 0 → เสร็จสิ้น; ตรวจว่ามี `JHCIS_Update.exe` วางข้าง exe และไม่มี `.part`

---

## Self-review (ทำแล้ว)

- **Spec coverage**: §4 config/ps2exe/fallback/log/ลบ code เดิม → Task 1,7,8; §4.1-4.2 → Task 5,9; §5 UI ทุก bullet → Task 7 (Shown handler, Start-Scan, Set-UiBusy, FormClosing); §6.1 → Task 4; §6.2-6.3 → Task 2,3,6; §6.4 → Task 5,7 step 6; §6.5-6.8 → Task 6; §7 → Task 8; §8 → ทุก Task มี `-SelfTest` และ build รันก่อน
- **Type consistency**: `Resolve-PayloadFile` คืน path/`$null` ใช้ตรงกันใน Task 5 และ 7; `Get-SilentUninstallCommand` คืน `{FilePath, Arguments}` ใช้ใน `Uninstall-App` ผ่าน `Invoke-Child`; `$OnProgress` ของ scan = `(done,total,found)` ของ download = `(bytes,total)` ระบุไว้ทั้งสองที่
- **Review Focus** ทั้ง 5 ข้อมี assert ใน Task 2/3/6 แล้ว
- **ที่ตั้งใจไม่ทดสอบอัตโนมัติ**: `Find-MysqlServers` ทั้งก้อน (ขึ้นกับวงแลน) ทดสอบด้วย opt-in `JHCIS_SCAN`; `Disable-JavaUpdate` ต้อง admin ทดสอบด้วย opt-in `JHCIS_JAVA`; UI ทดสอบด้วย smoke checklist Task 7 step 9
