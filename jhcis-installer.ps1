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
$Script:LogFile = Join-Path $Script:BaseDir 'jhcis-installer.log'
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
#endregion

#region System
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
    Write-Host "$($Script:Failed) failed"
    exit ([int]($Script:Failed -ne 0))
}
if ($SelfTest) { Invoke-SelfTest }
#endregion

#region Elevation
#endregion

#region UI
#endregion
