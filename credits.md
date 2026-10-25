# Credits

本项目的思路、脚本与文档，建立在以下开源项目与公开资料之上。按字母序。

---

## 直接使用的开源项目

### Aerial — 开源电视桌面
- 仓库：<https://github.com/pengchujin/aerial-tv>
- 本机版本：1.47（`aerial-guard` 变体）
- 用途：替换 PPOS 原桌面，Apple TV 风格、无广告无推荐位。
- 许可：见仓库 LICENSE（MIT）。
- 相关：
  - 安装说明（给 AI Agent 的版本）：<https://aerial.qust.me/agent.md>
  - AerialDream（配套航拍屏保）：同一作者

### cleanyourtv — 电视精简脚本集
- 仓库：<https://github.com/Gathin23/cleanyourtv>
- 用途：参考其"禁用清单 + 一键脚本"的组织方式与包分类思路（本项目 `scripts/debloat.ps1` 的 dry-run / 保护列表设计受其启发）。
- 参考文件：`disable.sh`、`restore.sh`、`debloat/cvte-*.txt`（CVTE/MStar 方案机型的禁用清单）。
- 许可：见仓库 LICENSE。

### 当贝市场 6.0.7
- 官网：<https://www.dangbei.com/>
- 用途：电视端应用安装来源（替代已停更的厂商商店）。免费软件，非开源。

### Android SDK Platform-Tools (adb)
- 下载：<https://developer.android.com/tools/releases/platform-tools>
- 许可：Apache License 2.0。仅作为外部工具使用，未分发其二进制。

---

## 作为方案参考（未直接使用）

| 项目 | 链接 | 参考点 | 结论 |
|---|---|---|---|
| 幕桥 mubridge | — | 免费无广告投屏，仅 DLNA/UPnP/HTTP | 要求 Android 6.0+，本机 API21 装不上 |
| AirScreen | `com.ionitech.airscreen` | 协议最全 | 免费版 1h 后每 5 分钟弹购买，属试用软件 |
| AirReceiver Lite | `com.softmedia.receiver.lite` | Android 5.0+ 可用 | 实测否决（广告/限制） |
| android-airplay-server | <https://github.com/jqssun/android-airplay-server> | 开源 AirPlay 接收端 | 偏服务端方案，未在本机验证 |
| Kodi / VLC | <https://kodi.tv> / <https://www.videolan.org> | 媒体中心 | 二者都不是 AirPlay/DLNA 接收端 |

---

## 文档与逆向工具

- **apk_label.py / apk_minsdk.py**（本仓库 `scripts/`）：纯 Python 解析 APK 的 binary AndroidManifest.xml（AXML）与 resources.arsc，
  无需 aapt/aapt2 即可取中文应用名与 minSdk。参考了 AOSP `ResourceTypes.h` 的 chunk 结构与公开的 AXML 格式说明。
- **Android 系统属性/分区/包管理行为**：AOSP 文档与 `dumpsys` 输出。
- **PPOS 广告链路**：通过 `strings /system/bin/advert` + `/init.rc` + `/data/data/com.pptv.launcher/*/strategy.json` 实测得出，非来自厂商文档。

---

## 免责与归属

- 本项目文档（`docs/`、`README.md`）采用 **CC BY 4.0**；`scripts/` 下代码采用 **MIT**，详见 [LICENSE](LICENSE)。
- 文中提及的商标（PPTV、PPOS、CVTE、MStar、当贝等）归各自所有者，本项目与其无关联。
- 所有操作在自有设备上完成，记录仅供参考；照做风险自负。
