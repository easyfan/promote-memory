[English](README.md) | [中文](README-CN.md)

# promote-memory

Memory promotion tool for Claude Code — scans `memory/errors.md` and `memory/learnings.md` in the current project and upgrades qualifying entries to permanent memory (`~/.claude/CLAUDE.md` or project `MEMORY.md`).

```
/promote-memory
```

No arguments. Automatically scans the current project's memory directory.

---

## What it does

**Step 1 — Locate paths**: resolves `PROJECT_MEMORY_DIR` from the current working directory, confirms source files exist.

**Step 2 — Invoke `memory-promoter` agent**: the agent reads `errors.md` and `learnings.md`, evaluates each `status:new` entry against promotion criteria, and writes qualifying entries to the appropriate target file.

**Promotion criteria:**

| Source | Condition |
|--------|-----------|
| `errors.md` | `status:new` + both "根因" and "解决方案" fields filled; or same error pattern appears ≥2 times |
| `learnings.md` | `status:new` + both "内容" and "适用场景" fields filled; or entry is ≥7 days old with both fields filled |

**Target selection:**

| Entry type | Target |
|------------|--------|
| Project-specific (contains project path, name, or tech stack) | `MEMORY.md` in project memory dir |
| General (keywords: "所有项目", "通用", "任意项目") | `~/.claude/CLAUDE.md` |
| Undetermined | `MEMORY.md` (conservative default) |

**Step 3 — Show report**:

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

Promoted entries are marked `status:promoted` in the source file and kept for audit. A separate memory file per entry is written into `memory/errors/` or `memory/learnings/`.

---

## Install

### Option A — Claude Code plugin (recommended)

```
/plugin marketplace add easyfan/promote-memory
/plugin install promote-memory@promote-memory
```

### Option B — install script

```bash
git clone https://github.com/easyfan/promote-memory
cd promote-memory
bash install.sh
```

```bash
bash install.sh --dry-run      # preview without writing
bash install.sh --uninstall    # remove installed files
CLAUDE_DIR=/custom bash install.sh   # custom Claude config path
```

### Option C — manual

```bash
cp commands/promote-memory.md ~/.claude/commands/
cp agents/memory-promoter.md  ~/.claude/agents/
```

---

## Usage tips

- **When to run**: every 3–5 work sessions; or when `errors.md` has ≥5 `status:new` entries; or the same error appears ≥2 times
- **Before running**: fill in "根因" and "解决方案" fields manually for `status:new` errors — entries missing these fields will be skipped
- **Concurrency**: avoid running in multiple projects simultaneously — concurrent writes to `~/.claude/CLAUDE.md` may lose data

---

## Files installed

```
~/.claude/
├── commands/
│   └── promote-memory.md    # /promote-memory slash command
└── agents/
    └── memory-promoter.md   # promotion logic agent (called automatically)
```

### Package structure

```
promote-memory/
├── .claude-plugin/
│   ├── plugin.json          # CC plugin manifest
│   └── marketplace.json     # marketplace entry
├── commands/promote-memory.md
├── agents/memory-promoter.md
├── evals/evals.json
├── install.sh
└── package.json
```

---

## Requirements

- **Claude Code** CLI
- No other dependencies

---

## Evals

`evals/evals.json` contains 5 test cases:

| ID | Scenario | What is verified |
|----|----------|-----------------|
| 1 | Both errors.md and learnings.md present, entries complete | Both files promoted, report shows counts |
| 2 | Only errors.md present (learnings.md missing) | Promotes errors only, no crash on missing file |
| 3 | Single complete error entry | Promoted count > 0, target file mentioned |
| 4 | Incomplete entry (missing "解决方案") | Entry skipped, report shows skip reason |
| 5 | errors.md already promoted, fresh learnings entry | Only learnings promoted, errors correctly skipped |

---

## License

MIT
