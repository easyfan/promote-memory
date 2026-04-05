---
description: Memory promotion agent — reads errors.md and learnings.md, evaluates each status:new entry against promotion criteria, and writes qualifying entries to MEMORY.md or CLAUDE.md. Called by /promote-memory command.
model: sonnet
isolation: none
allowed-tools: ["Read", "Write", "Bash"]
---

# memory-promoter

扫描项目 memory 目录中的 errors.md 和 learnings.md，将满足 Promotion 条件的条目升级到永久记忆。

## 输入参数

由 `/promote-memory` 命令传入：
- `PROJECT_MEMORY_DIR`：项目 memory 目录路径
- `CLAUDE_MD`：`$HOME/.claude/CLAUDE.md` 路径
- `PROJECT_MEMORY_MD`：项目 MEMORY.md 路径
- `PROJECT_ROOT`：项目根目录路径
- `SCRATCH_DIR`：scratch 报告输出目录，由 `/promote-memory` 命令传入

## 执行流程

### Step 1：读取源文件

读取以下文件（若文件不存在则跳过）：
- `${PROJECT_MEMORY_DIR}/errors.md`
- `${PROJECT_MEMORY_DIR}/learnings.md`
- `${PROJECT_MEMORY_DIR}/MEMORY.md`
- `${CLAUDE_MD}`

### Step 2：解析条目并判断 Promotion 条件

**errors.md 格式：**
```
ERR-YYYYMMDD-NNN | status:new/promoted | 错误描述
根因：...
解决方案：...
```

**Promotion 条件（errors）：**
- `status:new` 且"根因"和"解决方案"字段均已填写
- 或同一错误模式出现 ≥2 次

**learnings.md 格式：**
```
LEARN-YYYYMMDD-NNN | status:new/promoted | 学习主题
内容：...
适用场景：...
```

**Promotion 条件（learnings）：**
- `status:new` 且"内容"和"适用场景"字段均已填写
- 或条目创建时间距今 ≥7 天且"内容"和"适用场景"字段均已填写

### Step 3：写入目标文件

**目标选择规则：**
- **项目特定**的错误/学习 → 写入 `${PROJECT_MEMORY_MD}`
- **通用**的错误/学习（适用于多个项目）→ 写入 `${CLAUDE_MD}`

**判定规则（按优先级）：**
1. 条目"根因"或"解决方案"字段含 `${PROJECT_ROOT}` 路径、项目名称或项目特有技术栈 → 项目特定
2. 条目内容含"所有项目"、"通用"、"任意项目"等关键词 → 通用
3. 以上均无法判定 → 默认写入 `${PROJECT_MEMORY_MD}`（保守原则，避免污染全局）

**写入格式（MEMORY.md）：**
```markdown
- [错误描述](errors/err_YYYYMMDD_NNN.md) — 一句话总结
```

同时创建独立文件 `${PROJECT_MEMORY_DIR}/errors/err_YYYYMMDD_NNN.md`：
```markdown
---
name: 错误描述
description: 一句话总结
type: feedback
source-project: ${PROJECT_ROOT}
---

[原始错误内容]

**根因：** ...
**解决方案：** ...
```

**写入格式（CLAUDE.md）：**
在 `## 工程实践` 或 `## 常见错误` 章节追加：
```markdown
### 错误描述

根因：...
解决方案：...
适用项目：${PROJECT_ROOT}
```

### Step 4：更新源文件状态

将已 promote 的条目状态从 `status:new` 改为 `status:promoted`。

### Step 5：生成报告

输出格式：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Memory Promotion Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Promoted to PROJECT_MEMORY.md:
  - ERR-20260320-001: Bash 工具调用失败处理
  - LEARN-20260322-001: Agent 隔离策略选择

Promoted to CLAUDE.md:
  - ERR-20260318-002: Git worktree 清理时机

Skipped (incomplete):
  - ERR-20260325-003: 缺少"解决方案"字段

Total: 3 promoted, 1 skipped
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

将上述报告内容使用 Write tool 写入 `${SCRATCH_DIR}/promotion_report.md`。

## 注意事项

- 写入 `CLAUDE.md` 前先读取全文，避免重复写入相同内容
- 若 `MEMORY.md` 中已存在相同条目链接，跳过该条目
- 创建独立 memory 文件时，确保 `errors/` 或 `learnings/` 子目录存在
- 并发安全：本 agent 不应与其他写入 `CLAUDE.md` 的操作同时运行
