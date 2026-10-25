# debloat.ps1 —— PPTV 55P Pro 批量禁用 / 恢复
# 用法:
#   powershell -ExecutionPolicy Bypass -File debloat.ps1 -Ip 192.168.1.26            # 预览（不执行）
#   powershell -ExecutionPolicy Bypass -File debloat.ps1 -Ip 192.168.1.26 -Apply     # 执行禁用
#   powershell -ExecutionPolicy Bypass -File debloat.ps1 -Ip 192.168.1.26 -Apply -Restore  # 恢复
#   powershell -ExecutionPolicy Bypass -File debloat.ps1 -Ip 192.168.1.26 -Apply -Only com.pptv.newtvad
#
# 安全设计:
#   - 默认 dry-run，必须显式 -Apply
#   - 三个「不能禁」的包写死在 Protected 列表，永远跳过
#   - 逐个执行并回显结果，失败不中断
param(
  [Parameter(Mandatory=$true)][string]$Ip,
  [int]$Port = 5555,
  [switch]$Apply,
  [switch]$Restore,
  [string[]]$Only = @(),
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

# 广告 / 推送 / 统计 / 升级（表三，9 个）
$AdsPackages = @(
  "com.pptv.newtvad",         # 广告投放 SDK
  "com.pptv.tvbuy",           # 聚优购 电视购物
  "com.pptv.push.service",    # 推送通道
  "com.pptv.snisupdate",      # 静默升级
  "com.pptv.snisservice",     # 升级服务
  "com.pptv.diagnostics",     # 自动诊断上报
  "com.pptv.microhelper",     # 电视助手（推广位）
  "com.pptv.terminalmanager", # 终端管理（远端运维/静默安装）
  "com.android.phasebeam"     # 动态壁纸
)

# 可选：其它可禁用项（按需 -Only 指定，默认不包含）
$OptionalPackages = @(
  "com.pptv.screenprotect",   # 屏保（已换 AerialDream 才可禁）
  "com.pptv.guide",           # PPGuide 导视
  "com.pplive.tvplayer",      # PPTV 聚精彩
  "com.juli.dangbeimarket"    # 老版当贝 4.1.2（已有 6.0.7 时才可禁）
)

# 绝对不动：禁了会坏
$Protected = @(
  "com.pptv.launcher",        # HOME 键唯一响应者
  "com.pptv.tvhousekeeper",   # U 盘安装入口
  "com.pptv.search",          # 应用搜索
  "com.pptv.setting",         # 设置
  "com.pptv.framework.tvservice", # 寄宿 Aerial 守护无障碍服务
  "com.pptv.local.myapplication", # FallbackHome
  "com.pptv.lisenceauth",     # 授权校验（上游依赖）
  "com.sohu.inputmethod.sogou.tv",
  "android", "com.android.systemui", "com.android.packageinstaller",
  "com.android.webview", "com.android.bluetooth", "com.mstar.bluetooth3dservice"
)

$list = if ($Only.Count -gt 0) { $Only } elseif ($Restore) { $AdsPackages + $OptionalPackages } else { $AdsPackages }

& $Adb connect $ipPort 2>&1 | Out-Null
$fixed = $false
foreach ($p in $list) {
  if ($Protected -contains $p) { Write-Output "!! 跳过（保护列表）: $p"; continue }
  $exists = (& $Adb -s $ipPort shell "pm path $p" 2>&1 | Out-String)
  if ($exists -notmatch "package:") { Write-Output "-- 未安装，跳过: $p"; continue }

  if (-not $Apply) {
    Write-Output "[dry-run] 将 $(if($Restore){'恢复'}else{'禁用'}): $p"
    continue
  }
  if ($Restore) {
    $r = (& $Adb -s $ipPort shell "pm enable $p" 2>&1 | Out-String).Trim()
    Write-Output "恢复 $p -> $r"
  } else {
    $r = (& $Adb -s $ipPort shell "pm disable-user $p" 2>&1 | Out-String).Trim()
    Write-Output "禁用 $p -> $r"
  }
}

if ($Apply) {
  Write-Output "`n----- 当前已禁用 -----"
  & $Adb -s $ipPort shell "pm list packages -d" 2>&1
  Write-Output "----- 关键包状态 -----"
  foreach ($k in @("com.pptv.launcher","com.pptv.setting","com.pptv.tvhousekeeper","com.pptv.search")) {
    $s = (& $Adb -s $ipPort shell "dumpsys package $k | grep enabled" 2>&1 | Out-String).Trim()
    Write-Output "$k : $s"
  }
  Write-Output "`n建议: 逐项确认无副作用后再重启；恢复用 -Apply -Restore"
} else {
  Write-Output "`n[dry-run] 未做任何修改。确认无误后加 -Apply 执行。"
}
