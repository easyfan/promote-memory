[English](README.md) | [中文](README-CN.md)

# promote-memory

Claude Code 记忆升级工具——扫描当前项目的 `memory/errors.md` 和 `memory/learnings.md`，将满足条件的条目升级到永久记忆（`~/.claude/CLAUDE.md` 或项目 `MEMORY.md`）。

```
/promote-memory
```

无需参数，自动扫描当前项目的 memory 目录。

---

## 工作原理

**Step 1 — 定位路径**：从当前工作目录推算 `PROJECT_MEMORY_DIR`，确认源文件存在。

**Step 2 — 调用 `memory-promoter` agent**：agent 读取 `errors.md` 和 `learnings.md`，按照 Promotion 条件逐条判断，将满足条件的条目写入目标文件。

**Promotion 条件：**

| 来源 | 条件 |
|------|------|
| `errors.md` | `status:new` 且「根因」和「解决方案」字段均已填写；或同一错误模式出现 ≥2 次 |
| `learnings.md` | `status:new` 且「内容」和「适用场景」字段均已填写；或条目创建 ≥7 天且两个字段均已填写 |

**目标文件选择规则：**

| 条目类型 | 目标 |
|---------|------|
| 项目特定（含项目路径、名称或专有技术栈） | 项目 memory 目录下的 `MEMORY.md` |
| 通用（含「所有项目」「通用」「任意项目」等关键词） | `~/.claude/CLAUDE.md` |
| 无法判定 | `MEMORY.md`（保守原则，避免污染全局）|

**Step 3 — 展示报告：**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Memory Promotion 完成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
已 promote 到 ~/.claude/CLAUDE.md：X 条
已 promote 到 MEMORY.md：Y 条
跳过（不满足条件）：Z 条
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
详细记录：<SCRATCH_DIR>/promotion_report.md
```

已 promote 的条目在源文件中标记为 `status:promoted`（保留用于审计）。每条条目同时在 `memory/errors/` 或 `memory/learnings/` 下生成独立文件。

---

## 安装

### 方案 A — Claude Code plugin（推荐）

```
/plugin marketplace add easyfan/promote-memory
/plugin install promote-memory@promote-memory
```

### 方案 B — install.sh

```bash
git clone https://github.com/easyfan/promote-memory
cd promote-memory
bash install.sh
```

```bash
bash install.sh --dry-run      # 预览，不写入
bash install.sh --uninstall    # 卸载
CLAUDE_DIR=/custom bash install.sh   # 自定义 Claude 配置目录
```

### 方案 C — 手动复制

```bash
cp commands/promote-memory.md ~/.claude/commands/
cp agents/memory-promoter.md  ~/.claude/agents/
```

---

## 使用建议

- **触发时机**：每隔 3–5 个工作会话运行一次；或 `errors.md` 中积累了 ≥5 条 `status:new` 条目；或同一错误出现 ≥2 次
- **运行前**：建议先手动填写 `status:new` 错误条目的「根因」和「解决方案」——缺少这两个字段的条目将被跳过
- **并发风险**：避免在多个项目中同时运行，以防并发写入 `~/.claude/CLAUDE.md` 导致内容丢失

---

## 安装文件

```
~/.claude/
├── commands/
│   └── promote-memory.md    # /promote-memory 命令入口
└── agents/
    └── memory-promoter.md   # promotion 逻辑 agent（自动被命令调用）
```

### 包结构

```
promote-memory/
├── .claude-plugin/
│   ├── plugin.json          # CC plugin 清单
│   └── marketplace.json     # marketplace 条目
├── commands/promote-memory.md
├── agents/memory-promoter.md
├── evals/evals.json
├── install.sh
└── package.json
```

---

## 依赖

- **Claude Code** CLI
- 无其他依赖

---

## Evals

`evals/evals.json` 包含 5 个测试用例：

| ID | 场景 | 验证重点 |
|----|------|---------|
| 1 | errors.md 和 learnings.md 均存在且字段完整 | 两个文件均被 promote，报告显示计数 |
| 2 | 仅 errors.md 存在（learnings.md 缺失） | 仅 promote errors，缺失文件不报错 |
| 3 | 单条完整 error 条目 | promote 计数 > 0，报告中提及目标文件 |
| 4 | 不完整条目（缺少「解决方案」字段） | 条目被跳过，报告显示跳过原因 |
| 5 | errors.md 全部已 promoted，learnings 有新条目 | 仅 promote learnings，errors 正确跳过 |

---

## 许可证

MIT
