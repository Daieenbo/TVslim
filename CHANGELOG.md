# Changelog

本项目记录一次性的设备改造过程，版本号对应文档/脚本的修正轮次。

## [1.1.0] - 2026-10-25

补一章「文件管理与 U 盘」：系统没有文件管理器，实测第三方文件管理器可直读 U 盘。

### 新增
- `docs/05-文件管理与U盘安装.md`：`/mnt/usb/sda1` 的挂载方式与 `media_rw`(1023) 权限说明、
  MT 管理器（`bin.mt.plus` 2.26.10，minSdk 21）实测记录、adb 直装与电视管家两条替代路线。
- `docs/images/mt-usb.png`：配图；`.gitignore` 增加 `!docs/images/*.png` 例外（其余 png 仍不入库）。

### 变更
- 文档编号重排：`05-命令速查` → `06`，`06-回滚与事故记录` → `07`，并同步修正 README、本文件、
  `02-桌面替换-Aerial.md` 中的交叉引用。
- README：成果表新增「文件管理 / U 盘」一行；五步上手补充第 5 步（可选）。

### 实测结论
- U 盘不在 `/storage` 下，而是挂在 `/mnt/usb/sda1`（vfat，uid/gid=`1023` media_rw，`775`）；
  持有存储权限的第三方 App 可直接读写，依赖 `StorageVolume` 枚举的 App 看不到它。
- MT 管理器可用：1080p 渲染正常、D-pad 能移动列表高亮、能进入 U 盘子目录；
  但它是手机版 UI，工具栏/按钮无焦点框，用户协议弹窗超出屏幕 → 必须配鼠标/飞鼠。
  另外内置友盟统计（`libumeng-spy.so`），并有账号 / VIP 体系。
- 禁用电视管家会让 U 盘入口变成「您访问的内容找不到了」，再次印证 04 文档的「三不禁」。

### 已知限制
- Android 5 上还没有"开源 + TV 原生 + 无广告"的文件管理器经过完整验证；本章只对 MT 管理器做了实测。

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

### 修正（当天回滚的事故，详见 docs/07）
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
