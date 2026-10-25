# clean-space.ps1 —— 清理 /data 空间（孤儿目录 / 缓存 / dalvik）
# 用法:
#   powershell -ExecutionPolicy Bypass -File clean-space.ps1 -Ip 192.168.1.26              # 预览
#   powershell -ExecutionPolicy Bypass -File clean-space.ps1 -Ip 192.168.1.26 -Apply       # 执行（不含 dalvik）
#   powershell -ExecutionPolicy Bypass -File clean-space.ps1 -Ip 192.168.1.26 -Apply -Dalvik # 含 dalvik（需重启）
#
# 注意: 禁用 /system 内的 App 不会释放 /data 空间，空间只能靠本脚本这类清理。
param(
  [Parameter(Mandatory=$true)][string]$Ip,
  [int]$Port = 5555,
  [switch]$Apply,
  [switch]$Dalvik,
[string]$Adb = "adb"
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
$ipPort = "$Ip`:$Port"
$Adb = Resolve-Adb $Adb

# 待清理项：路径 + 说明。删除前会先 ls 确认存在。
$Targets = @(
  @{ Path = "/data/app/com.hpplay.happyplay.aw-1"; Desc = "乐播投屏旧版孤儿目录（活动版为 -2）"; Size = "约165M" },
  @{ Path = "/data/media/0/Android/data/com.pptv.launcher/cache/yfnet"; Desc = "原桌面视频缓存"; Size = "约254M" }
)
# 可选，需 -Dalvik 显式开启
$DalvikPath = "/data/dalvik-cache"

& $Adb connect $ipPort 2>&1 | Out-Null
& $Adb -s $ipPort root 2>&1 | Out-Null
Start-Sleep -Seconds 1

Write-Output "----- 清理前 -----"
& $Adb -s $ipPort shell "df -h /data" 2>&1

foreach ($t in $Targets) {
  $ls = (& $Adb -s $ipPort shell "ls $($t.Path)" 2>&1 | Out-String).Trim()
  $present = $ls -and ($ls -notmatch "No such file")
  Write-Output "`n[$($t.Desc)] $($t.Path) ($($t.Size)) 存在=$present"
  if (-not $present) { continue }
  if (-not $Apply) { Write-Output "  [dry-run] 将 rm -rf $($t.Path)"; continue }
  # 删除前二次确认这是 /data 下、不是关键路径
  if ($t.Path -notmatch '^/data/') { Write-Output "  !! 非 /data 路径，跳过"; continue }
  & $Adb -s $ipPort shell "rm -rf '$($t.Path)'" 2>&1 | Out-Null
  $after = (& $Adb -s $ipPort shell "ls $($t.Path)" 2>&1 | Out-String).Trim()
  Write-Output "  删除后 ls: $(if($after){$after}else{'（已不存在）'})"
}

if ($Dalvik) {
  $sz = (& $Adb -s $ipPort shell "du -sh $DalvikPath" 2>&1 | Out-String).Trim()
  Write-Output "`n[dalvik-cache] 当前 $sz"
  if (-not $Apply) {
    Write-Output "  [dry-run] 将清空 $DalvikPath 并重启（重启后 ART 重建，首次开机慢几分钟）"
  } else {
    & $Adb -s $ipPort shell "rm -rf $DalvikPath/*" 2>&1 | Out-Null
    Write-Output "  已清空，重启中..."
    & $Adb -s $ipPort reboot 2>&1 | Out-Null
    Write-Output "  注意: 首次开机可能数分钟，勿断电"
  }
}

Write-Output "`n----- 清理后 -----"
if ($Apply -and $Dalvik) { Write-Output "（重启后再查 df）" } else { & $Adb -s $ipPort shell "df -h /data" 2>&1 }
Write-Output "参考: 本例 /data 已用 2.0G -> 1.4G"
