Monitor this Beat Racer project for any file changes in real-time. Respond IMMEDIATELY when a change is detected.

## Real-time Monitoring Process:
1. Use `find` with `-mmin -0.5` to detect files modified in the last 30 seconds
2. Check git status for uncommitted changes
3. Compare against previous state to detect new changes
4. Respond IMMEDIATELY when any change is detected

## For Each Change Detected:

### 1. Immediate Change Report
- File path and type of change (created/modified/deleted)
- Brief description of what changed

### 2. Analysis (provide within seconds):
1. **Best Practices Compliance**: Does the change follow Godot 4 best practices from CLAUDE.md and /docs?
2. **Story Relevance**: Is the change relevant to the current story being worked on from backlog.md?
3. **Documentation Updates Needed**: Which /docs files need updating based on this change?
4. **Improvements**: What improvements could be made to the changed code?
5. **Risks**: What risks or potential issues are introduced by the change?

### 3. Documentation Check:
- List specific /docs files that should be updated
- Suggest what updates are needed
- Check if any new documentation should be created

## Special Attention Areas:
- Audio implementation (check against critical-audio-notes.md)
- Resource management patterns
- Signal usage and connections
- Performance implications
- Test coverage
- Project structure changes

## Implementation:
```bash
# Monitor loop
while true; do
    # Find recently modified files (last 30 seconds)
    RECENT_CHANGES=$(find . -type f -mmin -0.5 -not -path "./.git/*" -not -path "./.godot/*" 2>/dev/null)
    
    # Check git status
    GIT_STATUS=$(git status --porcelain)
    
    # If changes detected, analyze immediately
    if [ -n "$RECENT_CHANGES" ] || [ "$GIT_STATUS" != "$PREVIOUS_STATUS" ]; then
        # Report change IMMEDIATELY
        echo "🔔 CHANGE DETECTED at $(date)"
        # Analyze and report...
    fi
    
    PREVIOUS_STATUS="$GIT_STATUS"
    sleep 30
done
```

Continue monitoring until explicitly told to stop. Respond in real-time!

## How to Execute:
Use the monitoring script at `.claude/scripts/monitor.sh` to track changes and provide immediate feedback based on the analysis.