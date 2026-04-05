---
description: 扫描 memory/errors.md 和 learnings.md，将满足条件的条目升级到永久记忆。仅由用户手动执行 /promote-memory 触发，不应由其他 agent 自动调用。
allowed-tools: ["Bash", "Read", "Agent"]
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

若 errors.md 和 learnings.md 中仅有一个不存在，告知用户将仅扫描存在的那个文件，继续执行（不报错退出）。

通过 Bash 统计可用源文件中 `status:new` 条目数，若为 0 则提前退出：

```bash
NEW_COUNT=$(grep -c "status:new" "${PROJECT_MEMORY_DIR}/errors.md" "${PROJECT_MEMORY_DIR}/learnings.md" 2>/dev/null | awk -F: '{sum += $2} END {print sum+0}')
echo "NEW_COUNT=$NEW_COUNT"
```

若 `NEW_COUNT=0`，输出提示并退出："当前无待 promote 条目（errors.md 和 learnings.md 中均无 status:new 条目），无需运行。"

**Step 1：启动 memory-promoter agent**

先通过 Bash 检查 memory-promoter agent 是否已安装：

```bash
ls ~/.claude/agents/memory-promoter.md 2>/dev/null && echo "AGENT_OK" || echo "AGENT_MISSING"
```

若输出 `AGENT_MISSING`，输出以下提示并退出：
"memory-promoter agent 未安装。请先安装 promote-memory 插件：
  Option A: /plugin install promote-memory@promote-memory
  Option B: cp agents/memory-promoter.md ~/.claude/agents/"

若输出 `AGENT_OK`，输出进度提示：`[Step 1] 正在分析 memory 条目并执行 promotion，预计耗时 10-30 秒...`

然后通过 Bash 将路径变量展开为实际值，再通过 Agent tool（subagent_type: "memory-promoter"）传入已展开的路径：

```bash
echo "PROJECT_MEMORY_DIR=$HOME/.claude/projects/$(pwd | tr '/' '-')/memory"
echo "CLAUDE_MD=$HOME/.claude/CLAUDE.md"
echo "SCRATCH_DIR=$(pwd)/.claude/agent_scratch/promote_memory"
echo "PROJECT_ROOT=$(pwd)"
# 将展开值写入锚文件（存放于 SCRATCH_DIR，项目隔离，避免多项目并发冲突）
printf "PROJECT_MEMORY_DIR=%s\nCLAUDE_MD=%s\nSCRATCH_DIR=%s\nPROJECT_ROOT=%s\n" \
  "$HOME/.claude/projects/$(pwd | tr '/' '-')/memory" \
  "$HOME/.claude/CLAUDE.md" \
  "$(pwd)/.claude/agent_scratch/promote_memory" \
  "$(pwd)" > "$(pwd)/.claude/agent_scratch/promote_memory/paths.env"
```

使用上述 Bash 输出的实际展开值（而非 shell 变量名）构造 Agent 调用，prompt 和 subagent_type 均为必填参数：

Agent tool 参数（两个字段均为必填，不得省略）：
- `subagent_type: "memory-promoter"`
- `prompt: <以下模板全文，将所有 <bash 实际展开的 XXX> 占位符替换为上方 Bash 实际输出值后的完整字符串，不得保留任何 <...> 占位符>`

prompt 模板（占位符替换后的全文作为 prompt 参数值传入）：

```
请执行 memory promotion 任务。

PROJECT_MEMORY_DIR: <bash 实际展开的 PROJECT_MEMORY_DIR>
CLAUDE_MD: <bash 实际展开的 CLAUDE_MD>
PROJECT_MEMORY_MD: <bash 实际展开的 PROJECT_MEMORY_DIR>/MEMORY.md
PROJECT_ROOT: <bash 实际展开的 PROJECT_ROOT>
SCRATCH_DIR: <bash 实际展开的 SCRATCH_DIR>

请将 Promotion 报告写入 <bash 实际展开的 SCRATCH_DIR>/promotion_report.md
```

若 agent 返回错误或工具调用本身失败，向用户输出：
"[Step 1] memory-promoter agent 执行失败。
错误信息：<实际错误内容>
如需查看部分结果，请检查 <实际 SCRATCH_DIR>/promotion_report.md（可能为空）。
可重新运行 /promote-memory 重试。"
然后终止流程。

**Step 2：展示报告**

输出进度提示：`[Step 2] 正在生成报告...`

通过 Bash 从锚文件中读取 Step 1 已展开的 SCRATCH_DIR 绝对路径，检查报告文件是否存在：

```bash
SCRATCH_DIR_ABS=$(grep SCRATCH_DIR .claude/agent_scratch/promote_memory/paths.env | cut -d= -f2-)
ls "${SCRATCH_DIR_ABS}/promotion_report.md" 2>/dev/null && echo "REPORT_OK" || echo "REPORT_MISSING"
```

若输出 `REPORT_MISSING`，向用户输出（使用锚文件中 SCRATCH_DIR_ABS 实际值）：
"Promotion 报告未生成，可能原因：agent 未成功写入报告文件。
请检查 ${SCRATCH_DIR_ABS}/ 目录内容后重新运行。"
并退出。

读取 `${SCRATCH_DIR_ABS}/promotion_report.md` 并呈现给用户。报告应至少包含：
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
详细记录：<实际 SCRATCH_DIR 路径>/promotion_report.md
```

## 使用提示

- ⚠️ **并发风险**：避免在多个项目中同时运行本命令，以防并发写入 `~/.claude/CLAUDE.md` 导致内容丢失
- **触发时机**：每隔 3-5 个工作会话运行一次；或 `memory/errors.md` 中积累了 ≥5 条 `status:new` 条目、或同一错误出现 ≥2 次时主动运行
- 对于 `status:new` 的 errors 条目，建议先手动填写"根因"和"解决方案"字段，再运行本命令
- Promotion 后的条目保留在原文件中（status:promoted），可用于审计
