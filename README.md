# TVslim — PPTV 55P Pro 去广告 / 换桌面 / 系统精简实录

一台 2015 年前后的国产智能电视（PPTV 55P Pro，PPOS 7.2.148PU / Android 5.0.1），
通过 **纯 adb + 免 root** 的方式完成：**干掉开机广告 → 换成开源 Aerial 桌面 → 精简系统后台 → 摸清投屏与文件管理**。

全流程可复现、可回滚，**未改动 /system 分区任何文件，未刷机，未动 /tvconfig 出厂配置**。

---

## 成果一览

| 项目 | 结果 |
|---|---|
| 开机广告 | ✅ 已彻底关闭（删素材 + 关开关，实测无广告） |
| 默认桌面 | ✅ 开源 [Aerial](https://github.com/pengchujin/aerial-tv) 1.47 接管（HOME 键 → Aerial） |
| 广告/推送/升级类系统应用 | ✅ 禁用 9 个（newtvad、tvbuy、push.service、snisupdate、snisservice、diagnostics、microhelper、terminalmanager、phasebeam） |
| 第三方杂物 | ✅ 卸载 dev-enabler；当贝市场升级到 6.0.7 |
| 存储 | ✅ /data 已用 **2.0G → 1.4G**，可用 2.6G（净释放约 600M） |
| 文件管理 / U 盘 | ✅ 系统无文件管理器，U 盘由定制 vold 挂到 `/mnt/usb/sda1`；实测可装 MT 管理器直接读写，日常仍推荐 `adb install` 或电视管家 U 盘安装 |
| 投屏 | ✅ 保留系统自带「投屏助手」（com.pptv.playhelper）；纯免费无广告全协议方案在 Android 5（API 21 / armv7）上**不存在**，用系统投屏助手或接受乐播的广告 |
| 不可逆操作 | ❌ 无。所有禁用项均可 `pm enable` 恢复 |

---

## 设备信息（本实录基线）

| 项 | 值 |
|---|---|
| 型号 | PPTV-55P+Pro（`PPTV_55PPRO`） |
| 系统 | PPOS 7.2.148PU / Android 5.0.1 (API 21) / `aosp_pitaya-userdebug 5.0.1 LRX22C 2.0.7 test-keys` |
| 平台 | CVTE MSD828（`T.MS828.U802B`），Cortex-A17 四核 + Mali-450 |
| 内存/存储 | 2GB RAM / 8GB ROM（/data 4.0G，/system 992M） |
| 连接 | `192.168.1.26:5555`，`ro.adb.secure=1`，`adb root` 可用（userdebug） |

> 同一套流程对其它 CVTE/MStar 方案（T.MS828 系列）、以及 PPOS 5.x/6.x/7.x 机型大概率通用，
> 但**包名和广告素材路径请先按 [docs/04](docs/04-系统精简.md) 的方法自己核对一遍再动手**。

---

## 五步上手

1. **环境准备** — `scripts/connect-tv.ps1`（Windows）连上电视，拿到 `adb root`。
   详见 [docs/01-环境与连接.md](docs/01-环境与连接.md)
2. **换桌面** — 装 Aerial guard 版 + 授予 3 个权限，HOME 键进 Aerial。
   详见 [docs/02-桌面替换-Aerial.md](docs/02-桌面替换-Aerial.md)
3. **去开机广告** — 删 4 个素材目录 + `persist.sys.advert_enable=0`。
   详见 [docs/03-去开机广告.md](docs/03-去开机广告.md)
4. **系统精简** — 按 [inventory/精简审核清单-v3-已执行.md](inventory/精简审核清单-v3-已执行.md) 逐项确认后执行 `scripts/debloat.ps1`。
   详见 [docs/04-系统精简.md](docs/04-系统精简.md)
5. **文件管理（可选）** — 系统没有文件管理器，U 盘入口挂在电视管家；确实需要第三方文件管理器时看
   [docs/05-文件管理与U盘安装.md](docs/05-文件管理与U盘安装.md)（含 `/mnt/usb` 挂载权限与 MT 管理器实测）。

---

## 目录结构

```
TVslim/
├─ README.md                 本文件
├─ CHANGELOG.md              变更记录
├─ credits.md                用到的开源项目、出处与许可
├─ LICENSE                   文档 CC BY 4.0 / 脚本 MIT
├─ .gitignore / .gitattributes
├─ docs/
│  ├─ 01-环境与连接.md        adb、root、无线调试、Windows 环境变量坑
│  ├─ 02-桌面替换-Aerial.md    Aerial 原理、两个变体、3 个权限、HOME.CC 陷阱
│  ├─ 03-去开机广告.md        广告链路逆向、素材目录、开关、备份教训
│  ├─ 04-系统精简.md          分区账、包分类、执行顺序、三不禁、验证命令
│  ├─ 05-文件管理与U盘安装.md  /mnt/usb 挂载权限、MT 管理器实测、adb 直装
│  ├─ 06-命令速查.md          复制粘贴用
│  ├─ 07-回滚与事故记录.md     三次翻车现场与恢复方法
│  └─ images/                 文档配图（仅此目录的 png 入库）
├─ inventory/
│  ├─ 精简审核清单-v3-已执行.md  已执行的完整勾选清单（第一手记录）
│  └─ packages.csv            包名 / 应用名 / 体积 / 位置 / 分类 / 建议
└─ scripts/
   ├─ connect-tv.ps1          连接 + 信息采集（IP 可参数化）
   ├─ debloat.ps1             批量禁用/恢复（带 -Restore）
   ├─ clean-space.ps1         清 dalvik / 孤儿目录 / 缓存
   ├─ apk_label.py            无 aapt 提取 APK 应用名（AXML+ARSC 纯 Python）
   └─ apk_minsdk.py           提取 minSdk / targetSdk / 包名
```

---

## 四条硬教训（先看，能省几小时）

1. **原桌面不能禁。** Aerial 的 Manifest 只声明 `android.intent.category.HOME.CC`，不声明标准 `HOME`，
   禁掉 `com.pptv.launcher` 会让 HOME 键彻底失效。Aerial 是"HOME 先落原桌面 → 无障碍守护拉前台"，
   每次按主页有 **4~6 秒** 原桌面闪现，这是方案固有代价。
2. **电视管家 / 搜索 不能禁。** U 盘安装入口挂在电视管家（`.myapp.MyAppActivity` 我的应用）上，
   PPOS 没有独立文件管理器。禁了就"您访问的内容找不到了"。
3. **禁用 /system 里的 App 不释放 /data 空间。** 省内存和后台是真，省空间是假；
   /data 的空间要靠清 dalvik-cache、孤儿目录、应用缓存。
4. **U 盘不在 `/storage` 下。** 定制 vold 把它挂在 `/mnt/usb/sda1`（属主 `media_rw` 1023 / `775`），
   靠 `StorageVolume` 枚举的那些"电视文件管理器"看不见它；要读得直接给完整路径。

---

## 免责声明

本仓库记录的是对**自有设备**的操作。刷机/改系统有变砖风险，禁用系统组件可能影响保修与后续 OTA。
按本文档操作前请自行确认机型与包名，**先备份、后动手、逐项验证**。
