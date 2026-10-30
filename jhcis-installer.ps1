#requires -Version 5.1
param([switch]$SelfTest, [switch]$NoElevate)
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # ps2exe turns Write-Progress into a popup window
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Config
$Script:Version = '2.0.0'
$Script:PayloadTag = 'payload-2026-10'
$Script:PayloadBase = "https://github.com/usman-coe/powerpcu_j_install/releases/download/$($Script:PayloadTag)"
$Script:Payload = @{
    Client  = @{ Name = 'jhcis-install-client-jre8-0-191_64.exe'; Size = 426366287; Sha256 = 'ded0373a4a185f02714808ad96f8a423223809706cf45a1952ff962de74b9e19' }
    Updater = @{ Name = 'JHCIS_Update.exe'; Size = 41472028; Sha256 = '644a9581ff6d61db2e2f7d1b8aaa05d2863579f9b51d8a06f691f038a06e2313' }
}
$Script:DefaultPort = 3333
$Script:DefaultPassword = '123456'
$Script:DefaultInstallPath = 'C:\Program Files\jhcis-client'
$Script:InstallPathCandidates = @('C:\Program Files\jhcis-client','C:\Program Files (x86)\jhcis-client','C:\JHCIS','C:\jhcis','C:\JHCIS-Client','C:\Program Files\JHCIS','C:\Program Files (x86)\JHCIS')
$Script:GetdownUrl = 'https://jhcis.moph.go.th/files/getdown.txt'
$Script:LogBox = $null
$Script:Form = $null
$Script:ActiveWebClient = $null
$Script:GetdownFallback = @'
# JHCIS Update Configuration
appbase = https://7-sada.github.io/jhcis-update/

ui.name = JHCIS Updater
#ui.background = background.png
ui.progress = 20, 200, 300, 20  # ตำแหน่งและขนาดหลอดโหลด (x, y, width, height)
#ui.background_image = background.png


code = getdown-core-1.8.7.jar
code = JHCIS_Launcher.jar
code = Reports/Exclude/10_rpt_HT_Service.jasper
code = Reports/Exclude/11_rpt_HT_Presure.jasper
code = Reports/Exclude/12_1rpt_DMHT_CH09_chrfrg.jasper
code = Reports/Exclude/12_rpt_DMHT_CH09.jasper
code = Reports/Exclude/12_rpt_DMHT_egfr.jasper
code = Reports/Exclude/13_rpt_DMHT_MS0102_MS0202_MSUPCR.jasper
code = Reports/Exclude/14_rpt_DMHT_CVDRisk1.jasper
code = Reports/Exclude/14_rpt_DMHT_CVDRisk2.jasper
code = Reports/Exclude/15_rpt_HT_LipidProfile.jasper
code = Reports/Exclude/15_rpt_HT_Lipid_profile.jasper
code = Reports/Exclude/16_rpt_HT_LDL_lessthan100.jasper
code = Reports/Exclude/1_rpt_DMHT_Service.jasper
code = Reports/Exclude/2_rpt_DM_FBS_DTX.jasper
code = Reports/Exclude/3_rpt_DM_HbA1c.jasper
code = Reports/Exclude/3_rpt_DM_HbA1c_test.jasper
code = Reports/Exclude/4_1_rpt_DM_ch07.jasper
code = Reports/Exclude/4_2_rpt_DM_ch25.jasper
code = Reports/Exclude/4_3_rpt_DM_ch14.jasper
code = Reports/Exclude/4_4_rpt_DM_ch17.jasper
code = Reports/Exclude/5_rpt_DM_ch17_less100.jasper
code = Reports/Exclude/6_1_rpt_DM_footExam.jasper
code = Reports/Exclude/6_2_rpt_DM_EyeExam.jasper
code = Reports/Exclude/7_rpt_DM_Presure.jasper
code = Reports/Exclude/8_rpt_DM_Fatty.jasper
code = Reports/Exclude/9_rpt_DM_icd_R730.jasper
code = Reports/Exclude/AAAB.jasper
code = Reports/Exclude/AART.jasper
code = Reports/Exclude/acc07.jasper
code = Reports/Exclude/adl.jasper
code = Reports/Exclude/adl0to11.jasper
code = Reports/Exclude/BK5_MedCertify.jasper
code = Reports/Exclude/DrugOrder_sub_Lab_Past.jasper
code = Reports/Exclude/ExceptMEntal.jasper
code = Reports/Exclude/finan.jasper
code = Reports/Exclude/Graph_money1_2D.jasper
code = Reports/Exclude/Graph_Money1_3D.jasper
code = Reports/Exclude/HPV.jasper
code = Reports/Exclude/OPD_dmht - Copy.jasper
code = Reports/Exclude/OPD_dmht 0 byte.jasper
code = Reports/Exclude/OPD_dmht.jasper
code = Reports/Exclude/OPD_dmhtxx - Copy (3).jasper
code = Reports/Exclude/OPD_dmhtxx - Copy.jasper
code = Reports/Exclude/OPD_dmhtxx.jasper
code = Reports/Exclude/OPD_dmht_group_Concat.jasper
code = Reports/Exclude/Pathumthani_rpt_sumvisitgroupbyrightgroup.jasper
code = Reports/Exclude/Pathumthani_rpt_sumvisitGroupbyType.jasper
code = Reports/Exclude/percent_pyramid_graph.jasper
code = Reports/Exclude/personallergy_history.jasper
code = Reports/Exclude/pyramid_population_17.jasper
code = Reports/Exclude/QRCode_07101.jasper
code = Reports/Exclude/r1.jasper
code = Reports/Exclude/refer_card.jasper
code = Reports/Exclude/report1.jasper
code = Reports/Exclude/report11.jasper
code = Reports/Exclude/report1xxxx.jasper
code = Reports/Exclude/report6.jasper
code = Reports/Exclude/report8.jasper
code = Reports/Exclude/ReportSuperMan.jasper
code = Reports/Exclude/rptdentalgroupByAge.jasper
code = Reports/Exclude/rptdentalgroupbyAgeAndRight.jasper
code = Reports/Exclude/rptsumrightbymoney.jasper
code = Reports/Exclude/rpt_chronicPersonGetDrug.jasper
code = Reports/Exclude/rpt_fittest.jasper
code = Reports/Exclude/rpt_listVaccine.jasper
code = Reports/Exclude/rpt_MoneyInOutperRightGroup1.jasper
code = Reports/Exclude/rpt_serviceInOutperRightGroup.jasper
code = Reports/Exclude/rpt_serviceInOutperRightGroup1.jasper
code = Reports/Exclude/rpt_sumvisitGroupbyType.jasper
code = Reports/Exclude/rpt_sumvisitGroupbyType_xx.jasper
code = Reports/Exclude/RRP.jasper
code = Reports/Exclude/rsocialsecurity_subreport0.jasper
code = Reports/Exclude/ServiceByRightcode.jasper
code = Reports/Exclude/ssoRep.jasper
code = Reports/Exclude/testAABB.jasper
code = Reports/Exclude/testPassPara.jasper
code = Reports/Exclude/test_abc_test.jasper
code = Reports/Exclude/test_visit.jasper
code = Reports/Exclude/training-report1.jasper
code = Reports/Exclude/training-report2.jasper
code = Reports/Exclude/wOPD_dmht.jasper
code = Reports/Exclude/_01_personreport.jasper
code = Reports/Exclude/_aff.jasper
code = Reports/Exclude/_XXXXX_personreport.jasper
code = Reports/Exclude/__abcXXX.jasper
code = Reports/Exclude/__abc_123ww.jasper
code = Reports/Exclude/__report1.jasper
code = Reports/Exclude/__report4.jasper
code = Reports/Exclude/10_rpt_HT_Service.jrxml
code = Reports/Exclude/11_rpt_HT_Presure.jrxml
code = Reports/Exclude/12_rpt_DMHT_CH09.jrxml
code = Reports/Exclude/12_rpt_DMHT_egfr.jrxml
code = Reports/Exclude/13_rpt_DMHT_MS0102_MS0202_MSUPCR.jrxml
code = Reports/Exclude/14_rpt_DMHT_CVDRisk1.jrxml
code = Reports/Exclude/14_rpt_DMHT_CVDRisk2.jrxml
code = Reports/Exclude/15_rpt_HT_LipidProfile.jrxml
code = Reports/Exclude/15_rpt_HT_Lipid_profile.jrxml
code = Reports/Exclude/16_rpt_HT_LDL_lessthan100.jrxml
code = Reports/Exclude/1_rpt_DMHT_Service.jrxml
code = Reports/Exclude/2_rpt_DM_FBS_DTX.jrxml
code = Reports/Exclude/3_rpt_DM_HbA1c.jrxml
code = Reports/Exclude/3_rpt_DM_HbA1c_test.jrxml
code = Reports/Exclude/4_1_rpt_DM_ch07.jrxml
code = Reports/Exclude/4_2_rpt_DM_ch25.jrxml
code = Reports/Exclude/4_3_rpt_DM_ch14.jrxml
code = Reports/Exclude/4_4_rpt_DM_ch17.jrxml
code = Reports/Exclude/5_rpt_DM_ch17_less100.jrxml
code = Reports/Exclude/6_1_rpt_DM_footExam.jrxml
code = Reports/Exclude/6_2_rpt_DM_EyeExam.jrxml
code = Reports/Exclude/7_rpt_DM_Presure.jrxml
code = Reports/Exclude/8_rpt_DM_Fatty.jrxml
code = Reports/Exclude/9_rpt_DM_icd_R730.jrxml
code = Reports/Exclude/adl0to11.jrxml
code = Reports/Exclude/drug_label1.jrxml
code = Reports/Exclude/HPV.jrxml
code = Reports/Exclude/OPD_dmht_group_Concat.jrxml
code = Reports/Exclude/Pathumthani_rpt_sumvisitgroupbyrightgroup.jrxml
code = Reports/Exclude/Pathumthani_rpt_sumvisitGroupbyType.jrxml
code = Reports/Exclude/pyramid_population_17.jrxml
code = Reports/Exclude/refer_card.jrxml
code = Reports/Exclude/report1.jrxml
code = Reports/Exclude/rptdentalgroupByAge.jrxml
code = Reports/Exclude/rptdentalgroupbyAgeAndRight.jrxml
code = Reports/Exclude/rpt_chronicPersonGetDrug.jrxml
code = Reports/Exclude/rpt_listVaccine.jrxml
code = Reports/Exclude/rpt_sumvisitgroupbyrightgroup-backup.jrxml
code = Reports/Exclude/rpt_sumvisitGroupbyType.jrxml
code = Reports/Exclude/rpt_sumvisitGroupbyType_xx.jrxml
code = Reports/Exclude/ServiceByRightcode.jrxml
code = Reports/Exclude/testAABB.jrxml
code = Reports/Exclude/test_visit.jrxml
code = Reports/rdrugrepositoty.jasper
code = Reports/rdrugrepositoty.jrxml
code = Reports/rdrugstore_allSQL56.jasper
code = Reports/rdrugstore_allSQL56.jrxml
code = Reports/rperson_list.jasper
code = Reports/rperson_list.jrxml


