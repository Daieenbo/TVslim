# connect-tv.ps1 —— 连接电视 + 基础信息采集
# 用法:
#   powershell -ExecutionPolicy Bypass -File connect-tv.ps1 -Ip 192.168.1.26
#   powershell -ExecutionPolicy Bypass -File connect-tv.ps1 -Ip 192.168.1.26 -Info
# 说明: 使用独立 HOME/ADB_VENDOR_KEYS/TMP，避免与本机其它 adb 工具互相覆盖密钥。
param(
  [Parameter(Mandatory=$true)][string]$Ip,
  [int]$Port = 5555,
  [int]$Tries = 20,
  [switch]$Info,
[string]$Adb = "adb",
  [string]$WorkDir = ""
)

function Resolve-Adb([string]$Given) {
  if ($Given -ne "adb" -and (Test-Path $Given)) { return $Given }
  $cmd = Get-Command $Given -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($c in @((Join-Path $PSScriptRoot "..\platform-tools\adb.exe"), (Join-Path (Get-Location).Path "platform-tools\adb.exe"))) {
    if (Test-Path $c) { return $c }
  }
  Write-Output "找不到 adb，请装 platform-tools 或加 -Adb <路径>（见 docs/01）"; exit 2
}

$ErrorActionPreference = "Continue"
$root = if ($WorkDir) { $WorkDir } else { (Get-Location).Path }
$ipPort = "$Ip`:$Port"

$Adb = Resolve-Adb $Adb

# 独立环境，避免覆盖默认 .android 里的密钥
$isoHome = Join-Path $root "androidhome"
$isoTmp  = Join-Path $root "tmp"
New-Item -ItemType Directory -Force -Path $isoHome, (Join-Path $isoHome ".android"), $isoTmp | Out-Null
$env:HOME              = $isoHome
$env:USERPROFILE       = $isoHome
$env:ANDROID_USER_HOME = (Join-Path $isoHome ".android")
$env:ADB_VENDOR_KEYS   = (Join-Path $isoHome ".android\adbkey")
$env:TMP = $env:TEMP = $env:TMPDIR = $isoTmp

$state = "unknown"
for ($i = 1; $i -le $Tries; $i++) {
  & $Adb connect $ipPort 2>&1 | Out-Null
  & $Adb -s $ipPort shell "echo AUTHOK" 2>&1 | Out-Null
  $d = (& $Adb devices 2>&1 | Out-String)
  if ($d -match [regex]::Escape($ipPort) + "\s+device")        { $state = "device"; break }
  if ($d -match [regex]::Escape($ipPort) + "\s+unauthorized")  { $state = "unauthorized" }
  if ($d -notmatch [regex]::Escape($ipPort))                   { $state = "offline" }
  if ($i % 5 -eq 0) { Write-Output "[$(Get-Date -Format 'HH:mm:ss')] $state (try#$i)" }
  Start-Sleep -Seconds 2
}

Write-Output "FINAL STATE: $state"
if ($state -ne "device") {
  Write-Output "排查: 电视端 ADB/远程协助是否打开？IP 是否变了？unauthorized 请在电视弹窗选『一律允许』"
  exit 1
}

# 尝试 root（userdebug 才有用）
& $Adb -s $ipPort root 2>&1 | Out-Null
Start-Sleep -Seconds 1
& $Adb -s $ipPort shell "echo ROOTOK" 2>&1 | Out-Null

if ($Info) {
  $sh = { param($c) Write-Output "----- $c -----"; & $Adb -s $ipPort shell $c 2>&1 | Out-String }
  & $sh "id"
  & $sh "getprop ro.product.model; getprop ro.product.brand; getprop ro.build.version.release; getprop ro.build.version.sdk; getprop ro.build.display.id; getprop ro.build.type; getprop ro.adb.secure"
  & $sh "df -h"
  & $sh "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME"
  & $sh "settings get secure enabled_accessibility_services"
  & $sh "settings get secure default_input_method"
  & $sh "pm list packages -3"
  & $sh "pm list packages -d"
  & $sh "dumpsys window | grep mCurrentFocus"
  & $sh "getprop persist.sys.advert_enable"
}
exit 0
