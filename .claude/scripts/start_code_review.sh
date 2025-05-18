#!/bin/bash
# chmod +x applied

# This script will execute the code review monitor
# Wrapper script that ensures proper permissions and environment

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

MONITOR_SCRIPT="/Users/randroid/Dev/Games/beat-racer/.claude/scripts/code_review_monitor.sh"
PROJECT_ROOT="/Users/randroid/Dev/Games/beat-racer"

# Check if the monitor script exists
if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo -e "${RED}Error: Monitor script not found at $MONITOR_SCRIPT${NC}"
    exit 1
fi

# Make sure the script is executable
if [ ! -x "$MONITOR_SCRIPT" ]; then
    echo "Making monitor script executable..."
    chmod +x "$MONITOR_SCRIPT"
fi

# Kill any existing instances
existing_pid=$(ps -ef | grep "code_review_monitor.sh" | grep -v grep | awk '{print $2}')
if [ -n "$existing_pid" ]; then
    echo -e "${GREEN}Stopping existing monitor process (PID: $existing_pid)...${NC}"
    kill $existing_pid 2>/dev/null
    sleep 1
fi

# Make sure we're in the project root directory
cd "$PROJECT_ROOT"

# Create CLAUDE.md if it doesn't exist
if [ ! -f "$PROJECT_ROOT/.claude/CLAUDE.md" ]; then
    mkdir -p "$PROJECT_ROOT/.claude"
    cp "$PROJECT_ROOT/.claude/commands/review_changes.md" "$PROJECT_ROOT/.claude/CLAUDE.md" 2>/dev/null || \
    cat > "$PROJECT_ROOT/.claude/CLAUDE.md" << 'EOL'
# Beat Racer Code Review Guidelines

As you review code for the Beat Racer project, please apply the following standards:

## CRITICAL Audio Implementation
- AudioEffectDelay uses 'dry' parameter, NOT 'mix'
- Audio bus indices must be checked before use
- Beat synchronization must be precise

## Code Quality
- Use static typing and proper annotations
- Avoid print statements (use Logger class)
- Implement proper error handling
- Document complex algorithms
- Use constants instead of magic numbers

## Performance
- Optimize rhythm-critical code paths
- Properly manage audio resources
- Clean up resources in _exit_tree()
- Use appropriate data structures

Please provide specific, actionable feedback with code examples when possible.
EOL
    echo -e "${GREEN}Created CLAUDE.md with Beat Racer code review guidelines${NC}"
fi

# Execute the monitor script with auto-yes for test file creation
echo -e "${GREEN}Starting Beat Racer Code Review Monitor...${NC}"
exec "$MONITOR_SCRIPT" <<< "n"

