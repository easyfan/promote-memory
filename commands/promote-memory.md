---
description: 扫描 memory/errors.md 和 learnings.md，将满足条件的条目升级到永久记忆。仅由用户手动执行 /promote-memory 触发，不应由其他 agent 自动调用。
allowed-tools: ["Bash", "Read", "Task"]
---
# /promote-memory

扫描当前项目的 `memory/errors.md` 和 `memory/learnings.md`，将满足 Promotion 条件的条目升级到永久记忆（`~/.claude/CLAUDE.md` 或项目 `MEMORY.md`）。

## 用法

```
/promote-memory
```

无需参数，自动扫描当前项目的 memory 目录。

## 执行步骤

**Step 0：定位路径**

```bash
PROJECT_ROOT=$(pwd)
PROJECT_KEY=$(pwd | tr '/' '-')
PROJECT_MEMORY_DIR="$HOME/.claude/projects/${PROJECT_KEY}/memory"
SCRATCH_DIR="$PROJECT_ROOT/.claude/agent_scratch/promote_memory"
mkdir -p "$SCRATCH_DIR"
```

确认以下文件存在：
- `${PROJECT_MEMORY_DIR}/errors.md`
- `${PROJECT_MEMORY_DIR}/learnings.md`
- `${PROJECT_MEMORY_DIR}/MEMORY.md`（项目 MEMORY.md）
- `$HOME/.claude/CLAUDE.md`（用户级永久记忆）

参考检查命令：
```bash
ls ${PROJECT_MEMORY_DIR}/errors.md ${PROJECT_MEMORY_DIR}/learnings.md \
   ${PROJECT_MEMORY_DIR}/MEMORY.md $HOME/.claude/CLAUDE.md 2>/dev/null
```

若 errors.md 和 learnings.md 都不存在，输出提示并退出："无可用的源文件，请先运行项目积累 memory 条目。"

若 CLAUDE.md 或 MEMORY.md 不存在，自动创建空文件并输出提示："目标文件不存在，已自动创建。"

若其他文件不存在，告知用户并跳过该文件（不报错退出）。

**Step 1：启动 memory-promoter agent**

输出进度提示：`[Step 1] 正在分析 memory 条目并执行 promotion，预计耗时 10-30 秒...`

调用 `memory-promoter` agent（Task tool），传入：

```
请执行 memory promotion 任务。

PROJECT_MEMORY_DIR: ${PROJECT_MEMORY_DIR}
CLAUDE_MD: $HOME/.claude/CLAUDE.md
PROJECT_MEMORY_MD: ${PROJECT_MEMORY_DIR}/MEMORY.md
PROJECT_ROOT: ${PROJECT_ROOT}
SCRATCH_DIR: ${SCRATCH_DIR}

请将 Promotion 报告写入 ${SCRATCH_DIR}/promotion_report.md
```

Task tool 参数：
- `subagent_type: "memory-promoter"`

若 agent 返回错误或超时，向用户输出错误信息并终止流程。

**Step 2：展示报告**

输出进度提示：`[Step 2] 正在生成报告...`

检查 `${SCRATCH_DIR}/promotion_report.md` 是否存在；若不存在，向用户输出：
"Promotion 报告未生成，可能原因：SCRATCH_DIR 路径问题或 agent 静默失败。请检查 ${SCRATCH_DIR}/ 目录内容后重新运行。"
并退出。

读取 `${SCRATCH_DIR}/promotion_report.md` 并呈现给用户。报告应至少包含：
- 已 promote 条目数（按目标文件分组）
- 跳过条目数及原因
- 写入的目标文件路径

建议报告格式：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Memory Promotion 完成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
已 promote 到 ~/.claude/CLAUDE.md：X 条
已 promote 到 MEMORY.md：Y 条
跳过（不满足条件）：Z 条
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
详细记录：${SCRATCH_DIR}/promotion_report.md
```

## 使用提示

- ⚠️ **并发风险**：避免在多个项目中同时运行本命令，以防并发写入 `~/.claude/CLAUDE.md` 导致内容丢失
- **触发时机**：每隔 3-5 个工作会话运行一次；或 `memory/errors.md` 中积累了 ≥5 条 `status:new` 条目、或同一错误出现 ≥2 次时主动运行
- 对于 `status:new` 的 errors 条目，建议先手动填写"根因"和"解决方案"字段，再运行本命令
- Promotion 后的条目保留在原文件中（status:promoted），可用于审计
