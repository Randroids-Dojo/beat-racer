# Project Structure

## Directory Organization

Organize your project with a clear folder structure to maintain cleanliness as it scales:

```
/project.godot
/addons/                 # Third-party plugins
/assets/
    /audio/
        /music/
        /sfx/
    /fonts/
    /sprites/
        /characters/
        /environment/
        /ui/
    /shaders/
/scenes/
    /levels/
    /ui/
    /characters/
    /common/             # Reusable scene components
/scripts/
    /autoloads/
        audio_manager.gd    # Global audio system manager
    /resources/          # Custom resource scripts
        lane_sound_config.gd
        lane_mapping_resource.gd
    /components/         # Reusable behavior scripts
        /sound/
            lane_sound_system.gd
            sound_generator.gd
        verification_helpers.gd
/resources/              # Non-script resources
    /themes/
    /presets/
    /lane_configs/       # Preset lane sound configurations
```

## Beat Racer Specific Structure

```
/docs/                   # Documentation files
/tests/
    /gut/
        /unit/          # Unit tests
        /integration/   # Integration tests
        /verification/  # Framework validation tests
/test_results/          # Test output (gitignored)
```

## Naming Conventions

- Use `snake_case` for folders, files, node names, and variables
- Use `PascalCase` for classes and custom resources
- Prefix autoloaded singletons with an underscore (e.g., `_GameState`)
- Use descriptive names that indicate purpose

## Import Settings

- Configure project-wide import presets for textures
- For 2D games, disable mipmaps unless needed for distant objects
- Set appropriate compression settings based on asset type
- Use texture atlases for related sprites to reduce draw calls

## Test Organization

```
tests/gut/
├── unit/                 # Unit tests for individual components
│   ├── test_audio_effect_properties.gd
│   ├── test_audio_generation.gd
│   ├── test_lane_sound_system.gd
│   ├── test_resource_validation.gd
│   ├── test_scale_compatibility.gd
│   └── test_ui_configuration.gd
├── integration/          # Integration tests for system interactions
│   ├── test_audio_system_integration.gd
│   └── test_lane_sound_integration.gd
└── verification/         # Verification tests for framework and assumptions
    └── test_gut_conversion_validation.gd
```

## File Type Conventions

- `.gd` - GDScript files
- `.tscn` - Scene files
- `.tres` - Resource files
- `.uid` - Godot UID files (auto-generated)
- `.md` - Documentation files

## Best Practices

1. Keep related files close together
2. Use consistent naming patterns within directories
3. Separate reusable components from specific implementations
4. Maintain clear boundaries between different system types
5. Document non-obvious directory purposes