# Blue Lake / 蓝湖 — Chapter 1: Truth Gallery

《蓝湖》是一个小型、可行走的 2D 解谜叙事游戏（不是 RPG），使用 Godot 4.x 开发。主角是格雷汉·斯蒂尔（Graham Steel）。

第一章「真理美术馆」的 S01–S08 已全部实现，可以从头走到尾：

S01 进入 → S02 迷路 → S03 镜子 → S04 参观者 → S05《窗》 → S06 中央展台 → S07 回访 → S08 真正出口

每个 Slice 的实际玩法、已知问题和待决设计冲突见 [`AGENTS.md`](AGENTS.md)。开发记录见 [`docs/devlog.md`](docs/devlog.md)。

## 运行

1. 安装 Godot 4.x（项目在 4.7.2 下测试）。
2. 用 Godot 编辑器导入本目录（`project.godot`）并运行；或在项目根目录执行：

   ```bash
   /path/to/Godot.app/Contents/MacOS/Godot --path .
   ```

3. 主场景是 `scenes/main/prototype_01.tscn`，大部分逻辑在 `scripts/main.gd`。

无界面检查命令见 `AGENTS.md` 第 8 节。

## 操作

- `WASD` / 方向键：移动格雷汉
- `E`：普通观察 / 询问 / 环境互动
- `Space`：进入或退出蓝湖
- 进入蓝湖后，鼠标变成 Chalk Cursor；移到特殊目标上，按**左键**作用于它

没有视觉模式热键（Q 或数字键），这是有意的设计。

## 文件

- `AGENTS.md` — Codex 与 Claude Code 共用的项目规则（`CLAUDE.md` 只引用它）
- `docs/devlog.md` — 每轮开发的交接记录
- `docs/chapter1_migration_audit.md` — 从 Prototype 0.2 迁移到 S01–S08 的历史审计
- `workflow/美术馆/美术馆流程.xlsx` — 第一章 S01–S08 流程表（章节推进的设计权威）
- `蓝湖 *设计文档.pdf` — 四个场景的设计文档
- `BLUE_LAKE_CONTEXT.md.docx` — 补充背景
