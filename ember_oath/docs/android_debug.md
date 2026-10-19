# 《炎烬之誓》Android 横屏 debug 包

试包范围 C：横屏 debug APK，能装能开。不签名上架，不要求 AAB。

| 项 | 值 |
|---|---|
| 引擎 | Godot 4.7.2 |
| 预设 | `export_presets.cfg` → `Android` |
| 包名 | `com.emberoath.vow` |
| 版本 | `0.1.0`（version code 1） |
| 方向 | `sensor_landscape`（强制横屏，允许左右翻转） |
| 逻辑分辨率 | 1280×720，`canvas_items` + `expand` |
| ABI | `arm64-v8a`（真机）+ `x86_64`（模拟器） |
| 渲染 | `gl_compatibility`（桌面与 Android 相同） |
| 签名 | debug。keystore 留空时用编辑器调试密钥，不能上架 |

APK 不进 git（`.gitignore` 已忽略 `*.apk` 与 `**/builds/`）。

## 安装

```bash
adb install -r ember_oath_debug.apk
adb shell am start -n com.emberoath.vow/com.godot.game.GodotAppLauncher
```

`GodotApp` 本身未导出，入口是启动器别名 `GodotAppLauncher`。

已装过旧包时用 `-r` 覆盖。卸载：

```bash
adb uninstall com.emberoath.vow
```

## 自己导出

需要：

- Godot **4.7.2** 编辑器
- 对应导出模板，放到 `export_templates/4.7.2.stable/`（内含 `android_debug.apk`）
- JDK 17 或 21（`keytool`、`apksigner`）
- Android SDK：`platform-tools` 与 `build-tools`（目标 SDK 36，build-tools 用 35 或 36 均可）

编辑器 **Editor Settings → Export → Android** 填写：

- Android SDK Path
- Java SDK Path
- Debug Keystore（可留空，导出时自动生成；用户 `androiddebugkey`，密码 `android`）

命令行（在仓库根目录）：

```bash
godot --headless --path ember_oath --import
godot --headless --path ember_oath --export-debug "Android" builds/ember_oath_debug.apk
```

预设关闭 Gradle，直接打进官方 `android_debug.apk` 模板。AAB 需要另开 `gradle_build/use_gradle_build`，本试包不做。

## 装上之后怎么点

触控与鼠标走同一条链路：工程开启 `emulate_mouse_from_touch`，第一根手指合成鼠标左键。点格子、点单位、推进对话用 `PointerInput`；菜单和标题按钮是 `Button`，触摸与点击都会触发 `pressed`。第二根手指当作取消。屏幕上的「返回」与右键 / 取消同一层后退。Esc 与 Android 返回键：有选中或菜单时后退，否则打开或关闭系统菜单（工程已关闭 `quit_on_go_back`，返回键不会直接退出）。

1. **标题**：有存档时点「继续游戏」，否则点「新游戏」。已有存档时新游戏会先确认覆盖。左上角「菜单」可调音乐 / 音效。右上角语言按钮在「English / 中文」之间切换。
2. **旁白**：点屏幕推进，或点右上角「跳过 >>」。
3. **第一章**：点我方单位 → 点高亮格移动 → 行动菜单（贴着单位弹出）点「攻击」或「待机」→ 空地上点一下弹地图菜单 →「回合结束」。点菜单外即取消，系统菜单也在地图菜单里。每个我方回合开始自动存档。
   主操作避开贴边：左右 64、上下 48，回合结束再内缩 80，热区至少 48px。

## 冒烟

```bash
godot --headless --path ember_oath res://tools/smoke_runner.tscn
```

应打印 `ALL PASS`。其中包含横屏分辨率、`sensor_landscape`、触控模拟鼠标，以及单指选中 → 移动 → 攻击/待机 → 回合推进。

## 本环境验证（2026-10-15）

用 Godot 4.7.2 无头 `--export-debug "Android"` 打出已签名 debug APK（约 64MB）。`aapt dump badging`：包名 `com.emberoath.vow`，versionName `0.1.0`，`arm64-v8a` + `x86_64`，minSdk 24，targetSdk 36。清单里 `screenOrientation=0xb`（`userLandscape`），这是 Godot 4.7 对 `sensor_landscape` 的写入值，只允许横屏。

Android 14 x86_64 模拟器（逻辑屏 1280×720）上 `adb install -r` 成功，`am start` 能拉起进程，日志确认渲染器为 `gl_compatibility`。

同一台模拟器上没有走完可见的点选链路：

- `/dev/kvm` 报 `kvm_spurious_fault`，硬件加速不可用，只能软件模拟，主线程忙到 Android 把触控标成无响应并取消。
- SwiftShader 链不上 `CanvasShaderGLES3`（`GL_MAX_FRAGMENT_UNIFORM_VECTORS`，着色器活跃 uniform 261）。画面停在黑屏/启动图。这是模拟器 GLES 转译的限制，不是清单方向或包名错误。

真机用上面的 `adb install` / `am start` 即可。冒烟测试在桌面无头模式 ALL PASS，覆盖同一条 PointerInput 链路。
