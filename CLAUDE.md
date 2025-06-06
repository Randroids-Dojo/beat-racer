# Godot 4 Best Practices for Beat Racer

This is the main documentation index for the Beat Racer project. Documentation has been organized into separate files for better maintainability.

## 🚨 CRITICAL - Read First
**[Critical Audio Implementation Notes](docs/critical-audio-notes.md)** - Must-read before any audio work
- AudioEffectDelay property names (use 'dry' not 'mix')
- Slider configuration requirements (step = 0.01)
- Verification procedures before implementation

**🔍 ERROR CHECKING** - Run before committing code:
```bash
bash check_errors.sh
```
- Comprehensive error detection for parse, type, and script errors
- Must pass before submitting any changes
- Use regularly during development to catch issues early

## Quick Navigation

### Core Development
1. **[Project Structure](docs/project-structure.md)** - Directory organization and naming conventions
2. **[Node Organization](docs/node-organization.md)** - Node hierarchy and communication patterns
3. **[Scene Composition](docs/scene-composition.md)** - Component-based design and scene structure
4. **[Scripting Patterns](docs/scripting-patterns.md)** - GDScript 2.0 features and coding standards
5. **[Context7 Godot Lookup](docs/context7-godot-lookup.md)** - How to use Context7 for accurate Godot docs

### Systems Implementation
6. **[Input Handling](docs/input-handling.md)** - Input architecture, buffering, and rhythm detection
7. **[Performance Optimization](docs/performance-optimization.md)** - Optimization techniques and profiling
8. **[Audio Implementation](docs/audio-implementation.md)** - Audio architecture and procedural generation
9. **[Audio Effect Guidelines](docs/audio-effect-guidelines.md)** - Effect properties and common mistakes
10. **[Signal Management](docs/signal-management.md)** - Event system and signal best practices
11. **[Resource Management](docs/resource-management.md)** - Resource loading and pooling strategies
12. **[State Management](docs/state-management.md)** - State machines and game state patterns

### UI and Polish
13. **[UI Design](docs/ui-design.md)** - UI architecture, theming, and responsive design
14. **[Testing and Debugging](docs/testing-debugging.md)** - GUT framework, debugging tools, and best practices

## When to Read Each Section

### Starting a New Feature
1. Read [Critical Audio Notes](docs/critical-audio-notes.md) if working with audio
2. Review [Project Structure](docs/project-structure.md) for file organization
3. Check [Scripting Patterns](docs/scripting-patterns.md) for coding standards

### When You Need API Documentation
1. Use [Context7 Godot Lookup](docs/context7-godot-lookup.md) to verify:
   - Property names and types
   - Method signatures
   - Class inheritance
   - Signal parameters
2. Always check before implementing new features
3. Verify when debugging unexpected behavior

### Working with Audio
1. **Always** start with [Critical Audio Notes](docs/critical-audio-notes.md)
2. Read [Audio Implementation](docs/audio-implementation.md) for architecture
3. Consult [Audio Effect Guidelines](docs/audio-effect-guidelines.md) before using effects
4. Run tests in `/tests/gut/unit/test_audio_effect_properties.gd`

### Creating UI
1. Read [UI Design](docs/ui-design.md) for architecture patterns
2. **Critical**: Check slider configuration section (step = 0.01)
3. Review [Signal Management](docs/signal-management.md) for event handling

### Debugging Issues
1. Start with [Testing and Debugging](docs/testing-debugging.md)
2. Check [Critical Audio Notes](docs/critical-audio-notes.md) for common audio issues
3. Use GUT tests in `/tests/gut/` for verification

### Performance Issues
1. Read [Performance Optimization](docs/performance-optimization.md)
2. Review [Resource Management](docs/resource-management.md) for pooling
3. Check [Node Organization](docs/node-organization.md) for hierarchy optimization

## Project-Specific Notes

### Beat Racer Requirements
- Rhythm-based gameplay mechanics
- Dynamic audio generation
- Real-time beat synchronization
- Performance-critical audio processing

### Testing Commands
```bash
# Check for errors before running tests
bash check_errors.sh

# Run all tests (with zero-orphan policy)
./run_gut_tests.sh

# Run with JUnit XML report
./run_gut_tests.sh --report

# Test specific category
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut/unit/

# Run with verbose output for debugging
./run_gut_tests.sh --verbose

# Find orphan nodes
godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -glog=3
```

Note: All tests follow zero-orphan policy. See [Testing and Debugging](docs/testing-debugging.md) for details.

## Key Reminders

1. **Run error checking** with `bash check_errors.sh` before committing ✓
2. **AudioEffectDelay** uses 'dry' property, NOT 'mix' ✓
3. **Sliders** must have step = 0.01 for smooth operation ✓
4. **Always test** with GUT framework before implementing
5. **Use Context7** to verify Godot API properties (see [Context7 Guide](docs/context7-godot-lookup.md))
6. **Log comprehensively** for easier debugging

### Quick Context7 Reference
```
# Get Godot library ID first
mcp__context7-mcp__resolve-library-id:
  libraryName: "godot"

# Then look up any class/method/property
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <id>
  topic: "AudioEffectDelay dry"
```

## Project Progress

### Completed Stories
- Story 001: Audio Bus Setup ✓
- Story 002: Lane-based Sound Generator ✓
- Story 003: Beat Synchronization System ✓
- Story 004: Simple Sound Playback Test ✓
- Story 005: Basic Track Layout ✓ (See [Story 005 Complete](docs/story-005-complete.md))
- Story 006: Single Vehicle Implementation ✓ (See [Story 006 Complete](docs/story-006-complete.md))
- Story 007: Lane Detection System ✓ (See [Story 007 Complete](docs/story-007-complete.md))
- Story 008: Visual Feedback System ✓ (See [Story 008 Complete](docs/story-008-complete.md))
- Story 009: Lane Position to Sound Mapping ✓ (See [Story 009 Complete](docs/story-009-complete.md))
- Story 010: Lap Recording System ✓ (See [Story 010 Complete](docs/story-010-complete.md))
- Story 011: Path Playback System ✓ (See [Story 011 Complete](docs/story-011-complete.md))
- Story 012: Basic UI Elements ✓ (See [Story 012 Complete](docs/story-012-complete.md))
- Story 013: Sound Visualization ✓ (See [Story 013 Complete](docs/story-013-complete.md))
- Story 014: Audio Mixing Controls ✓ (See [Story 014 Complete](docs/story-014-complete.md))
- Story 015: Vehicle Feel Improvements ✓ (See [Story 015 Complete](docs/story-015-complete.md))
- Story 016: Camera System ✓ (See [Story 016 Complete](docs/story-016-complete.md))
- Story 017: Multiple Sound Banks ✓ (See [Story 017 Complete](docs/story-017-complete.md))
- Story 017.5: Main Game Scene Integration ✓
- Story 018: Save/Load System ✓ (See [Story 018 Complete](docs/story-018-complete.md))
- Story 019: Audio Export ✓

### Next Story
- Story 020: Track Editor

## Additional Resources

- [Official Godot Documentation](https://docs.godotengine.org/en/stable/)
- [GDQuest Tutorials](https://www.gdquest.com/)
- [KidsCanCode Godot Recipes](https://kidscancode.org/godot_recipes/)

---

*Remember: These are guidelines to help create a well-structured, maintainable, and performant game. Adapt them to suit your specific needs.*