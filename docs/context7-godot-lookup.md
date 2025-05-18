# Using Context7 for Godot Documentation

Context7 is an essential tool for looking up accurate Godot 4 documentation. This guide shows how to use it effectively.

## Basic Usage

### Step 1: Get the Godot Library ID

Always start by getting the Godot library ID:

```
mcp__context7-mcp__resolve-library-id:
  libraryName: "godot"
```

This returns a Context7-compatible library ID that you'll use in all subsequent lookups.

### Step 2: Look Up Documentation

Once you have the library ID, look up specific documentation:

```
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <id_from_step_1>
  topic: "AudioEffectDelay"
  tokens: 5000  # Optional: Control amount of documentation returned
```

## Common Lookup Examples

### Audio Classes
```
# Audio effect properties
topic: "AudioEffectDelay"
topic: "AudioEffectReverb"
topic: "AudioEffectCompressor"

# Audio generation
topic: "AudioStreamGenerator"
topic: "AudioStreamGeneratorPlayback"

# Audio management
topic: "AudioServer"
topic: "AudioStreamPlayer"
```

### UI Controls
```
# Slider properties (CRITICAL for step property)
topic: "HSlider"
topic: "VSlider"
topic: "Range"  # Base class for sliders

# Other UI elements
topic: "Control"
topic: "Button"
topic: "Label"
```

### Physics and Movement
```
# Character physics
topic: "CharacterBody2D"
topic: "RigidBody2D"
topic: "Area2D"

# Physics properties
topic: "PhysicsServer2D"
topic: "CollisionShape2D"
```

### Signals and Events
```
# Signal documentation
topic: "signal"
topic: "Object emit_signal"
topic: "Object connect"
```

## Advanced Searches

### Search for Methods
```
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <id>
  topic: "get_stream_playback"  # Specific method
  tokens: 3000
```

### Search for Properties
```
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <id>
  topic: "HSlider step"  # Specific property
  tokens: 3000
```

### Search for Constants
```
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <id>
  topic: "AudioServer BUS_COUNT"  # Specific constant
  tokens: 3000
```

## Best Practices

1. **Always Verify Property Names**: Before using any property, check it exists
   ```
   topic: "AudioEffectDelay dry"  # Verify 'dry' property exists
   ```

2. **Check Method Signatures**: Understand parameters and return types
   ```
   topic: "AudioServer add_bus_effect"
   ```

3. **Look Up Inheritance**: Understand class hierarchies
   ```
   topic: "CharacterBody2D extends"
   ```

4. **Find Related Classes**: Discover related functionality
   ```
   topic: "AudioEffect"  # Base class for all effects
   ```

5. **Check for Deprecations**: Ensure you're using current API
   ```
   topic: "deprecated audio"
   ```

## Troubleshooting Common Issues

### Audio Effect Properties
When you get property errors:
```
# Check what properties actually exist
topic: "AudioEffectDelay properties"
tokens: 8000
```

### Signal Connection Issues
When signals won't connect:
```
# Check signal parameters
topic: "Object connect parameters"
tokens: 5000
```

### UI Control Behavior
When UI controls behave unexpectedly:
```
# Check all properties and their defaults
topic: "HSlider properties default"
tokens: 8000
```

## Integration with Testing

Use Context7 lookups in your test files:

```gdscript
# In test files, document your lookups
func test_audio_effect_properties():
    # Verified with Context7:
    # topic: "AudioEffectDelay" shows 'dry' property, no 'mix'
    var delay = AudioEffectDelay.new()
    assert_true("dry" in delay.get_property_list())
    assert_false("mix" in delay.get_property_list())
```

## Quick Reference Card

```
# Get library ID (always do first)
mcp__context7-mcp__resolve-library-id:
  libraryName: "godot"

# Basic lookup
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <id>
  topic: "ClassName"

# Detailed lookup
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <id>
  topic: "ClassName specific_property"
  tokens: 10000
```

Remember: Always verify with Context7 before implementing!