#requires -Version 5.1
param([switch]$SelfTest)
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
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
    try { return (Get-FileHash -Path $Path -Algorithm SHA256).Hash -ieq $Expected } catch { return $false }
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
function Resolve-PayloadFile([string]$Name, [string]$Sha256, [long]$Size, [string]$Url, [string[]]$SearchDirs, [string]$DownloadDir, [scriptblock]$OnProgress = $null, [scriptblock]$ConfirmUseMismatch = $null) {
    if (-not $ConfirmUseMismatch) {
        $ConfirmUseMismatch = { param($path) [Windows.Forms.MessageBox]::Show(("ไฟล์ {0} มีอยู่แล้วแต่ไม่ตรงกับที่โปรแกรมรู้จัก ใช้ไฟล์นี้ต่อหรือไม่? (No = ดาวน์โหลดใหม่)" -f $path), 'JHCIS Installer', 'YesNo', 'Warning') -eq 'Yes' }
    }
    $asked = $false
    foreach ($dir in $SearchDirs) {
        $path = Join-Path $dir $Name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        if (Test-FileSha256 $path $Sha256) { Write-Log ok "พบไฟล์ติดตั้ง: $path"; return $path }
        if (-not $asked) {
            $asked = $true
            if (& $ConfirmUseMismatch $path) { Write-Log ok "พบไฟล์ติดตั้ง: $path"; return $path }
        }
    }
    $part = Join-Path $DownloadDir "$Name.part"
    $final = Join-Path $DownloadDir $Name
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
        Write-Log info "กำลังดาวน์โหลด $Name ($([math]::Round($Size/1MB)) MB) ..."
        $wc = New-Object Net.WebClient
        try {
            $task = $wc.DownloadFileTaskAsync($Url, $part)
            Wait-UiUntil { $task.IsCompleted } -OnTick {
                if ($OnProgress) { $len = 0; if (Test-Path -LiteralPath $part) { $len = (Get-Item -LiteralPath $part).Length }; & $OnProgress $len $Size }
            } | Out-Null
            if ($task.IsFaulted -or $task.IsCanceled) {
                $msg = if ($task.Exception -and $task.Exception.InnerException) { $task.Exception.InnerException.Message } else { 'ยกเลิก' }
                Write-Log err "ดาวน์โหลดไม่สำเร็จ: $Name - $msg"
                Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
                return $null
            }
        } finally { $wc.Dispose() }
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
    Write-Host "$($Script:Failed) failed"
    exit ([int]($Script:Failed -ne 0))
}
if ($SelfTest) { Invoke-SelfTest }
#endregion

#region Elevation
#endregion

#region UI
#endregion
