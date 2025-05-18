# Audio Effect Guidelines

## Verification Before Implementation

When implementing audio systems in Godot 4, ALWAYS verify effect properties before using them:

### 1. Use Context7 for Documentation

To look up any Godot class documentation:

```
# Step 1: Get the Godot library ID
mcp__context7-mcp__resolve-library-id:
  libraryName: "godot"

# Step 2: Get documentation for specific class
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <returned_id_from_step_1>
  topic: "AudioEffectDelay"  # Replace with any Godot class name
```

Example topics you might look up:
- `"AudioEffectDelay"` - Audio delay effect properties
- `"AudioStreamGenerator"` - Procedural audio generation
- `"HSlider"` - Slider control properties
- `"AudioServer"` - Audio bus management
- `"CharacterBody2D"` - Character physics properties

You can also search for specific functionality:
```
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <returned_id>
  topic: "signal"  # Search for signal-related documentation
  tokens: 10000    # Get more comprehensive results
```

### 2. Property Verification

Use the `verification_helpers.gd` script to check if properties exist:

```gdscript
# Check if property exists
if property_exists(effect, "property_name"):
    effect.property_name = value
else:
    print("Property does not exist!")

# List all available properties
var properties = list_properties(effect)
for prop in properties:
    print(prop)
```

### 3. Use Audio Debugging Tools

```gdscript
# Initialize debugger
var audio_debugger = preload("res://scripts/components/audio_debugger.gd").new()

# Test specific effect
audio_debugger.test_effect("AudioEffectDelay")
```

## Important Notes (Verified in test_comprehensive_audio.gd)

1. **AudioEffectDelay**:
   - Does NOT have a 'mix' property ✓
   - Use 'dry' property instead
   - Verified in test_audio_effect_properties.gd

2. **Effect Property Names**:
   - Different effects use different property names for similar concepts
   - Always verify before using
   - Don't assume consistency across effect types

3. **Testing Process**:
   - Run test_comprehensive_audio.gd before implementing
   - Use small test implementations first
   - Gradually build up complex systems

## Common Effect Properties by Type

### AudioEffectReverb
```gdscript
var reverb = AudioEffectReverb.new()
reverb.room_size = 0.8
reverb.damping = 0.5
reverb.wet = 0.33
reverb.dry = 0.66
reverb.spread = 1.0
```

### AudioEffectDelay
```gdscript
var delay = AudioEffectDelay.new()
delay.dry = 0.8  # NOT 'mix'!
delay.tap1_delay_ms = 250.0
delay.tap1_level_db = -6.0
delay.tap1_pan = 0.2
```

### AudioEffectCompressor
```gdscript
var compressor = AudioEffectCompressor.new()
compressor.threshold = -20.0
compressor.ratio = 4.0
compressor.attack_us = 20.0
compressor.release_ms = 250.0
compressor.gain = 0.0
```

### AudioEffectDistortion
```gdscript
var distortion = AudioEffectDistortion.new()
distortion.mode = AudioEffectDistortion.MODE_CLIP
distortion.pre_gain = 0.0
distortion.keep_hf_hz = 16000.0
distortion.drive = 0.0
distortion.post_gain = 0.0
```

## Common Implementation Mistakes

### 1. UI Control Issues
- **Problem**: Sliders only showing 0 or 1 values
- **Cause**: Missing `step` property in scene file
- **Solution**: Always set `step = 0.01` for continuous controls
- **Prevention**: Configure sliders programmatically as failsafe

```gdscript
func _ready():
    for slider in get_tree().get_nodes_in_group("volume_sliders"):
        slider.min_value = 0.0
        slider.max_value = 1.0
        slider.step = 0.01  # CRITICAL!
```

### 2. Audio Stream Generation
- **Problem**: Test sounds not playing
- **Cause**: Incorrect async handling or missing null checks
- **Solution**: Generate all audio frames immediately, check stream playback
- **Prevention**: Add error checking and status logging

```gdscript
func generate_test_sound():
    var player = AudioStreamPlayer.new()
    var gen = AudioStreamGenerator.new()
    gen.mix_rate = 44100.0
    player.stream = gen
    add_child(player)
    player.play()
    
    var playback = player.get_stream_playback()
    if playback == null:
        print("ERROR: Failed to get stream playback")
        player.queue_free()
        return
    
    # Generate all frames at once
    for i in range(44100):  # 1 second
        var value = sin(2.0 * PI * 440.0 * i / 44100.0)
        playback.push_frame(Vector2(value, value))
```

### 3. Missing Feedback
- **Problem**: Issues hard to diagnose from logs
- **Cause**: Insufficient logging at critical points
- **Solution**: Log all user actions and system responses
- **Prevention**: Implement comprehensive logging system from start

```gdscript
func _log(category: String, message: String):
    var timestamp = Time.get_time_string_from_system()
    print("[%s] %s: %s" % [timestamp, category, message])

# Use throughout code
_log("Audio", "Initializing effect: %s" % effect.get_class())
_log("UI", "Slider value changed: %f" % value)
_log("System", "Bus created: %s" % bus_name)
```

## Testing Checklist

Before deploying audio effects:

- [ ] Run test_comprehensive_audio.gd
- [ ] Verify all UI sliders have step = 0.01
- [ ] Check effect properties with Context7
- [ ] Test with verification_helpers.gd
- [ ] Log all operations
- [ ] Test on target hardware
- [ ] Handle edge cases (null checks, etc.)

## Effect Chains Best Practices

When chaining multiple effects:

```gdscript
func create_effect_chain(bus_name: String):
    var bus_idx = AudioServer.get_bus_index(bus_name)
    
    # Order matters! Apply in sequence:
    # 1. Compression (dynamics control)
    var compressor = AudioEffectCompressor.new()
    compressor.threshold = -12.0
    AudioServer.add_bus_effect(bus_idx, compressor)
    
    # 2. EQ (frequency shaping)
    var eq = AudioEffectEQ10.new()
    AudioServer.add_bus_effect(bus_idx, eq)
    
    # 3. Reverb (spatial effects)
    var reverb = AudioEffectReverb.new()
    reverb.wet = 0.2
    AudioServer.add_bus_effect(bus_idx, reverb)
    
    # 4. Limiter (final protection)
    var limiter = AudioEffectLimiter.new()
    limiter.ceiling_db = -0.5
    AudioServer.add_bus_effect(bus_idx, limiter)
```

## Resources

- [Godot AudioEffect Documentation](https://docs.godotengine.org/en/stable/classes/class_audioeffect.html)
- Run `./run_gut_tests.sh` for verification
- See test files in `/tests/gut/unit/`