#!/bin/bash
# Ralph for Kimi Code CLI - Autonomous AI agent loop
# Usage: ./ralph.sh [max_iterations]
# 
# Based on the Ralph pattern by Geoffrey Huntley and the Ralph project for Amp/Claude
# Adapted for Kimi Code CLI

set -e

# Default max iterations
MAX_ITERATIONS=${1:-10}

# Script directory and file paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
PROMPT_FILE="$SCRIPT_DIR/KIMI.md"

# Check prerequisites
if ! command -v kimi &> /dev/null; then
    echo "Error: Kimi CLI not found. Please install Kimi Code CLI first."
    echo "Visit: https://github.com/moonshotai/kimi-cli"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Error: git not found. Please install git."
    exit 1
fi

if [ ! -f "$PRD_FILE" ]; then
    echo "Error: prd.json not found at $PRD_FILE"
    echo "Please create a prd.json file or use the PRD skill to generate one."
    exit 1
fi

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
    LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
    
    if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
        DATE=$(date +%Y-%m-%d)
        FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
        ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
        
        echo "Archiving previous run: $LAST_BRANCH"
        mkdir -p "$ARCHIVE_FOLDER"
        [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
        [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
        echo "   Archived to: $ARCHIVE_FOLDER"
        
        # Reset progress file for new run
        echo "# Ralph Progress Log" > "$PROGRESS_FILE"
        echo "Started: $(date)" >> "$PROGRESS_FILE"
        echo "---" >> "$PROGRESS_FILE"
    fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
    if [ -n "$CURRENT_BRANCH" ]; then
        echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
    fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
fi

echo ""
echo "==============================================================="
echo "  Ralph for Kimi Code CLI - Autonomous AI Agent Loop"
echo "==============================================================="
echo ""
echo "Max iterations: $MAX_ITERATIONS"
echo "PRD file: $PRD_FILE"
echo "Progress file: $PROGRESS_FILE"
echo ""

# Show current status
echo "Current PRD Status:"
jq -r '.userStories[] | "\(.id): \(.title) [passes: \(.passes)]"' "$PRD_FILE"
echo ""

for i in $(seq 1 $MAX_ITERATIONS); do
    echo ""
    echo "==============================================================="
    echo "  Ralph Iteration $i of $MAX_ITERATIONS"
    echo "==============================================================="
    echo ""

    # Run Kimi with the Ralph prompt
    # Use --print for non-interactive mode (auto-approves like --yolo)
    # Use --final-message-only for clean output
    OUTPUT=$(cat "$PROMPT_FILE" | kimi --print --final-message-only 2>&1) || true
    
    # Show output
    echo "$OUTPUT"
    
    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "==============================================================="
        echo "  RALPH COMPLETED ALL TASKS!"
        echo "==============================================================="
        echo ""
        echo "Completed at iteration $i of $MAX_ITERATIONS"
        echo ""
        
        # Show final status
        echo "Final PRD Status:"
        jq -r '.userStories[] | "\(.id): \(.title) [passes: \(.passes)]"' "$PRD_FILE"
        
        exit 0
    fi
    
    echo ""
    echo "Iteration $i complete. Checking for more work..."
    
    # Show current status
    echo ""
    echo "Current PRD Status:"
    jq -r '.userStories[] | "\(.id): \(.title) [passes: \(.passes)]"' "$PRD_FILE"
    
    sleep 2
done

echo ""
echo "==============================================================="
echo "  RALPH REACHED MAX ITERATIONS"
echo "==============================================================="
echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
echo ""

# Show final status
echo "Final PRD Status:"
jq -r '.userStories[] | "\(.id): \(.title) [passes: \(.passes)]"' "$PRD_FILE"

exit 1
