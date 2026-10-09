# 《见缝插针》TapTap 发布指南

## 已就绪的材料（本仓库内）

| 材料 | 位置 | 规格 |
|---|---|---|
| 可安装 APK（调试签名） | `builds/pin_circle_debug.apk` | arm64, 28.5MB |
| 应用图标 | `icon.png` | 512×512 |
| 封面 | `docs/cover_1920x1080.png` | 1920×1080 |
| 截图 ×3 | `docs/screenshots/` | 1080×1920 竖屏 9:16 |
| Android 导出预设 | `export_presets.cfg` | 已配置竖屏/arm64 |

## 四条发布路径（按门槛从低到高）

### 路径 0：直接分享 APK（零门槛，今天就能做）
把 `builds/pin_circle_debug.apk` 通过微信/QQ/网盘发给朋友，安卓手机直接安装。
适合：先收集真实手感反馈。**调试签名的包不能用于正式上架。**

### 路径 1：TapTap 篝火测试（推荐起步）
面向独立游戏的测试渠道，**无需版号**，有核心玩家社区给反馈。
1. 注册 [TapTap 开发者中心](https://developer.taptap.cn)（个人开发者，实名认证：身份证 + 人脸识别）
2. 创建游戏 → 填名称/类型/简介（文案见下）
3. 上传图标、封面、截图
4. 上传 APK → 选择「篝火测试/试玩」
5. 审核通常 1-3 个工作日

### 路径 2：TapTap 国服正式上架
- **需要版号**（国家新闻出版署审批）或小游戏备案；无内购的免费小游戏备案相对简单，但个人开发者走版号流程周期长（数月）
- 正式包必须用**自己的发布密钥**签名（见下文"打正式包"），并妥善保管——丢失将无法更新游戏
- 建议：先篝火测试验证，再决定是否投入

### 路径 3：TapTap 国际版 taptap.io
面向海外玩家，**无需版号**，流程同路径 1。游戏目前只有中文文案，上架前建议补英文。

## 打正式包（Release APK）

```bash
# 1. 生成发布密钥（只需一次；密码自己设并牢记，keystore 文件备份好）
"C:\Program Files\Java\jdk-24\bin\keytool.exe" -genkeypair -alias release -keyalg RSA -keysize 2048 -validity 10000 -keystore release.keystore

# 2. 在 Godot 编辑器: 项目 -> 导出 -> Android 预设 -> Keystore 栏填入 release.keystore 路径/密码
# 3. 或命令行:
Godot_v4.7.2-stable_win64.exe --headless --path pin_circle --export-release "Android" builds/pin_circle_release.apk
```

## 上架文案（可直接粘贴）

**游戏名**：见缝插针
**一句话介绍**：点击屏幕，把针插进旋转的圆盘——别碰到其他针。
**简介**：
一根针，一个旋转的圆盘，一次点击。看准空隙出手，针针入盘；手抖一瞬，前功尽弃。
越往后针越多、转越快、还会突然反转。极简画面，极度上瘾。你能撑到第几关？
**标签**：休闲, 街机, 单人, 极简, 反应
**视频建议**：录 15-20 秒连续过关 + 一次失败的真实游玩即可（手机模拟器或 scrcpy 投屏录制）。

## 环境备忘（本机已配置）

- Godot 4.7.2 便携版：`E:\projects\taptap\tools\godot\`
- Android SDK（platform-35 + build-tools 35.0.0）：`E:\projects\taptap\tools\android-sdk\`
- JDK 24：`C:\Program Files\Java\jdk-24`
- 调试密钥：`C:\Users\lushe\.android\debug.keystore`（android / androiddebugkey）
- 导出模板：已装入 `%APPDATA%\Godot\export_templates\4.7.2.stable\`
