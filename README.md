# Ralph for Kimi Code CLI

Ralph is an autonomous AI agent loop that runs Kimi Code CLI repeatedly until all PRD (Product Requirements Document) items are complete. Each iteration is a fresh instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

This is a port of the original [Ralph](https://github.com/snarktank/ralph) project (built for Amp and Claude Code) to work with [Kimi Code CLI](https://github.com/moonshotai/kimi-cli).

Based on the [Ralph pattern](https://ghuntley.com/ralph) by Geoffrey Huntley.

## Prerequisites

- [Kimi Code CLI](https://github.com/moonshotai/kimi-cli) installed and authenticated
- Git repository for your project
- PowerShell (Windows) or Bash (Linux/macOS - use `ralph.sh`)

## Quick Start

### 1. Copy Ralph Files to Your Project

From your project root:

```powershell
# Create the ralph directory
mkdir -p scripts/ralph

# Copy the Ralph files
cp /path/to/ralph-kimi/ralph.ps1 scripts/ralph/
cp /path/to/ralph-kimi/KIMI.md scripts/ralph/

# Make the script executable (if needed)
chmod +x scripts/ralph/ralph.ps1  # Linux/Mac only
```

### 2. Copy Skills to Your Kimi Config (Optional but Recommended)

Copy the skills to your Kimi config for use across all projects:

```powershell
# Windows
Copy-Item -Recurse skills/prd $env:USERPROFILE\.kimi\skills\
Copy-Item -Recurse skills/ralph $env:USERPROFILE\.kimi\skills\

# Or use the standard agents directory
Copy-Item -Recurse skills/prd $env:USERPROFILE\.config\agents\skills\
Copy-Item -Recurse skills/ralph $env:USERPROFILE\.config\agents\skills\
```

```bash
# Linux/Mac
cp -r skills/prd ~/.kimi/skills/
cp -r skills/ralph ~/.kimi/skills/

# Or use the standard agents directory
cp -r skills/prd ~/.config/agents/skills/
cp -r skills/ralph ~/.config/agents/skills/
```

### 3. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
/skill:prd
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 4. Convert PRD to Ralph Format

Use the Ralph skill to convert the markdown PRD to JSON:

```
/skill:ralph
```

This creates `prd.json` with user stories structured for autonomous execution.

### 5. Run Ralph

```powershell
# PowerShell
.\scripts\ralph\ralph.ps1 [max_iterations]

# Default is 10 iterations
.\scripts\ralph\ralph.ps1

# Or specify a custom number
.\scripts\ralph\ralph.ps1 20
```

Ralph will:
- Create a feature branch (from PRD `branchName`)
- Pick the highest priority story where `passes: false`
- Implement that single story
- Run quality checks (typecheck, tests)
- Commit if checks pass
- Update `prd.json` to mark story as `passes: true`
- Append learnings to `progress.txt`
- Repeat until all stories pass or max iterations reached

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                        Ralph Loop                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │ Kimi CLI │───→│  Git     │───→│ prd.json │              │
│  │  (New)   │    │ (Memory) │    │ (Status) │              │
│  └──────────┘    └──────────┘    └──────────┘              │
│       ↑                                          │          │
│       └──────────┐    ┌──────────┐              │          │
│                  │    │ progress │              ↓          │
│                  └───→│  .txt    │←─────────────┘          │
│                       │(Learnings)│                         │
│                       └──────────┘                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

Each iteration spawns a new Kimi instance with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

## File Structure

| File | Purpose |
|------|---------|
| `ralph.ps1` | The PowerShell loop that spawns fresh Kimi instances |
| `KIMI.md` | Prompt template for Kimi Code CLI |
| `prd.json` | User stories with passes status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `skills/prd/` | Skill for generating PRDs |
| `skills/ralph/` | Skill for converting PRDs to JSON format |

## Writing Good PRDs

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

## Progress Tracking

After each iteration, Ralph updates `progress.txt` with learnings. Check status anytime:

```powershell
# See which stories are done
cat prd.json | ConvertFrom-Json | Select-Object -ExpandProperty userStories | Select-Object id, title, passes

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Customizing for Your Project

After copying `KIMI.md` to your project, customize it for your project:

- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Completion

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Notes & Troubleshooting

### Execution Time

Each Ralph iteration can take **30-120 seconds** or more, depending on:
- Complexity of the task
- Size of your codebase
- Network latency to Kimi API
- Number of tools Kimi needs to use

This is normal - Kimi is reading files, analyzing code, making changes, running checks, and committing. Be patient!

### Timeouts

If you're running Ralph in an environment with timeout limits (like CI/CD), you may need to:
- Increase timeout limits
- Reduce the number of stories per PRD
- Run Ralph locally instead

### Checking Progress During Run

Since each iteration takes time, you can check progress in another terminal:

```powershell
# Watch PRD status
watch -n 5 "cat scripts/ralph/prd.json | ConvertFrom-Json | Select-Object -ExpandProperty userStories | Select-Object id, passes"

# Watch git log
watch -n 5 "git log --oneline -5"

# Watch progress
watch -n 5 "cat scripts/ralph/progress.txt"
```

### Kimi CLI Configuration

Ralph uses Kimi's `--print` mode which:
- Runs non-interactively (no user input needed)
- Auto-approves all tool calls (equivalent to `--yolo`)
- Outputs only the final message

Make sure Kimi CLI is properly authenticated before running Ralph:
```bash
kimi login
```

### Stopping Ralph

To stop Ralph mid-run:
- Press `Ctrl+C` in the terminal
- Or close the terminal window

Ralph can be safely stopped at any time. When you restart, it will:
- Pick up where it left off (based on `prd.json` status)
- Archive previous run if branch changed
- Continue with remaining stories

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## License

MIT - See LICENSE file for details.

## Credits

- Original Ralph pattern by [Geoffrey Huntley](https://ghuntley.com/ralph)
- Original Ralph implementation for Amp/Claude by [Snarktank](https://github.com/snarktank/ralph)
- Ported to Kimi Code CLI by contributors
