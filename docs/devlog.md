# Blue Lake 开发日志

每轮结束在末尾追加一条：日期、做了什么、怎么测试的、还没做完的、需要用户决定的。规则见 `AGENTS.md`。

---

## 2026-10-24 — 项目整理与版本控制（Claude Code）

### 做了什么

本轮只做项目整理，**没有修改任何游戏代码**（`.gd` / `.tscn` / `project.godot` 均未改动）。

- 新增 `.gitignore`：排除 `.godot/`、`.DS_Store`、`**/.DS_Store`、`.artifacts/`、`*.tmp`。
- 重写 `AGENTS.md`：旧内容停留在 Prototype 0.2。阅读 README、迁移审计、`chapter_state.gd`、`main.gd`、美术馆流程表、BLUE_LAKE_CONTEXT 和四份场景 PDF 后，按真实状态重写：项目定位与硬性约束、主角命名（格雷汉）、操作语言、设计权威顺序、S01–S08 实际玩法、待决问题、工作流、交接规则、测试命令。
- 新增 `CLAUDE.md`（只有一行 `@AGENTS.md`）。
- 新增本文件 `docs/devlog.md`。
- 更新 `README.md`：说明 S01–S08 已全部实现、运行方法、操作方式，删除“S03 未实现”等过时说法。
- `git init`（分支 main），remote 设为 `https://github.com/iggour/blue-lake-game.git`，初始提交并推送（结果见本轮汇报）。

### 怎么测试的

- Godot 4.7.2（`/Users/zhangtongyang/Downloads/Godot.app/Contents/MacOS/Godot`）无界面模式：
  - 对 `scripts/` 下全部 6 个 `.gd` 逐个 `--check-only --script`：**无解析错误**。
  - `--headless --quit-after 120` 运行主场景：**无运行时错误输出**。
- 确认 `--check-only` 确实能报出错误：在临时目录里放一个故意写错的脚本，能输出 `SCRIPT ERROR: Parse Error`，但退出码仍为 0 —— 所以检查时必须 grep 输出，已写入 AGENTS.md。
- 运行 Godot 前后对项目文件（不含 `.godot/`）做了校验和比对，无变化。
- 没有做手动试玩，也没有脚本化走通测试（项目里尚无测试脚本）。

### 还没做完的

- 没有任何 Slice 的脚本化测试；第一次写时建议放在 `tests/`。
- 下列待决问题均未处理。

### 需要用户决定的

- **a)** S08 只淡出到 `"outside"`，没有接上「窗 → 幕布 → 真理剧院」转场（CONTEXT 中最重要的里程碑）。`transition_overlay.gd` 已存在，但 S08 主线未使用，只在 S06「拿走原件」分支调用，且落点也是 outside。
- **b)** S06「拿走原件」分支被追后翻窗直接结束，跳过 S07/S08；「留下展品」分支没有 PDF 写的修复师/参观者赠送复制品，也没有道德倾向变量。
- **c)** S04 用荧光剂 + 关灯让参观者认出格雷汉；PDF 写的是参观者靠声音/动作认出修复师。是否有意改动？
- **d)** 场景顺序冲突：CONTEXT 为 美术馆 → 剧院 → 澡堂 → 下水道；澡堂 PDF 写的是从美术馆的窗翻进澡堂、之后去剧院。
- **e)** `main.gd` 1800 多行，每个 Slice 重复一套变量和函数，应逐个 Slice 拆出去；拆分需先经用户同意。
- **f)**（本次额外发现）下水道 PDF 的战斗系统/Boss/神经画像结算，剧院与澡堂 PDF 的倾向变量、支线任务、好感度，美术馆 PDF 的调窗模式，都与“无战斗/无属性/视觉模式不做热键”约束冲突，如何转译待定。
- **g)**（本次额外发现）阿姨名字：CONTEXT 写 Aunt Cote，PDF 与代码写肯特阿姨 / Kent。
- **h)**（小问题）`main.gd` 中部分游戏内文字为繁体（参观者、修复师、机械维纳斯等处），与其余简体不统一。