class = pcu.SysStart.LoginForm

java_version = 1080000
'@
#endregion

#region Base paths
$Script:BaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path ([Environment]::GetCommandLineArgs()[0]) }
#endregion

#region Log
function Write-Log {
    param([Parameter(Mandatory)][ValidateSet('ok','err','warn','info')][string]$Level, [Parameter(Mandatory)][string]$Message)
    $sym = @{ ok = [string][char]0x2713; err = [string][char]0x2717; warn = '!'; info = [string][char]0x2192 }[$Level]
    $line = "{0:HH:mm:ss} {1} {2}" -f (Get-Date), $sym, $Message
    if ($SelfTest) { Write-Host $line }
    try { Add-Content -Path $Script:LogFile -Value $line -Encoding UTF8 } catch { }
    if ($null -ne $Script:LogBox -and -not $Script:LogBox.IsDisposed) {
        try {
            $Script:LogBox.SelectionStart = $Script:LogBox.TextLength
            $Script:LogBox.SelectionColor = [Drawing.Color]::FromName(@{ ok = 'Green'; err = 'Red'; warn = 'DarkOrange'; info = 'Black' }[$Level])
            $Script:LogBox.AppendText($line + "`r`n")
            $Script:LogBox.ScrollToCaret()
        } catch { }
    }
}
#endregion

#region Pure
function Get-AppKind([string]$DisplayName) {
    if ($DisplayName -imatch '^JHCIS-Client') { return 'client' }
    if ($DisplayName -imatch '^JHCIS-Server') { return 'server' }
    if ($DisplayName -imatch '^Java(\(TM\))? (\d|SE)') { return 'java' }
    return $null
}
function Get-SilentUninstallCommand([string]$UninstallString) {
    if ($UninstallString -imatch 'msiexec.*?(\{[0-9A-F-]+\})') {
        return [pscustomobject]@{ FilePath = 'msiexec.exe'; Arguments = "/x $($Matches[1]) /qb /norestart" }
    }
    $exe = $UninstallString.Replace('"', '').Trim()
    if ($exe -imatch '\.exe$') {
        return [pscustomobject]@{ FilePath = $exe; Arguments = '/S _?=' + (Split-Path $exe) }
    }
    return $null
}
function Get-MysqlVersionFromHandshake([byte[]]$Bytes) {
    if ($Bytes.Length -lt 6 -or $Bytes[4] -ne 0x0A) { return $null }
    $end = [Array]::IndexOf($Bytes, [byte]0, 5)
    if ($end -le 5) { return $null }
    return [Text.Encoding]::ASCII.GetString($Bytes, 5, $end - 5)
}
function Test-GetdownContent([string]$Text) {
    return ($Text -match 'appbase\s*=') -and ($Text -notmatch '<html')
}
function Test-FileSha256([string]$Path, [string]$Expected) {
    $fs = $null; $sha = $null
    try {
        $fs = [IO.File]::OpenRead($Path)
        $sha = [Security.Cryptography.SHA256]::Create()
        $buf = New-Object byte[] 4194304
        while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) {
            [void]$sha.TransformBlock($buf, 0, $n, $null, 0)
            [Windows.Forms.Application]::DoEvents()   # keep the window responsive while hashing 400+ MB
        }
        [void]$sha.TransformFinalBlock($buf, 0, 0)
        return ([BitConverter]::ToString($sha.Hash) -replace '-', '') -ieq $Expected
    } catch { return $false }
    finally { if ($null -ne $fs) { $fs.Dispose() }; if ($null -ne $sha) { $sha.Dispose() } }
}
function ConvertTo-Port([string]$Text) {
    $n = 0
    if ([int]::TryParse($Text, [ref]$n) -and $n -ge 1 -and $n -le 65535) { return $n }
    return $Script:DefaultPort
}
function Get-IpFromServerText([string]$Text) {
    return ($Text.Trim() -split '\s+')[0]
}
function Get-LanHosts([string]$Base, [string]$LocalIp) {
    return [string[]]@(1..254 | ForEach-Object { "$Base$_" } | Where-Object { $_ -ne $LocalIp })
}
#endregion

