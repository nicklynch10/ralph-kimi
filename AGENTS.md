# Ralph for Kimi Code CLI - Agent Instructions

This file contains information for AI agents working on the Ralph project itself.

## Project Overview

Ralph is an autonomous AI agent loop that runs Kimi Code CLI repeatedly until all PRD items are complete. This is a port of the original Ralph project from Amp/Claude Code to Kimi Code CLI.

## Project Structure

```
.
├── ralph.ps1           # Main PowerShell script that runs the loop
├── KIMI.md             # Prompt template for Kimi Code CLI
├── prd.json.example    # Example PRD format
├── README.md           # Documentation
├── AGENTS.md           # This file
└── skills/
    ├── prd/            # Skill for generating PRDs
    │   └── SKILL.md
    └── ralph/          # Skill for converting PRDs to JSON
        └── SKILL.md
```

## Key Differences from Original Ralph

| Feature | Original Ralph (Amp/Claude) | Ralph for Kimi |
|---------|------------------------------|----------------|
| Script | `ralph.sh` (Bash) | `ralph.ps1` (PowerShell) |
| Prompt | `prompt.md` / `CLAUDE.md` | `KIMI.md` |
| Auto-approve | `--dangerously-allow-all` / `--dangerously-skip-permissions` | `--print` mode (implicit) |
| Skills dir | `~/.amp/skills/` or `~/.claude/skills/` | `~/.kimi/skills/` or `~/.config/agents/skills/` |

## How Ralph Works

1. **Loop**: `ralph.ps1` runs a loop for N iterations
2. **Spawn**: Each iteration spawns Kimi with `KIMI.md` as the prompt via stdin
3. **Execute**: Kimi reads `prd.json`, picks a task, implements it
4. **Commit**: Changes are committed to git
5. **Update**: `prd.json` and `progress.txt` are updated
6. **Check**: Script checks for `<promise>COMPLETE</promise>` signal

## Kimi CLI Specifics

- Use `--print` for non-interactive mode (auto-approves all actions)
- Use `--final-message-only` for clean output
- Kimi reads the prompt from stdin when piped
- Skills are discovered from `~/.kimi/skills/` or project `.kimi/skills/`

## Testing Changes

When modifying the Ralph script:

1. Test with a sample `prd.json`
2. Ensure proper error handling
3. Verify git operations work correctly
4. Check that iteration limits are respected

## Common Tasks

### Adding a new quality check

Edit `KIMI.md` and add the check to the "Quality Requirements" section.

### Modifying the progress format

Update both `KIMI.md` and `skills/ralph/SKILL.md` to keep them in sync.

### Adding platform support

The current implementation is PowerShell for Windows. For cross-platform support, consider:
- Creating a bash equivalent (`ralph.sh`)
- Using Python for a universal script

## Code Style

- PowerShell: Use explicit parameter names, proper error handling
- Markdown: Use consistent heading levels, clear examples
- JSON: Use 2-space indentation
