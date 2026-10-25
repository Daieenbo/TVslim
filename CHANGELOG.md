# Changelog

本项目记录一次性的设备改造过程，版本号对应文档/脚本的修正轮次。

## [1.0.0] - 2026-10-25

首次整理成仓库。汇总当天在 PPTV 55P Pro（PPOS 7.2.148PU / Android 5.0.1）上的全部操作。

### 完成
- **去开机广告**：确认广告由 `/system/bin/advert` 播放本地素材，删除
  `/data/data/com.pptv.launcher/` 下 `new_advert`、`new_advert_depressed`、`shutdown`、`shutdown_depressed`
  四个目录，并置 `persist.sys.advert_enable=0`；冷启动验收无广告。
- **桌面替换**：安装 Aerial 1.47（`app.orchard.tv`，guard 变体），授予 WRITE_SECURE_SETTINGS /
  通知使用权 / 无障碍 / 使用情况访问；HOME 键进入 Aerial。
- **系统精简**：禁用 9 个广告/推送/统计/升级类包（含 `com.pptv.terminalmanager` 远端静默安装通道），
  可选禁用 screenprotect / guide / tvplayer；卸载 `com.gelab.devenab`。
- **空间清理**：删乐播旧版孤儿目录 165M、原桌面 yfnet 缓存 254M、清 dalvik-cache 876M→661M；
  /data 已用 2.0G→1.4G。
- **易用性补丁**：U 盘安装入口恢复（重新启用电视管家 + 搜索），当贝市场从 4.1.2 升级到 6.0.7
  （`com.dangbeimarket`，adb 安装）。
- **投屏调研**：确认 Android 5（API 21 / armv7）上不存在"免费+无广告+全协议"的投屏方案，结论并入 README 成果表。

### 修正（当天回滚的事故，详见 docs/06）
- `com.pptv.launcher` 禁用后 HOME 键失效 → 撤销禁用。原因：Aerial 只声明 `HOME.CC` 不声明标准 `HOME`。
- `com.pptv.tvhousekeeper` / `com.pptv.search` 禁用导致 U 盘安装入口失效 → 撤销禁用。
- 开机广告素材备份命令被 PowerShell 变量展开破坏（复制了整个 launcher 目录到 /data）→ 清理并改用 `adb pull` 备份到电脑。

### 文档
- 新增 `docs/01`~`docs/06`、`inventory/packages.csv`、`inventory/精简审核清单-v3-已执行.md`。
- 脚本：`connect-tv.ps1`（IP 参数化）、`debloat.ps1`（dry-run + 保护列表 + -Restore）、
  `clean-space.ps1`、`apk_label.py`、`apk_minsdk.py`。

### 已知限制
- 每次按 HOME 有 4~6 秒原桌面闪现（Aerial 方案固有代价，未解决）。
- 投屏无"四全"方案。
- 只在 PPTV 55P Pro / PPOS 7.2.148PU 上完整验证，其它机型需自行核对包名。
