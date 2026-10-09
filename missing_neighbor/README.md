# 失踪的邻居

> 她不见了。还是，你不见了？

短篇叙事解谜（约 40 分钟）。你以为在查邻居去哪了；真相是邻居没失踪，失踪的是你自己。

- 引擎：Godot 4.x（开发验证版本 4.7.2），2D，1080×1920 竖屏（手机优先）
- 玩法：搜证点击 + 线索板拖拽配对（仅此两种）
- 平台目标：Android（可先在桌面调试运行）

---

## 一、如何运行（桌面调试）

1. 安装 Godot 4.3 或更高版本（标准版即可，无需 .NET）。
2. 打开 Godot 项目管理器 → 导入 → 选择本目录的 `project.godot`。
3. 按 F5（或点击右上角运行），主场景为 `res://scenes/main_menu.tscn`。

命令行方式：

```bash
godot --path .                 # 运行游戏
godot --headless --import --path .   # 仅导入资源/检查脚本
```

## 二、如何导出 Android APK

1. Godot 编辑器菜单：**编辑器 → 管理导出模板 → 下载并安装**（与编辑器同版本）。
2. 安装 JDK 17 与 Android SDK（可用 Android Studio 装 SDK Platform + Build-tools）。
3. **编辑器设置 → Export → Android**：填入 SDK 路径。
4. **项目 → 导出 → 添加预设 → Android**：
   - 包名建议：`com.yourname.missing_neighbor`
   - 方向：Portrait（项目设置中已默认竖屏）
   - 架构：勾选 `arm64-v8a`
   - 勾选 **Export With Debug**（试玩包）或配置发布 keystore（正式包）
5. 点击 **Export Project** 得到 APK。
6. TapTap 路径：先建游戏页开「预约」→ 试玩/正式包再补资质；若走 Tap 小游戏正式上线需前置备案（无内购相对简单）。本项目按 **APK / TapPlay** 思路导出即可。

## 三、文件地图

```
missing_neighbor/
  project.godot            # 项目配置(竖屏/拉伸/Autoload/主题)
  icon.png                 # 应用图标(程序生成)
  data/
    levels/level_01..12.json   # 12 关全部数据(热点/证据/线索板/文案/结局)
    strings/ui_zh.json         # 界面文案
  scenes/
    main_menu.tscn         # 主菜单: 新游戏/继续/退出
    game.tscn              # 游戏壳: 承载关卡、转场、氛围音
    level_view.tscn        # 关卡视图(数据驱动)
    inventory_ui.tscn      # 背包
    evidence_board.tscn    # 线索板(拖拽配对)
    ending.tscn            # 结局演出
  scripts/
    autoload/game_state.gd     # GameState: 关卡进度/证据/提示计时/UI文案
    autoload/save_manager.gd   # SaveManager: user://save.json 读写
    main_menu.gd
    game.gd
    level_controller.gd    # 关卡控制器(读 JSON 驱动一切)
    hotspot.gd             # 热点(隐形, 提示时描边闪烁)
    inventory.gd
    evidence_board.gd      # 手动拖拽实现, 触屏可靠
    ending_controller.gd
  art/
    bg/                    # 13 张场景背景(程序生成)
    icons/                 # 29 个证据图标(程序生成)
    characters/            # 林晚音剪影
    ui/default_theme.tres  # 全局主题(SystemFont 中文)
  audio/                   # click/success/fail/ambience(程序生成 WAV)
  tools/
    smoke_test.gd          # 冒烟测试(JSON 校验+全流程驱动+截图)
    smoke_runner.tscn
    shots/                 # 测试截图输出
../tools/                  # 仓库级工具(不在游戏项目内)
  generate_art.py          # 占位美术生成器(Pillow)
  generate_audio.py        # 音效生成器
  godot/                   # 便携版 Godot 4.7.2(本地验证用)
```

## 四、自动化自测

```bash
godot --path . res://tools/smoke_runner.tscn
```

覆盖：12 关 JSON 字段与引用完整性、存档读写、主菜单→关卡→热点→背包→线索板全流程、
错误/正确配对反馈、垂直切片(1/5/10/12)通关、提示系统(无操作描边闪烁→线索板自动高亮)、
结局双选项。截图输出到 `tools/shots/`。

## 五、素材与授权

- 全部美术与音频均为程序生成（`tools/generate_art.py` / `generate_audio.py`），无第三方版权素材。
- 字体：开发期使用 Godot `SystemFont`（Windows 微软雅黑 / Android 系统 Noto CJK 回退），不打包字体文件。
  正式发布如需统一观感，可换思源黑体（SIL OFL 授权），替换 `art/ui/default_theme.tres` 中的字体并在本文件注明。

## 六、验收清单

- [x] 新游戏从关 1 开始
- [x] 关 1/5/10/12 必得证据可获得
- [x] 线索板错/对反馈正确
- [x] 存档后杀掉进程再进可继续
- [x] 12 关都能进并能通关到结局
- [x] 结局两选项都能回到主菜单
- [x] 无操作会触发提示（90 秒描边闪烁 → 再 60 秒线索板自动高亮）
- [x] 竖屏 1080×1920 布局无严重遮挡
- [x] README 含运行与导出步骤
- [x] 无第三方版权素材