#region System
function Wait-UiUntil([scriptblock]$Condition, [int]$TimeoutMs = -1, [scriptblock]$OnTick = $null) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        [Windows.Forms.Application]::DoEvents()
        if ($OnTick) { & $OnTick }
        if (& $Condition) { return $true }
        if ($TimeoutMs -ge 0 -and $sw.ElapsedMilliseconds -ge $TimeoutMs) { return $false }
        Start-Sleep -Milliseconds 50
    }
}
function Invoke-Child([string]$FilePath, [string]$Arguments = '', [switch]$Hidden, [string]$WorkingDirectory = '') {
    $sp = @{ FilePath = $FilePath; PassThru = $true }
    if ($Arguments) { $sp.ArgumentList = $Arguments }
    if ($Hidden) { $sp.WindowStyle = 'Hidden' }
    if ($WorkingDirectory) { $sp.WorkingDirectory = $WorkingDirectory }
    try { $p = Start-Process @sp }
    catch { Write-Log err "รันไม่สำเร็จ: $FilePath - $($_.Exception.Message)"; return -1 }
    $null = $p.Handle   # cache handle so ExitCode stays readable for quick exits
    Wait-UiUntil { $p.HasExited } | Out-Null
    $p.WaitForExit()
    if ($null -eq $p.ExitCode) { return -1 }
    return [int]$p.ExitCode
}
function Get-WritableDir([string]$Preferred) {
    try {
        if (-not (Test-Path -LiteralPath $Preferred -PathType Container)) { return $env:TEMP }
        $t = Join-Path $Preferred ".write-test-$([guid]::NewGuid())"
        [IO.File]::WriteAllText($t, 'x'); Remove-Item -LiteralPath $t
        return $Preferred
    } catch { return $env:TEMP }
}
function Get-InstalledApps {
    $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $out = foreach ($r in @(Get-ItemProperty $keys -ErrorAction SilentlyContinue)) {
        $v = @{}
        foreach ($n in 'DisplayName', 'DisplayVersion', 'UninstallString') {
            $pr = $r.PSObject.Properties[$n]; $v[$n] = if ($pr -and $pr.Value) { [string]$pr.Value } else { '' }
        }
        if (-not $v.DisplayName -or -not $v.UninstallString) { continue }
        $k = Get-AppKind $v.DisplayName
        if ($null -eq $k) { continue }
        [pscustomobject]@{ Name = $v.DisplayName; Version = $v.DisplayVersion; Uninstall = $v.UninstallString; Kind = $k }
    }
    return @($out)
}
function Find-InstallPath {
    foreach ($c in $Script:InstallPathCandidates) { if (Test-Path -LiteralPath $c) { return $c } }
    return $null
}
function Get-SubnetBases {
    $seen = @{}
    $out = foreach ($a in @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue)) {
        $ip = [string]$a.IPAddress
        if ($a.PrefixOrigin -eq 'WellKnown' -or $ip.StartsWith('127.') -or $ip.StartsWith('169.254.')) { continue }
        $base = ($ip -replace '\d+$', '')
        if ($seen.ContainsKey($base)) { continue }
        $seen[$base] = $true
        [pscustomobject]@{ Base = $base; LocalIp = $ip; Interface = $a.InterfaceAlias }
    }
    return @($out)
}
function Start-MysqlHandshakeRead([Net.Sockets.TcpClient]$Client) {
    try {
        $stream = $Client.GetStream()
        $buf = New-Object byte[] 256
        return [pscustomobject]@{ Buffer = $buf; Task = $stream.ReadAsync($buf, 0, 256) }
    } catch { return $null }
}
function Complete-MysqlHandshakeRead($Read) {
    if (-not $Read) { return $null }
    $t = $Read.Task
    if (-not $t.IsCompleted -or $t.IsFaulted -or $t.IsCanceled) { return $null }
    $n = $t.Result
    if ($n -le 0) { return $null }
    return Get-MysqlVersionFromHandshake ([byte[]]$Read.Buffer[0..($n - 1)])
}
function Read-MysqlHandshake([Net.Sockets.TcpClient]$Client) {
    $r = Start-MysqlHandshakeRead $Client
    if (-not $r) { return $null }
    Wait-UiUntil { $r.Task.IsCompleted } 1500 | Out-Null
    return Complete-MysqlHandshakeRead $r
}
function Find-MysqlServers([int]$Port, [scriptblock]$OnProgress = $null, [string[]]$Hosts = $null) {
    $results = New-Object Collections.ArrayList
    if ($Hosts) { $subs = @([pscustomobject]@{ Base = 'custom'; LocalIp = ''; Interface = 'custom'; Hosts = $Hosts }) }
    else {
        $subs = @(Get-SubnetBases)
        if ($subs.Count -eq 0) { Write-Log warn 'ไม่พบ network interface แบบ IPv4' }
    }
    foreach ($sub in $subs) {
        Write-Log info "สแกน subnet $($sub.Base)0/24 ผ่าน $($sub.Interface)"
        $list = if ($sub.Base -eq 'custom') { $sub.Hosts } else { Get-LanHosts $sub.Base $sub.LocalIp }
        $pairs = New-Object Collections.ArrayList
        foreach ($h in $list) {
            $c = New-Object Net.Sockets.TcpClient
            [void]$pairs.Add([pscustomobject]@{ Host = $h; Client = $c; Task = $c.ConnectAsync($h, $Port); Read = $null })
        }
        $total = $pairs.Count
        $tick = { if ($OnProgress) { & $OnProgress @($pairs | Where-Object { $_.Task.IsCompleted }).Count $total $results.Count } }
        Wait-UiUntil { @($pairs | Where-Object { -not $_.Task.IsCompleted }).Count -eq 0 } 800 -OnTick $tick | Out-Null
        foreach ($p in $pairs) {
            $t = $p.Task
            if ($t.IsCompleted -and -not $t.IsFaulted -and -not $t.IsCanceled -and $p.Client.Connected) {
                $p.Read = Start-MysqlHandshakeRead $p.Client
            }
        }
        Wait-UiUntil { @($pairs | Where-Object { $_.Read -and -not $_.Read.Task.IsCompleted }).Count -eq 0 } 1500 -OnTick $tick | Out-Null
        foreach ($p in $pairs) {
            $v = Complete-MysqlHandshakeRead $p.Read
            if ($v -and -not (@($results | Where-Object { $_.Host -eq $p.Host }).Count)) {
                [void]$results.Add([pscustomobject]@{ Host = $p.Host; Port = $Port; Version = $v })
                Write-Log ok "พบ MySQL ที่ $($p.Host):$Port ($v)"
            }
        }
        foreach ($p in $pairs) { try { $p.Client.Dispose() } catch { } }
        Write-Log info "สแกน $($sub.Base)0/24 เสร็จ พบ $($results.Count) เครื่อง"
    }
    return @($results)
}
function Resolve-PayloadFile([string]$Name, [string]$Sha256, [long]$Size, [string]$Url, [string[]]$SearchDirs, [string]$DownloadDir, [scriptblock]$OnProgress = $null, [scriptblock]$ConfirmUseMismatch = $null, [int]$StallTimeoutMs = 60000) {
    if (-not $ConfirmUseMismatch) {
        $ConfirmUseMismatch = {
            param($path)
            $t = "ไฟล์ {0} มีอยู่แล้วแต่ไม่ตรงกับที่โปรแกรมรู้จัก`n`nใช้ไฟล์นี้ต่อหรือไม่?`nใช่ = ใช้ไฟล์นี้ (ไม่แนะนำ)   ไม่ใช่ = ดาวน์โหลดใหม่" -f $path
            if ($null -ne $Script:Form -and -not $Script:Form.IsDisposed) { $r = [Windows.Forms.MessageBox]::Show($Script:Form, $t, 'JHCIS Installer', 'YesNo', 'Warning', 'Button2') }
            else { $r = [Windows.Forms.MessageBox]::Show($t, 'JHCIS Installer', 'YesNo', 'Warning', 'Button2') }
            $r -eq 'Yes'
        }
    }
    $asked = $false
    foreach ($dir in $SearchDirs) {
        $path = Join-Path $dir $Name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        Write-Log info "กำลังตรวจสอบไฟล์ $Name ..."
        if (Test-FileSha256 $path $Sha256) { Write-Log ok "พบไฟล์ติดตั้ง: $path"; return $path }
        if (-not $asked) {
            $asked = $true
            Write-Log warn "ไฟล์ $path มีอยู่แล้วแต่ SHA256 ไม่ตรงกับที่โปรแกรมรู้จัก"
            if (& $ConfirmUseMismatch $path) { Write-Log warn "ใช้ไฟล์ที่ไม่ผ่านการตรวจสอบตามที่ผู้ใช้ยืนยัน: $path"; return $path }
        }
    }
    $part = Join-Path $DownloadDir "$Name.part"
    $final = Join-Path $DownloadDir $Name
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
        Write-Log info "กำลังดาวน์โหลด $Name ($([math]::Round($Size/1MB)) MB) ..."
        $wc = New-Object Net.WebClient
        $Script:ActiveWebClient = $wc
        $st = @{ Len = [long]-1; Sw = [Diagnostics.Stopwatch]::StartNew(); Stalled = $false }   # stall watchdog: .part size must keep growing
        try {
            $task = $wc.DownloadFileTaskAsync($Url, $part)
            Wait-UiUntil { $task.IsCompleted -or $st.Stalled } -OnTick {
                $len = 0; if (Test-Path -LiteralPath $part) { $len = (Get-Item -LiteralPath $part).Length }
                if ($len -ne $st.Len) { $st.Len = $len; $st.Sw.Restart() }
                elseif (-not $task.IsCompleted -and $st.Sw.ElapsedMilliseconds -ge $StallTimeoutMs) { $st.Stalled = $true; try { $wc.CancelAsync() } catch { } }
                if ($OnProgress) { & $OnProgress $len $Size }
            } | Out-Null
            if ($st.Stalled) {
                Wait-UiUntil { $task.IsCompleted } 5000 | Out-Null   # let WebClient close the .part stream
                Write-Log err "ดาวน์โหลด $Name หยุดนิ่งนานเกินไป - ยกเลิก"
                Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
                return $null
            }
            if ($task.IsFaulted -or $task.IsCanceled) {
                $msg = if ($task.Exception -and $task.Exception.InnerException) { $task.Exception.InnerException.Message } else { 'ยกเลิก' }
                Write-Log err "ดาวน์โหลดไม่สำเร็จ: $Name - $msg"
                Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
                return $null
            }
        } finally { $wc.Dispose(); $Script:ActiveWebClient = $null }
        Write-Log info "กำลังตรวจสอบไฟล์ $Name ..."
        if (Test-FileSha256 $part $Sha256) {
            Move-Item -LiteralPath $part -Destination $final -Force
            if ($OnProgress) { [void](& $OnProgress $Size $Size) }
            Write-Log ok "ดาวน์โหลด $Name เสร็จแล้ว"
            return $final
        }
        Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
        if ($attempt -lt 2) { Write-Log warn 'ไฟล์ที่โหลดมา SHA256 ไม่ตรง - ลองโหลดใหม่' }
    }
    Write-Log err 'ไฟล์ที่โหลดมาไม่ตรงกับที่โปรแกรมรู้จัก โปรแกรมเวอร์ชันนี้อาจเก่า กรุณาโหลดโปรแกรมเวอร์ชันใหม่'
    return $null
}
$Script:WorkDir = Get-WritableDir $Script:BaseDir
$Script:LogFile = Join-Path $Script:WorkDir 'jhcis-installer.log'

