# Code Review Instructions

When reviewing code changes for the Beat Racer project, please follow these comprehensive guidelines. Check the project backlog to understand what features are in development.

## GDScript Best Practices

### Type Annotations
- Use static typing for all variables: `var speed: float = 5.0`
- Add return types to functions: `func calculate_score() -> int:`
- Use typed arrays where possible: `var sounds: Array[AudioStreamPlayer] = []`
- Favor strong types over variant where intention is clear

### Variable Initialization
- Initialize all member variables at declaration
- Use default arguments for function parameters
- Verify nullability before accessing optional resources
- Use assert() for critical initialization checks

### Naming Conventions
- Use snake_case for variables, functions, and files
- Use PascalCase for classes and nodes
- Prefix private variables with underscore: `_private_var`
- Use descriptive names that indicate purpose and units: `car_speed_meters_per_second`
- Prefix signals with "on_": `signal on_lane_changed(lane_index: int)`

### Logging and Debugging
- NEVER use print() statements in production code
- Use the Logger class: `Logger.debug("Vehicle speed: %s", speed)`
- Set appropriate log levels (DEBUG/INFO/WARN/ERROR)
- Add context to log messages (class name, function, relevant values)
- Log entry and exit points for important functions

### Error Handling
- Check file operations with appropriate error messages
- Use try/except for recoverable errors
- Add appropriate fallbacks for missing resources
- Use is_instance_valid() before accessing potentially freed objects
- For audio operations, have fallback sounds if loading fails

## Beat Racer Audio-Specific Guidelines

- **CRITICAL**: AudioEffectDelay uses 'dry' parameter, NOT 'mix'
- Always check audio bus indices match expected values
- Use the SoundManager singleton for playing sounds
- Implement proper error handling for audio file loading
- Always use beat-synchronized playback for musical elements
- Check BPM-related calculations twice for accuracy
- Use lane-specific sound generation protocols as documented
- Always normalize audio levels when combining multiple streams

## Performance Considerations

### Efficient Algorithms
- Optimize inner loops for rhythm-critical code
- Use spatial partitioning for vehicle track detection
- Pre-calculate beat markers instead of runtime calculation
- Cache frequently accessed values
- Use _physics_process only for physics-related code
- Consider time complexity for any algorithm operating per-frame

### Resource Management
- Use resource preloading for frequently used assets
- Implement proper resource cleanup in _exit_tree()
- Use ResourceLoader.load_threaded for background loading
- Pool reusable objects rather than instantiating/freeing
- Release audio resources when not in active use
- Use object pooling for particle effects and sounds

### Memory Usage
- Monitor for memory leaks using proper profiling
- Use weakrefs for non-owning references
- Be cautious with large arrays/dictionaries
- Consider using typed arrays (Float32Array, etc.) for large datasets
- Use streaming for large audio files

### Rendering and Physics
- Minimize physics operations in audio-critical code paths
- Use physics layers to optimize collision detection
- Implement LOD (Level of Detail) for distant objects
- Use occlusion culling techniques for complex scenes
- Batch similar draw calls where possible
- Use simplified collision shapes

## Code Quality

### Constants and Configuration
- Use @export variables for designer-tunable parameters: `@export var max_speed: float = 120.0`
- Define named constants for magic numbers: `const LANE_COUNT: int = 3`
- Use enums for related constants: `enum Lane {LEFT, CENTER, RIGHT}`
- Store configuration in resource files when appropriate
- Use project settings for global configuration

### Code Structure
- Keep functions under 30 lines for readability
- Follow single responsibility principle for classes
- Use composition over inheritance where possible
- Implement state pattern for complex object behavior
- Follow MVC pattern for UI components
- Use dependency injection for testable components

### Code Duplication
- Extract repeated code into helper functions
- Use inheritance for shared behavior when appropriate
- Create utility classes for common operations
- Use strategy pattern for algorithm variations
- Consider generics for container operations

### Complexity Management
- Use early returns to reduce nesting
- Break complex calculations into named steps
- Keep cyclomatic complexity under 10 per function
- Use guard clauses to handle edge cases first
- Favor readability over cleverness

## Documentation

### Code Documentation
- Add class-level documentation for all scripts: `## Vehicle controller that handles lane-based movement`
- Document non-obvious parameters and return values
- Explain complex algorithms with comments
- Document magic numbers if they must exist: `# 0.016667 is 1/60, for per-frame timing`
- Use TODO/FIXME comments for future work, include ticket numbers

### Variable Documentation
- Use descriptive names over comments where possible
- Explain the purpose of complex data structures
- Document units for numeric values: `# speed in meters per second`
- Note valid ranges for parameters: `# Valid range: 0.0 to 1.0`
- Document threading concerns where applicable

### Project Documentation
- Update docs/audio-implementation.md when changing audio systems
- Add testing instructions for complex features
- Document performance implications of significant changes
- Update class diagrams for architectural changes
- Keep the backlog updated with implementation notes

## Beat Racer-Specific Guidelines

### Track and Vehicle Systems
- Ensure lane detection is precise and consistent
- Verify vehicle movement is beat-synchronized
- Test lane changes work with all vehicle types
- Follow established patterns for track generation
- Ensure physics settings are consistent across scenes

### Audio Systems
- Verify all audio is properly synchronized to the beat system
- Check for audio resource leaks after scene changes
- Ensure all audio effects use correct property names
- Test volume levels across different sound combinations
- Verify audio bus routing is correct for each sound type

### UI and Feedback
- Ensure UI elements follow the design system
- Verify beat visualization is accurate
- Test UI responsiveness at different resolutions
- Ensure accessibility considerations are addressed
- Follow the established color scheme and typography

### Game Loop
- Verify recording and playback systems work correctly
- Ensure lap detection is accurate and consistent
- Test beat synchronization at different BPM values
- Verify score calculation is accurate
- Ensure game state transitions are smooth

## Review Process

For changed files, provide specific feedback with code examples where possible. Focus on:

1. Critical issues that could lead to bugs or crashes
2. Performance implications for frame rate or audio timing
3. Maintainability and readability improvements
4. Alignment with Beat Racer's architecture and style
5. Potential edge cases or failure modes

Reference specific documentation or backlog items when applicable to provide context for your recommendations.
