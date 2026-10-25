# 02 · 桌面替换：Aerial

目标：把开机后/按 HOME 键的桌面换成开源的「Aerial」（Apple TV 风格，纯净、无广告、无推荐位）。

- 项目：<https://github.com/pengchujin/aerial-tv>
- 本例版本：**1.47**，包名 `app.orchard.tv`
- 变体：`aerial-standard` 与 `aerial-guard`，**电视装 guard 版**（多一个"守护"服务，用于把桌面抢回前台）

## 1. 为什么选它

| 维度 | Aerial | 换第三方电视桌面（当贝/Emotn 等） |
|---|---|---|
| 广告/推荐位 | 无 | 通常有 |
| 体积 | ~2.8MB | 几十 MB |
| 依赖 | 无（纯本地渲染 + 可选壁纸） | 常带商店、推送 |
| Android 5 | 支持（标准 APK，未用新 API） | 多数已放弃 API21 |

## 2. 安装（三条命令）

```bash
adb connect 192.168.1.26:5555
adb install -r aerial-guard-1.47.apk
adb shell am start -n app.orchard.tv/.MainActivity
```

装完先在电视上手动打开一次 Aerial，让它完成初始化。

## 3. 授予 3 个权限（关键，缺一个守护就不工作）

### 3.1 写安全设置（命令行）

```bash
adb shell pm grant app.orchard.tv android.permission.WRITE_SECURE_SETTINGS
```

### 3.2 通知使用权（命令行，二选一）

```bash
adb shell cmd notification allow_listener app.orchard.tv/app.orchard.tv.guard.RevivalListener
```

> 老版本 Android 5 上 `cmd notification` 可能不存在，改用电视 UI：
> 设置 → 应用/通知 → 通知使用权 → 勾选 Aerial。

### 3.3 悬浮窗（命令行）

```bash
adb shell appops set app.orchard.tv SYSTEM_ALERT_WINDOW allow
```

### 3.4 电视 UI 里手动确认的三项

`guard` 变体的守护逻辑依赖这三项，命令行能开一部分，但**建议都在电视上核一遍**：

1. **辅助功能（无障碍）** → 开启 Aerial 的 `HomeGuardService`
2. **通知使用权** → Aerial 的 `RevivalListener`
3. **使用情况访问**（Usage Access）→ 允许 Aerial

开启后可用命令行验证：

```bash
adb shell settings get secure enabled_accessibility_services
# 期望输出里含 app.orchard.tv/app.orchard.tv.guard.HomeGuardService

adb shell dumpsys window | grep mCurrentFocus
# 按 HOME 键后，期望看到 app.orchard.tv/...
```

## 4. 屏保（可选，但推荐）

系统自带屏保换成 **AerialDream**（同一作者，Apple TV 航拍视频屏保），
原 `com.pptv.screenprotect` 就可以禁用了（见 04 文档 B3）。

## 5. ⚠️ HOME.CC 陷阱（本次翻车点，务必读）

Aerial 的 AndroidManifest 声明的是：

```
android.intent.category.HOME.CC      ← 国内定制 HOME 类别
android.intent.category.LEANBACK_LAUNCHER
android.intent.category.LAUNCHER
```

**它没有声明标准的 `android.intent.category.HOME`。**
所以系统里唯一能响应 HOME 键的仍然是原桌面 `com.pptv.launcher`。

后果：
- 如果按"常规思路"禁用原桌面 → **HOME 键彻底失效**（实测：从银河奇异果按主页无任何反应，Aerial 守护也失去触发源）。
- 正确姿势：**原桌面保持启用**。按 HOME 键 → 原桌面先起来（约 4~6 秒）→ 无障碍守护检测到并立刻把 Aerial 拉到前台。

这是该方案在 PPOS 上的固有代价，不是操作失误。若不能接受这几秒闪现，替代思路见 07 文档末尾。

## 6. 验证清单

```bash
adb shell pm list packages | grep app.orchard.tv          # 已安装
adb shell settings get secure enabled_accessibility_services
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
adb shell dumpsys window | grep mCurrentFocus              # 按 HOME 后应为 app.orchard.tv
```

## 7. 回滚

```bash
# 卸载 Aerial
adb uninstall app.orchard.tv
# 若已禁用原桌面（不该做），恢复它
adb shell pm enable com.pptv.launcher
adb reboot
```
