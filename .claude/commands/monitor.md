Monitor this Beat Racer project for any file changes in real-time. Report any new files, modifications, or deletions immediately. Check git status every 30 seconds and provide detailed alerts.

For each change detected, analyze and report:
1. **Best Practices Compliance**: Does the change follow Godot 4 best practices from CLAUDE.md and /docs?
2. **Story Relevance**: Is the change relevant to the current story being worked on from backlog.md?
3. **Documentation Review**: Are there relevant docs in /docs that should be reviewed for this change?
4. **Improvements**: What improvements could be made to the changed code?
5. **Risks**: What risks or potential issues are introduced by the change?

Pay special attention to:
- Audio implementation (check against critical-audio-notes.md)
- Resource management patterns
- Signal usage and connections
- Performance implications
- Test coverage

Continue monitoring until explicitly told to stop.