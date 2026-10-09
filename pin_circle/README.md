# 见缝插针

> 点击屏幕，把针插进旋转的圆盘——别碰到其他针。

极简反射类街机小游戏。Godot 4.x / 2D / 1080×1920 竖屏 / 目标平台 Android。

## 玩法

- 点击屏幕任意处：从底部射出一根针，插进旋转的圆盘
- 针碰到已有的针：失败，点击重试
- 插完圆盘中央数字显示的针数：过关
- 难度曲线：针数递增、转速加快、每 3 关反转、第 3 关起预置针、第 8 关起中途变向
- 最佳关卡自动存档（`user://pin_save.json`）

## 运行

```bash
godot --path .                      # 运行
godot --path . res://tools/smoke_runner.tscn   # 冒烟测试(全流程+真实输入+竞态回归)
```

桌面双击 `E:\projects\taptap\玩见缝插针.bat` 直接玩。

## 导出 Android

环境已配好（见 `docs/publish_guide.md` 环境备忘）：

```bash
godot --headless --path . --export-debug "Android" builds/pin_circle_debug.apk
```

正式发布（release 签名 + TapTap 上架步骤）：见 [docs/publish_guide.md](docs/publish_guide.md)。

## 文件地图

```
pin_circle/
  project.godot          # 竖屏/stretch/主题
  export_presets.cfg     # Android 导出预设
  icon.png               # 512 图标(程序生成)
  scenes/main.tscn       # 唯一场景
  scenes/flying_pin.tscn
  scripts/
    main.gd              # 状态机/关卡生成/存档/果汁反馈
    wheel.gd             # 轮盘自绘 + 角度碰撞判定
    background.gd        # 星空渐变背景
    flying_pin.gd / ripple.gd
  audio/                 # 8 档音高 tick + fail + win(程序生成)
  tools/                 # 冒烟测试 + 截图
  docs/                  # 封面/截图/发布指南
  builds/                # APK 输出
```

## 素材授权

全部画面为代码实时绘制，音效为程序生成 WAV，无第三方素材。字体使用系统字体（SystemFont）。