function Uninstall-App([pscustomobject]$App) {
    $cmd = Get-SilentUninstallCommand $App.Uninstall
    if ($null -eq $cmd) { Write-Log err "ไม่รู้วิธีถอน $($App.Name) - กรุณาถอนเองใน Control Panel"; return $false }
    Write-Log info "กำลังถอนการติดตั้ง $($App.Name) ..."
    $code = Invoke-Child $cmd.FilePath $cmd.Arguments   # not hidden: an NSIS prompt without /SD must stay clickable
    if ($code -eq 3010) { Write-Log ok "ถอน $($App.Name) แล้ว (ควร restart เครื่องภายหลัง)"; return $true }
    if ($code -in 0, 1605) { Write-Log ok "ถอน $($App.Name) แล้ว"; return $true }
    Write-Log err "ถอน $($App.Name) ไม่สำเร็จ (exit $code)"
    return $false
}

function Grant-FullPermissions([string]$Path) {
    $Path = $Path.Trim().TrimEnd('\', '/')
    $system = @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData, "$env:SystemDrive\Users", $env:USERPROFILE) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }
    if ($Path -match '^[A-Za-z]:$' -or $system -contains $Path) { Write-Log err "ปฏิเสธ: ไม่ตั้ง permission บนโฟลเดอร์ระบบ $Path"; return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Write-Log err "ไม่พบโฟลเดอร์: $Path"; return $false }
    Write-Log info "อัปเดต permission สำหรับ $Path"
    $icArgs = "`"$Path`" /T /C /Q /grant *S-1-5-32-545:(OI)(CI)F /grant *S-1-5-32-544:(OI)(CI)F"
    if ($env:USERNAME) { $icArgs += " /grant `"$env:USERNAME`":(OI)(CI)F" }
    $code = Invoke-Child 'icacls.exe' $icArgs -Hidden
    if ($code -eq 0) { Write-Log ok "อัปเดต permission สำเร็จ - Users / Administrators / $env:USERNAME ได้ Full Control"; return $true }
    Write-Log err "ไม่สามารถอัปเดต permission ได้ (exit code = $code)"
    return $false
}

function Get-GetdownText([string]$Url = $Script:GetdownUrl, [int]$TimeoutMs = 10000) {
    $wc = New-Object Net.WebClient
    try {
        $wc.Encoding = [Text.Encoding]::UTF8
        $task = $wc.DownloadStringTaskAsync($Url)
        if (-not (Wait-UiUntil { $task.IsCompleted } $TimeoutMs)) { try { $wc.CancelAsync() } catch { } }
        elseif (-not $task.IsFaulted -and -not $task.IsCanceled) {
            $text = $task.Result
            if (Test-GetdownContent $text) { Write-Log ok 'ดาวน์โหลด getdown.txt ล่าสุดจากเว็บกรมฯ แล้ว'; return $text }
            Write-Log warn 'ไฟล์ getdown.txt จากเว็บไม่ถูกต้อง - ใช้ไฟล์ที่แนบมากับโปรแกรมแทน'
            return $Script:GetdownFallback
        }
    } catch { }
    finally { $wc.Dispose() }
    Write-Log warn 'ดาวน์โหลด getdown.txt ไม่ได้ (ไม่มีอินเทอร์เน็ต?) - ใช้ไฟล์ที่แนบมากับโปรแกรมแทน'
    return $Script:GetdownFallback
}

function Set-GetdownFile([string]$InstallPath, [string]$Text) {
    if (-not (Test-Path -LiteralPath $InstallPath -PathType Container)) { Write-Log err "ไม่พบโฟลเดอร์: $InstallPath"; return $false }
    $target = Join-Path $InstallPath 'getdown.txt'
    try {
        if (Test-Path -LiteralPath $target) { Copy-Item -LiteralPath $target "$target.bak" -Force }
        [IO.File]::WriteAllText($target, $Text, (New-Object Text.UTF8Encoding $false))
        Write-Log ok "วาง getdown.txt ที่ $target แล้ว"
        return $true
    } catch {
        Write-Log err "เขียน getdown.txt ไม่สำเร็จ: $($_.Exception.Message)"
        return $false
    }
}

function Disable-JavaUpdate {
    $failed = 0
    foreach ($root in 'HKLM\SOFTWARE', 'HKLM\SOFTWARE\WOW6432Node') {
        $policy = "$root\JavaSoft\Java Update\Policy"
        foreach ($name in 'EnableJavaUpdate', 'EnableAutoUpdateCheck', 'NotifyDownload', 'NotifyInstall') {
            if ((Invoke-Child 'reg.exe' "add `"$policy`" /v $name /t REG_DWORD /d 0 /f" -Hidden) -ne 0) { $failed++ }
        }
        Invoke-Child 'reg.exe' "delete `"$root\Microsoft\Windows\CurrentVersion\Run`" /v SunJavaUpdateSched /f" -Hidden | Out-Null
    }
    if ($failed -ge 1) { Write-Log err "ปิด Java auto-update ไม่สำเร็จ $failed รายการ (ต้องใช้สิทธิ์ Administrator)"; return $false }
    Write-Log ok 'ปิด Java auto-update แล้ว (คง JRE 1.8 ไว้สำหรับ JHCIS)'
    return $true
}
#endregion

#region SelfTest
function Assert-Equal($Actual, $Expected, [string]$Name) {
    if ("$Actual" -ne "$Expected") { $Script:Failed++; Write-Host "FAIL $Name : got [$Actual] expected [$Expected]" }
    else { Write-Host "ok   $Name" }
}
function Assert-True($Condition, [string]$Name) { Assert-Equal ([bool]$Condition) $true $Name }
function Invoke-SelfTest {
    $Script:Failed = 0
    Assert-Equal $(Write-Log info 'selftest'; 1) 1 'Write-Log does not throw'
    Assert-True ($Script:Payload.Client.Sha256.Length -eq 64) 'config sha length'
    Assert-Equal (Get-AppKind 'Java 8 Update 191 (64-bit)') 'java' 'kind java'
    Assert-Equal (Get-AppKind 'Java SE Development Kit 8 Update 191 (64-bit)') 'java' 'kind jdk'
    Assert-Equal (Get-AppKind 'Java(TM) 8 Update 191') 'java' 'kind java(tm)'
    Assert-Equal (Get-AppKind 'Java Auto Updater') $null 'kind auto updater excluded'
    Assert-Equal (Get-AppKind 'JHCIS-Client-JRE-8.0.191_64bit 3.0.0') 'client' 'kind client'
    Assert-Equal (Get-AppKind 'JHCIS-Server-JRE-8.0.191_64bit 3.0.0') 'server' 'kind server'
    Assert-Equal (Get-AppKind 'MySQL Server 5.6') $null 'kind other'
    Assert-Equal (Get-AppKind 'Java SE Runtime Environment 8') 'java' 'kind java se runtime'
    Assert-Equal (Get-AppKind 'My JHCIS Client Tools') $null 'kind unanchored name excluded'

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
    $big = Join-Path $env:TEMP ("sha-big-{0}.bin" -f [guid]::NewGuid())
    $bb = New-Object byte[] 9437185; (New-Object Random).NextBytes($bb); [IO.File]::WriteAllBytes($big, $bb)
    Assert-True (Test-FileSha256 $big (Get-FileHash $big -Algorithm SHA256).Hash) 'sha multi-chunk (9 MB)'
    Remove-Item $big

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

    Assert-Equal (Invoke-Child 'cmd.exe' '/c exit 3' -Hidden) 3 'child exit code'
    Assert-Equal (Invoke-Child 'cmd.exe' '/c exit 7' -Hidden) 7 'child exit code quick exit'
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
    $listener2 = New-Object Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, 0); $listener2.Start()
    $lport2 = $listener2.LocalEndpoint.Port
    $accept2 = $listener2.AcceptTcpClientAsync()
    $Script:FakeWrote = $false; $Script:ProgressDone = -1; $Script:ProgressTotal = -1
    $hs2 = [byte[]](0x4A,0,0,0,0x0A) + [Text.Encoding]::ASCII.GetBytes('5.6.45-scan') + [byte[]](0,1,2,3)
    $found = @(Find-MysqlServers -Port $lport2 -Hosts @('127.0.0.1','127.0.0.1') -OnProgress {
        param($done,$total,$cnt)
        $Script:ProgressDone = $done; $Script:ProgressTotal = $total
        if ($accept2.IsCompleted -and -not $Script:FakeWrote) { $Script:FakeWrote = $true; $accept2.Result.GetStream().Write($hs2, 0, $hs2.Length) }
    })
    Assert-Equal $found.Count 1 'scan finds fake server once (dedupe)'
    Assert-Equal $found[0].Host '127.0.0.1' 'scan host'
    Assert-Equal $found[0].Port $lport2 'scan port'
    Assert-Equal $found[0].Version '5.6.45-scan' 'scan version'
    Assert-True ($Script:ProgressDone -ge 0 -and $Script:ProgressTotal -eq 2) 'scan progress callback called with total'
    try { $accept2.Result.Dispose() } catch {}; $listener2.Stop()
    if ($env:JHCIS_SCAN) { $sw=[Diagnostics.Stopwatch]::StartNew(); $r=@(Find-MysqlServers 3306); Write-Host "scan: $($r.Count) found in $($sw.ElapsedMilliseconds) ms: $($r | % { "$($_.Host) $($_.Version)" })" }
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
    $noisy = Resolve-PayloadFile -Name 'p.bin' -Sha256 $sha -Size $bytes.Length -Url $url -SearchDirs @() -DownloadDir $d1 -OnProgress { param($a,$b) 'noise' }
    Assert-True ($noisy -is [string]) 'payload return is a plain string even when callback emits output'
    Assert-Equal $noisy (Join-Path $d1 'p.bin') 'payload noisy callback path'
    Assert-Equal (Resolve-PayloadFile -Name 'p.bin' -Sha256 $sha -Size $bytes.Length -Url 'file:///Z:/missing.bin' -SearchDirs @($d1) -DownloadDir $d1) $got 'payload found locally, no download'
    $d2 = Join-Path $env:TEMP ("payload-d2-{0}" -f [guid]::NewGuid()); New-Item -ItemType Directory $d2 | Out-Null
    Assert-Equal (Resolve-PayloadFile -Name 'p.bin' -Sha256 ('0'*64) -Size $bytes.Length -Url $url -SearchDirs @($d2) -DownloadDir $d2) $null 'payload bad sha -> null'
    Assert-True (-not (Test-Path (Join-Path $d2 'p.bin')) -and -not (Test-Path (Join-Path $d2 'p.bin.part'))) 'payload bad sha leaves nothing'
    Assert-Equal (Resolve-PayloadFile -Name 'p.bin' -Sha256 ('0'*64) -Size 1 -Url $url -SearchDirs @($d1) -DownloadDir $d1 -ConfirmUseMismatch { $true }) $got 'payload local mismatch, user accepts'
    Assert-Equal (Resolve-PayloadFile -Name 'p.bin' -Sha256 $sha -Size 1 -Url 'file:///Z:/missing.bin' -SearchDirs @($d2) -DownloadDir $d2) $null 'payload download failure -> null'
    Remove-Item $src, $d1, $d2 -Recurse -Force
    $gd = Join-Path $env:TEMP ("getdown-{0}" -f [guid]::NewGuid()); New-Item -ItemType Directory $gd | Out-Null
    Assert-True (Set-GetdownFile $gd 'appbase = one') 'getdown write first'
    Assert-True (Set-GetdownFile $gd 'appbase = two') 'getdown write second'
    Assert-Equal (Get-Content (Join-Path $gd 'getdown.txt') -Raw) 'appbase = two' 'getdown current content'
    Assert-Equal (Get-Content (Join-Path $gd 'getdown.txt.bak') -Raw) 'appbase = one' 'getdown backup content'
    Assert-Equal ((Get-Content (Join-Path $gd 'getdown.txt') -Encoding Byte -TotalCount 3) -join ',') '97,112,112' 'getdown no BOM'
    Assert-True (-not (Set-GetdownFile (Join-Path $gd 'missing') 'x')) 'getdown missing dir -> false'
    Assert-Equal (Get-GetdownText 'http://127.0.0.1:9/getdown.txt' 1000) $Script:GetdownFallback 'getdown unreachable -> fallback'
    $gt = Join-Path $gd 'web.txt'; $gurl = ([Uri]$gt).AbsoluteUri; $gtext = "appbase = https://example/`n# ทดสอบ`n"
    [IO.File]::WriteAllText($gt, $gtext, (New-Object Text.UTF8Encoding $false))
    Assert-True ([string]::Equals((Get-GetdownText $gurl 3000), $gtext, [StringComparison]::Ordinal)) 'getdown web text decoded as UTF-8'
    [IO.File]::WriteAllText($gt, '<html><body>404</body></html>')
    Assert-Equal (Get-GetdownText $gurl 3000) $Script:GetdownFallback 'getdown html 200 -> fallback'
    Assert-True (Grant-FullPermissions $gd) 'icacls on temp dir'
    Assert-True (Grant-FullPermissions "$gd\") 'icacls trailing backslash'
    Assert-True (-not (Grant-FullPermissions (Join-Path $gd 'missing'))) 'icacls missing -> false'
    & { function Invoke-Child { 0 }   # stub: a broken guard must fail these asserts, not run icacls on the real C:\
        foreach ($bad in 'C:\', 'C:', $env:SystemRoot, $env:ProgramFiles, "$env:SystemDrive\Users") { Assert-True (-not (Grant-FullPermissions $bad)) "icacls refuses $bad" } }
    Assert-True (-not (Uninstall-App ([pscustomobject]@{Name='X';Version='';Uninstall='rundll32 foo';Kind='client'}))) 'uninstall unknown -> false'
    Remove-Item $gd -Recurse -Force
    if ($env:JHCIS_JAVA) { Assert-True (Disable-JavaUpdate) 'disable java update (admin)' }
    $sl = New-Object Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, 0); $sl.Start()   # accepts connections, never answers
    $surl = "http://127.0.0.1:$($sl.LocalEndpoint.Port)"
    $sw = [Diagnostics.Stopwatch]::StartNew(); $r = Get-GetdownText "$surl/g" 1500; $ms = $sw.ElapsedMilliseconds
    Assert-True ($r -eq $Script:GetdownFallback -and $ms -lt 4000) "getdown stalled server -> fallback ($ms ms)"
    $sd = Join-Path $env:TEMP ("payload-stall-{0}" -f [guid]::NewGuid()); New-Item -ItemType Directory $sd | Out-Null
    $sw.Restart(); $r = Resolve-PayloadFile -Name 'stall.bin' -Sha256 ('0'*64) -Size 10 -Url "$surl/s" -SearchDirs @() -DownloadDir $sd -StallTimeoutMs 1500; $ms = $sw.ElapsedMilliseconds
    Assert-True ($null -eq $r -and $ms -lt 4000 -and -not (Test-Path (Join-Path $sd 'stall.bin.part'))) "payload stall watchdog -> null, no .part ($ms ms)"
    $sl.Stop(); Remove-Item $sd -Recurse -Force
    Write-Host "$($Script:Failed) failed"
    exit ([int]($Script:Failed -ne 0))
}
if ($SelfTest) { Invoke-SelfTest }
#endregion

#region Elevation
$Script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $Script:IsAdmin -and $PSCommandPath -and -not $NoElevate) {
    try { Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -NoElevate" }
    catch { Write-Log err "ขอสิทธิ์ Administrator ไม่สำเร็จ: $($_.Exception.Message)" }
    exit
}
#endregion

#region UI
[Windows.Forms.Application]::EnableVisualStyles()
$Script:Running = $false
$Script:InstalledApps = @()
$Script:IsServerMachine = $false
$Script:UninstallList = @()
$Script:DlName = ''
$Script:LastPct = -1
$Script:StepFailures = 0
$Script:PrefillPath = $Script:DefaultInstallPath
$Script:Scanning = $false
$Script:StartQueued = $false

function New-Ctl([string]$Type, $Parent, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Text = '') {
    $c = New-Object "Windows.Forms.$Type"
    $c.Location = New-Object Drawing.Point($X, $Y)
    $c.Size = New-Object Drawing.Size($W, $H)
    $c.Text = $Text
    $Parent.Controls.Add($c)
    return $c
}
function Set-UiBusy([bool]$Busy) {
    foreach ($c in @($Script:CboServer, $Script:BtnScan, $Script:TxtPort, $Script:TxtInstallPath, $Script:ChkInstall, $Script:ChkPerm, $Script:ChkUpdate, $Script:ChkGetdown, $Script:ChkJava, $Script:BtnStart)) { $c.Enabled = -not $Busy }
    $Script:ChkUninstall.Enabled = (-not $Busy) -and $Script:UninstallList.Count -gt 0
    if ($Busy) { $Script:Progress.Style = 'Marquee' }
    else { $Script:Progress.Style = 'Continuous'; $Script:Progress.Value = 0 }
}
function Start-Scan {
    $Script:Scanning = $true
    Set-UiBusy $true
    $Script:BtnStart.Enabled = $true   # spec 5: กดเริ่มติดตั้งระหว่างสแกนได้ (เข้าคิว เริ่มเองเมื่อสแกนเสร็จ)
    try {
        $found = @(Find-MysqlServers (ConvertTo-Port $Script:TxtPort.Text) -OnProgress {
            param($done, $total, $cnt)
            if ($total -gt 0) {
                $Script:Progress.Style = 'Continuous'
                $Script:Progress.Maximum = $total
                $Script:Progress.Value = [Math]::Min($done, $total)
            }
        })
        $Script:CboServer.Items.Clear()
        foreach ($s in $found) { [void]$Script:CboServer.Items.Add("$($s.Host) ($($s.Version))") }
        if ($found.Count -gt 0) { $Script:CboServer.SelectedIndex = 0 }
        else { Write-Log warn 'ไม่พบ MySQL server ในวงแลน - พิมพ์ IP เครื่องแม่เองในช่อง IP' }
    } finally {
        Set-UiBusy $false
        $Script:Scanning = $false
        if ($Script:StartQueued) {
            $Script:StartQueued = $false
            if (-not $Script:Form.IsDisposed) { $Script:BtnStart.PerformClick() }   # window closed during the scan -> never start headless
        }
    }
}
$Script:OnDownload = {
    param($done, $total)
    $pct = 0
    if ($total -gt 0) { $pct = [int][Math]::Min(100, [Math]::Floor($done * 100 / $total)) }
    $Script:Progress.Style = 'Continuous'; $Script:Progress.Maximum = 100; $Script:Progress.Value = $pct
    $step = $pct - ($pct % 10)
    if ($step -ne $Script:LastPct) {
        $Script:LastPct = $step
        if ($step -gt 0) { Write-Log info "ดาวน์โหลด $($Script:DlName) ... $step%" }
    }
}
function Get-Payload($P, [string[]]$SearchDirs) {
    $Script:DlName = $P.Name; $Script:LastPct = -1
    return Resolve-PayloadFile -Name $P.Name -Sha256 $P.Sha256 -Size $P.Size -Url "$($Script:PayloadBase)/$($P.Name)" -SearchDirs $SearchDirs -DownloadDir $Script:WorkDir -OnProgress $Script:OnDownload
}
function Invoke-Step([string]$Title, [scriptblock]$Body) {
    $Script:Progress.Style = 'Marquee'
    try { $r = @(& $Body) } catch { Write-Log err "$Title ไม่สำเร็จ: $($_.Exception.Message)"; $Script:StepFailures++; return }
    if ($r -contains $false) { $Script:StepFailures++ }
}
function Update-UninstallList {
    $Script:InstalledApps = @(Get-InstalledApps)
    $Script:IsServerMachine = @($Script:InstalledApps | Where-Object { $_.Kind -eq 'server' }).Count -gt 0
    foreach ($a in $Script:InstalledApps) { Write-Log info "พบโปรแกรมที่ติดตั้งอยู่: $($a.Name)" }
    if ($Script:InstalledApps.Count -eq 0) { Write-Log info 'ไม่พบ JHCIS / Java ที่ติดตั้งอยู่' }
    $Script:UninstallList = @($Script:InstalledApps | Where-Object { $_.Kind -eq 'client' }) + @($Script:InstalledApps | Where-Object { $_.Kind -eq 'java' -and -not $Script:IsServerMachine })
    if ($Script:UninstallList.Count -gt 0) { $Script:ChkUninstall.Text = "ถอน JHCIS Client / Java ตัวเดิม  (พบ $($Script:UninstallList.Count) รายการ)" }
    else { $Script:ChkUninstall.Text = 'ถอน JHCIS Client / Java ตัวเดิม  (ไม่พบของเดิม)'; $Script:ChkUninstall.Checked = $false; $Script:ChkUninstall.Enabled = $false }
}
function Invoke-InstallFlow {
    $Script:StepFailures = 0
    $Script:TxtInstallPath.Text = $Script:TxtInstallPath.Text.Trim()
    if (-not $Script:TxtInstallPath.Text) { $Script:TxtInstallPath.Text = $Script:DefaultInstallPath }
    # spec 6: หาไฟล์ติดตั้ง Client ให้ได้ก่อนถอนของเดิม ไม่งั้นถ้าโหลดไม่ได้ เครื่องจะไม่เหลือทั้ง Client และ Java
    $clientFile = $null
    if ($Script:ChkInstall.Checked) {
        try { $clientFile = Get-Payload $Script:Payload.Client @(@($Script:BaseDir, (Join-Path $Script:BaseDir 'JHCIS-install-jre_jdk_64\jHCIS-All-PCU'), $Script:WorkDir) | Select-Object -Unique) }
        catch { Write-Log err "หาไฟล์ติดตั้ง JHCIS Client ไม่สำเร็จ: $($_.Exception.Message)" }
    }
    if ($Script:ChkUninstall.Checked) {
        if ($Script:ChkInstall.Checked -and -not $clientFile) { Write-Log err 'ไม่ถอนของเดิมเพราะยังไม่มีไฟล์ติดตั้ง JHCIS Client' }
        else { foreach ($a in $Script:UninstallList) { Invoke-Step "ถอน $($a.Name)" { Uninstall-App $a } } }
    }
    if ($Script:ChkInstall.Checked) {
        Invoke-Step 'ติดตั้ง JHCIS Client' {
            if (-not $clientFile) { return $false }
            $ip = Get-IpFromServerText $Script:CboServer.Text
            if (-not $ip) { Write-Log warn 'ไม่ได้ระบุ IP เครื่องแม่ - ต้องกรอกค่า ODBC เองตอน installer ถาม'; $ip = '(ไม่พบ - กรอกเอง)' }
            if ($Script:Form.WindowState -eq 'Minimized') { $Script:Form.WindowState = 'Normal' }
            $Script:Form.Activate()
            [void][Windows.Forms.MessageBox]::Show($Script:Form, "เมื่อ installer ถามค่า ODBC ให้กรอก:`nIP = $ip`nPort = $(ConvertTo-Port $Script:TxtPort.Text)`nuser = root`npassword = $($Script:DefaultPassword)`ndatabase = jhcisdb", 'JHCIS Installer', 'OK', 'Information')
            $Script:Progress.Style = 'Marquee'
            Write-Log info 'กำลังรันตัวติดตั้ง JHCIS Client ...'
            if ((Invoke-Child $clientFile -WorkingDirectory (Split-Path $clientFile)) -ne 0) {
                Write-Log warn 'ตัวติดตั้งจบโดยไม่สำเร็จ - ดำเนินการต่อ (อาจเป็นเพราะปิด installer ก่อนติดตั้งเสร็จ)'
                $false   # counts as a failed step; still re-detect the install folder below
            }
            else { Write-Log ok 'ตัวติดตั้ง JHCIS Client ทำงานเสร็จแล้ว' }
            $found = Find-InstallPath
            if ($found -and $Script:TxtInstallPath.Text.Trim() -eq $Script:PrefillPath) { $Script:TxtInstallPath.Text = $found; Write-Log info "ตรวจพบโฟลเดอร์ติดตั้งใหม่: $found" }
        }
    }
    if ($Script:ChkPerm.Checked) { Invoke-Step 'ตั้ง permission' { Grant-FullPermissions $Script:TxtInstallPath.Text } }
    if ($Script:ChkUpdate.Checked) {
        Invoke-Step 'อัปเดต JHCIS' {
            $file = Get-Payload $Script:Payload.Updater @(@($Script:BaseDir, $Script:WorkDir) | Select-Object -Unique)
            if (-not $file) { return $false }
            $Script:Progress.Style = 'Marquee'
            Write-Log info 'กำลังรัน JHCIS_Update.exe ...'
            $code = Invoke-Child $file -WorkingDirectory (Split-Path $file)
            if ($code -ne 0) { Write-Log warn "JHCIS_Update.exe จบโดยไม่สำเร็จ (exit $code) - ดำเนินการต่อ" }
            else { Write-Log ok 'อัปเดต JHCIS เสร็จแล้ว' }
        }
    }
    if ($Script:ChkGetdown.Checked) { Invoke-Step 'วาง getdown.txt' { Set-GetdownFile $Script:TxtInstallPath.Text (Get-GetdownText) } }
    if ($Script:ChkJava.Checked) { Invoke-Step 'ปิด Java auto-update' { Disable-JavaUpdate } }
    if ($Script:StepFailures -eq 0) {
        Write-Log ok 'การติดตั้งเสร็จสิ้น'
        [void][Windows.Forms.MessageBox]::Show($Script:Form, "การติดตั้งเสร็จสิ้น`nเปิดโปรแกรม JHCIS จาก shortcut บน Desktop ได้เลย", 'JHCIS Installer', 'OK', 'Information')
    } else {
        $msg = "เสร็จสิ้น แต่มี $($Script:StepFailures) ขั้นตอนล้มเหลว - ดูรายละเอียดใน log"
        Write-Log warn $msg
        [void][Windows.Forms.MessageBox]::Show($Script:Form, $msg, 'JHCIS Installer', 'OK', 'Warning')
    }
}

$Script:Form = New-Object Windows.Forms.Form
$Script:Form.Text = "ติดตั้ง JHCIS Client v$($Script:Version)"
$Script:Form.ClientSize = New-Object Drawing.Size(560, 680)
$Script:Form.FormBorderStyle = 'FixedSingle'
$Script:Form.MaximizeBox = $false
$Script:Form.StartPosition = 'CenterScreen'
$Script:Form.Font = New-Object Drawing.Font('Segoe UI', 10)

$grp = New-Ctl GroupBox $Script:Form 12 8 536 122 'เครื่องแม่ (MySQL Server)'
[void](New-Ctl Label $grp 12 30 44 24 'IP')
$Script:CboServer = New-Ctl ComboBox $grp 60 27 330 26
$Script:CboServer.DropDownStyle = 'DropDown'
$Script:BtnScan = New-Ctl Button $grp 400 25 122 30 'สแกนใหม่'
[void](New-Ctl Label $grp 12 68 44 24 'Port')
$Script:TxtPort = New-Ctl TextBox $grp 60 65 70 26 ([string]$Script:DefaultPort)
$Script:LblOdbc = New-Ctl Label $grp 140 62 382 52 "ค่าที่ต้องกรอกตอน installer ถาม ODBC: user=root  password=$($Script:DefaultPassword)  database=jhcisdb"

$grp = New-Ctl GroupBox $Script:Form 12 138 536 222 'ขั้นตอน'
$Script:ChkUninstall = New-Ctl CheckBox $grp 14 26 510 28 'ถอน JHCIS Client / Java ตัวเดิม'
$Script:ChkInstall = New-Ctl CheckBox $grp 14 58 510 28 'ติดตั้ง JHCIS Client'
$Script:ChkPerm = New-Ctl CheckBox $grp 14 90 216 28 'ตั้ง permission โฟลเดอร์'
$Script:TxtInstallPath = New-Ctl TextBox $grp 232 90 290 26
$Script:ChkUpdate = New-Ctl CheckBox $grp 14 122 510 28 'อัปเดต JHCIS เป็น version ใหม่ (JHCIS_Update.exe)'
$Script:ChkGetdown = New-Ctl CheckBox $grp 14 154 510 28 'วาง getdown.txt (แก้ปัญหาเปิด JHCIS ไม่ได้)'
$Script:ChkJava = New-Ctl CheckBox $grp 14 186 510 28 'ปิด Java auto-update (JHCIS ต้องใช้ JRE 1.8)'
foreach ($c in @($Script:ChkUninstall, $Script:ChkInstall, $Script:ChkPerm, $Script:ChkUpdate, $Script:ChkGetdown, $Script:ChkJava)) { $c.Checked = $true }
$found = Find-InstallPath
if ($found) { $Script:PrefillPath = $found }
$Script:TxtInstallPath.Text = $Script:PrefillPath

$Script:BtnStart = New-Ctl Button $Script:Form 12 370 406 40 '▶ เริ่มติดตั้ง'
$Script:BtnClose = New-Ctl Button $Script:Form 428 370 120 40 'ปิด'
$Script:Progress = New-Ctl ProgressBar $Script:Form 12 420 536 22
$Script:LogBox = New-Ctl RichTextBox $Script:Form 12 452 536 216
$Script:LogBox.ReadOnly = $true
$Script:LogBox.ScrollBars = 'Vertical'
$Script:LogBox.BackColor = [Drawing.Color]::White
$Script:LogBox.Font = New-Object Drawing.Font('Segoe UI', 9)

$Script:Form.Add_Shown({
    try {
        Write-Log info "=== เริ่มโปรแกรม v$($Script:Version) $(Get-Date -Format s) ==="
        if (-not $Script:IsAdmin) { Write-Log warn 'โปรแกรมไม่ได้รันด้วยสิทธิ์ Administrator - บางขั้นตอนอาจล้มเหลว' }
        Update-UninstallList
        if ($Script:IsServerMachine) {
            $msg = "เครื่องนี้มี JHCIS Server ติดตั้งอยู่ - โปรแกรมนี้ใช้กับเครื่องลูกเท่านั้น (จะไม่ถอน Java เพราะเครื่องแม่ต้องใช้)`n`nดำเนินการต่อจริงหรือไม่?"
            if ([Windows.Forms.MessageBox]::Show($Script:Form, $msg, 'JHCIS Installer', 'YesNo', 'Warning') -ne 'Yes') { $Script:Form.Close(); return }
        }
        Start-Scan
    } catch { Write-Log err "ผิดพลาด: $($_.Exception.Message)" }
})
$Script:BtnScan.Add_Click({ try { Start-Scan } catch { Write-Log err "สแกนไม่สำเร็จ: $($_.Exception.Message)" } })
$Script:BtnStart.Add_Click({
    try {
        if ($Script:Scanning) {
            $Script:StartQueued = $true
            $Script:BtnStart.Enabled = $false
            Write-Log info 'จะเริ่มติดตั้งทันทีที่สแกนเสร็จ'
            return
        }
        $Script:Running = $true; Set-UiBusy $true
        try { Invoke-InstallFlow }
        finally {
            try { Update-UninstallList } catch { Write-Log err "ตรวจโปรแกรมที่ติดตั้งอยู่ไม่สำเร็จ: $($_.Exception.Message)" }
            Set-UiBusy $false; $Script:Running = $false
        }
    } catch { Write-Log err "ผิดพลาด: $($_.Exception.Message)" }
})
$Script:BtnClose.Add_Click({ try { $Script:Form.Close() } catch { Write-Log err "ผิดพลาด: $($_.Exception.Message)" } })
$Script:Form.Add_FormClosing({
    param($s, $e)
    try {
        if (-not $Script:Running) { return }
        if ([Windows.Forms.MessageBox]::Show($Script:Form, 'กำลังติดตั้งอยู่ ปิดโปรแกรมจริงหรือไม่? (โปรแกรมติดตั้งที่เปิดอยู่จะทำงานต่อจนจบเอง)', 'JHCIS Installer', 'YesNo', 'Question') -ne 'Yes') { $e.Cancel = $true; return }
        if ($null -ne $Script:ActiveWebClient) {
            try { $Script:ActiveWebClient.CancelAsync() } catch { }
            Start-Sleep -Milliseconds 500   # let WebClient close the .part stream
        }
        foreach ($pl in $Script:Payload.Values) { Remove-Item -LiteralPath (Join-Path $Script:WorkDir "$($pl.Name).part") -Force -ErrorAction SilentlyContinue }
        Write-Log warn 'ผู้ใช้ปิดโปรแกรมกลางคัน'
        # flow ยังรันอยู่ใน DoEvents loop ซ้อน ถ้าแค่ปิดฟอร์ม flow จะทำขั้นถัดไปต่อโดยไม่มีหน้าต่าง; Exit ไม่ kill โปรแกรมลูก (Start-Process แยก process)
        [Environment]::Exit(0)
    } catch { Write-Log err "ผิดพลาด: $($_.Exception.Message)" }
})
[void][Windows.Forms.Application]::Run($Script:Form)
#endregion
