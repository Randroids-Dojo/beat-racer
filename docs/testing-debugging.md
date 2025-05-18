# Testing and Debugging

## Built-in Debug Tools

### Print Statements with Context

```gdscript
print("[Player] Health changed: ", old_health, " -> ", new_health)
print("[%s] %s" % [self.name, message])  # Include object name
```

### Use the Godot Debugger Panel

1. Print call stack when errors occur
2. Monitor variables in real-time
3. Set breakpoints for stepping through code
4. Use the profiler to identify performance bottlenecks

### Visual Debugging

```gdscript
func _draw():
    if OS.is_debug_build():
        # Draw hitbox outline
        draw_rect(Rect2($CollisionShape2D.position - $CollisionShape2D.shape.extents, 
                 $CollisionShape2D.shape.extents * 2),
                 Color.RED, false, 2.0)
        
        # Draw movement vector
        draw_line(Vector2.ZERO, _velocity.normalized() * 50, Color.GREEN, 2.0)
        
        # Draw debug text
        draw_string(get_theme_default_font(), Vector2(0, -20), 
                   "State: %s" % current_state.name, HORIZONTAL_ALIGNMENT_CENTER)
```

## GUT Testing Framework

The Beat Racer project uses the Godot Unit Test (GUT) framework with a zero-orphan policy for clean, maintainable testing.

### Quick Start

```bash
# Run all tests
./run_gut_tests.sh

# Run with JUnit XML report
./run_gut_tests.sh --report

# Run specific test category
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut/unit/

# Run specific test file
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut/unit/test_audio_effect_properties.gd
```

### Test Directory Structure

```
tests/
├── gut/                       # All GUT-based tests
│   ├── unit/                 # Unit tests for individual components
│   │   ├── test_audio_effect_properties.gd
│   │   ├── test_audio_generation.gd
│   │   └── test_ui_configuration.gd
│   ├── integration/          # Integration tests for system interactions
│   │   └── test_audio_system_integration.gd
│   └── verification/         # Verification tests for framework and assumptions
│       └── test_gut_conversion_validation.gd
├── TEST_TEMPLATE.gd          # Template for new tests
└── README.md                 # Testing documentation (being integrated)
```

### Writing Tests - Basic Structure

All tests should follow this pattern:

```gdscript
extends GutTest

# Always track created nodes for cleanup
var _created_nodes = []

func before_all():
    # Setup that runs once before all tests
    # Load any required resources/scripts
    pass

func before_each():
    # Setup that runs before each test
    pass

func after_each():
    # CRITICAL: Clean up all tracked nodes
    for node in _created_nodes:
        if is_instance_valid(node):
            # Stop audio players
            if node.has_method("stop") and node.has_method("playing"):
                if node.playing:
                    node.stop()
            # Remove from scene tree
            if node.is_inside_tree():
                node.get_parent().remove_child(node)
            node.queue_free()
    _created_nodes.clear()
    # Wait for cleanup
    await get_tree().process_frame

func test_example():
    gut.p("Testing example feature")
    
    # Create nodes
    var node = Node.new()
    _created_nodes.append(node)  # ALWAYS track created nodes
    
    # Test assertions
    assert_not_null(node, "Node should be created")
```

### Common GUT Assertions

```gdscript
# Equality
assert_eq(actual, expected, "Description")
assert_ne(actual, unexpected, "Description")

# Null checks
assert_null(value, "Should be null")
assert_not_null(value, "Should not be null")

# Boolean
assert_true(condition, "Should be true")
assert_false(condition, "Should be false")

# Collections
assert_has(array, item, "Array should contain item")
assert_does_not_have(array, item, "Array should not contain item")

# Numeric comparisons
assert_gt(value, minimum, "Should be greater than")
assert_lt(value, maximum, "Should be less than")
assert_between(value, min, max, "Should be between")

# Floating point
assert_almost_eq(actual, expected, tolerance, "Should be approximately equal")
```

### Zero Orphan Policy

Every test must clean up all created resources:

```gdscript
func test_audio_player():
    var player = AudioStreamPlayer.new()
    _created_nodes.append(player)  # Track the node
    add_child(player)              # Add to scene if needed
    
    # Test logic...
    # Cleanup handled by after_each()
```

### Test Result Management

- Test results (*.xml files) are automatically ignored by git
- Clean up test results: `rm test_results*.xml`
- Test results directory (`/test_results/`) is also ignored
- No test result files should be committed to the repository

### Key Test Areas

- **Audio Effect Properties**: Verifies AudioEffectDelay uses 'dry' not 'mix' ✓
- **Audio Bus Management**: Tests bus creation, routing, and effects
- **Sound Generation**: Tests procedural audio generation
- **UI Configuration**: Verifies slider step=0.01 for smooth control
- **System Integration**: Tests component interactions

### Command Line Options

```bash
# Specify Godot path
./run_gut_tests.sh --godot-path /path/to/godot

# Generate JUnit XML report
./run_gut_tests.sh --report

# Verbose output
./run_gut_tests.sh --verbose

# Use custom config
./run_gut_tests.sh --config my_config.json
```

### CI/CD Integration

Example GitHub Actions configuration:

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Install Godot
      run: |
        wget https://downloads.tuxfamily.org/godotengine/4.0/Godot_v4.0-stable_linux.x86_64.zip
        unzip Godot_v4.0-stable_linux.x86_64.zip
        sudo mv Godot_v4.0-stable_linux.x86_64 /usr/local/bin/godot
    
    - name: Run tests
      run: ./run_gut_tests.sh --report
    
    - name: Upload test results
      uses: actions/upload-artifact@v2
      if: always()
      with:
        name: test-results
        path: test_results.xml
```

### Configuration

The `.gutconfig.json` file controls GUT behavior:

```json
{
  "dirs": ["res://tests/gut/"],
  "prefix": "test_",
  "log_level": 1,
  "should_exit": true,
  "junit_xml_file": "test_results.xml",
  "audio_driver": "Dummy",
  "rendering_driver": "opengl3"
}
```

### Common Issues and Solutions

#### Finding Orphans
```bash
# Run with higher log level
godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -glog=3
```

#### Common Orphan Sources
- Untracked nodes
- Nodes with `_ready()` not added to scene tree  
- AudioStreamPlayer not stopped
- Custom classes creating child nodes

#### Audio Testing Notes
- AudioEffectDelay uses 'dry' property instead of 'mix'
- Always verify property names before use
- Use dummy audio driver for headless testing

### Pre-Commit Checklist

- [ ] All created nodes are tracked in `_created_nodes`
- [ ] Nodes with children are added to scene tree
- [ ] AudioStreamPlayer nodes are stopped before cleanup
- [ ] Test runs with 0 orphans
- [ ] All tests pass
- [ ] No parser errors or warnings

## Testing Patterns

### Audio Testing Pattern

```gdscript
func test_audio_manager():
    var manager = preload("res://scripts/autoloads/audio_manager.gd").new()
    _created_nodes.append(manager)
    manager._ready()  # Initialize
    
    # Test bus creation
    assert_gt(AudioServer.bus_count, 1, "Should create audio buses")
```

### UI Testing Pattern

```gdscript
func test_slider_configuration():
    var slider = HSlider.new()
    _created_nodes.append(slider)
    
    # Critical configuration
    slider.step = 0.01  # MUST be set for smooth operation
    slider.min_value = 0.0
    slider.max_value = 1.0
    
    assert_eq(slider.step, 0.01, "Step must be 0.01 for smooth control")
```

### Scene Tree Requirements

Some nodes require scene tree attachment:

```gdscript
func test_sound_generator():
    var generator = preload("res://scripts/components/sound/sound_generator.gd").new()
    _created_nodes.append(generator)
    add_child(generator)  # Required for _ready() and child nodes
    
    # Test logic...
```

### Test Categories

#### Unit Tests (`/tests/gut/unit/`)
- Test individual components in isolation
- Mock dependencies when possible
- Focus on single functionality

#### Integration Tests (`/tests/gut/integration/`)
- Test multiple components working together
- Use real implementations
- Verify system-wide behavior

### Adding New Tests

1. Copy `TEST_TEMPLATE.gd` to appropriate directory
2. Rename following convention: `test_feature_name.gd`
3. Implement test methods with `test_` prefix
4. Track all created nodes
5. Run tests and verify 0 orphans
6. Update documentation if adding new patterns

### Debugging Tests

```bash
# Enable verbose logging
./run_gut_tests.sh --verbose

# Run with visual output (not headless)
godot -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

## Testing Best Practices

### Always Test UI Controls

```gdscript
extends GutTest

func test_slider_configuration():
    var slider = HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.step = 0.01  # CRITICAL
    
    # Test step is set correctly
    assert_eq(slider.step, 0.01, "Slider step should be 0.01")
    
    # Test value changes smoothly
    slider.value = 0.5
    assert_eq(slider.value, 0.5, "Slider should accept mid-range values")
```

### Test Audio Generation

```gdscript
func test_audio_stream_generation():
    var player = AudioStreamPlayer.new()
    var generator = AudioStreamGenerator.new()
    generator.mix_rate = 44100.0
    player.stream = generator
    add_child(player)
    player.play()
    
    var playback = player.get_stream_playback()
    assert_not_null(playback, "Should get valid playback")
    
    # Generate test tone
    var frames_generated = 0
    for i in range(100):
        var value = sin(2.0 * PI * 440.0 * i / 44100.0)
        playback.push_frame(Vector2(value, value))
        frames_generated += 1
    
    assert_eq(frames_generated, 100, "Should generate all frames")
    
    player.queue_free()
```

### Effect Property Testing

```gdscript
func test_audio_effect_delay_properties():
    var delay = AudioEffectDelay.new()
    
    # Test that 'dry' property exists (not 'mix')
    var has_dry = false
    var has_mix = false
    
    for prop in delay.get_property_list():
        if prop.name == "dry":
            has_dry = true
        elif prop.name == "mix":
            has_mix = true
    
    assert_true(has_dry, "AudioEffectDelay should have 'dry' property")
    assert_false(has_mix, "AudioEffectDelay should NOT have 'mix' property")
```

### GUT Test Conventions

```gdscript
extends GutTest

func before_all():
    # Setup before all tests in this script
    pass

func before_each():
    # Setup before each test
    pass

func after_each():
    # Cleanup after each test
    pass

func after_all():
    # Cleanup after all tests
    pass

func test_example():
    # Test method must start with 'test_'
    describe("When testing something")
    
    # Arrange
    var object = MyClass.new()
    
    # Act
    var result = object.do_something()
    
    # Assert
    assert_eq(result, expected_value, "Should return expected value")
```

## Comprehensive Logging System

### Structured Log Messages

```gdscript
func _log(message: String) -> void:
    if _debug_logging:
        var timestamp = Time.get_time_string_from_system()
        print("[%s] %s: %s" % [timestamp, get_class(), message])
```

### Log Different Operations

```gdscript
# Log initialization
_log("=== AudioManager Starting Initialization ===")
_log("Godot version: " + Engine.get_version_info().string)

# Log operations with parameters
_log("Playing test tone on bus '%s': frequency=%fHz, duration=%fs" % 
    [bus_name, frequency, duration])

# Log errors clearly
_log("ERROR: Failed to get stream playback")

# Log completion
_log("Operation complete - %d items processed" % count)
```

### Log Analysis Tips

1. Look for missing expected operations (e.g., "Playing test tone" after button press)
2. Check for sequence errors (initialization happening out of order)
3. Watch for error messages or unexpected values
4. Compare initial values with expected defaults
5. Track user interactions to reproduction steps

## Common Audio Stream Issues

### Always Check Stream Playback Availability

```gdscript
var playback = player.get_stream_playback()
if playback == null:
    print("ERROR: Failed to get stream playback")
    player.queue_free()
    return
```

### Generate Audio Data Immediately

```gdscript
# Don't spread generation across frames with await
for i in range(frames_to_generate):
    var value = generate_sample(i)
    playback.push_frame(Vector2(value, value))

# Then await the finished signal
await player.finished
player.queue_free()
```

### Add Status Logs for Debugging

```gdscript
_log("Generating percussion sound...")
_log("Percussion sound generated, %d frames" % frames_to_generate)
_log("Percussion player cleaned up")
```

## Custom Debug Systems

### Debug Overlay

```gdscript
# scripts/autoloads/debug_overlay.gd
extends CanvasLayer

var stats = {}
var enabled = OS.is_debug_build()

func _ready():
    if not enabled:
        queue_free()
        return
        
    var debug_panel = Panel.new()
    debug_panel.anchor_right = 0.2
    debug_panel.anchor_bottom = 1.0
    
    var label = Label.new()
    label.name = "StatsLabel"
    label.anchor_right = 1.0
    label.anchor_bottom = 1.0
    label.text = "Debug Stats:"
    
    debug_panel.add_child(label)
    add_child(debug_panel)

func _process(_delta):
    if not enabled:
        return
        
    # Update FPS
    stats["FPS"] = Engine.get_frames_per_second()
    
    # Update dynamic stats
    if get_node_or_null("/root/Level/Player"):
        var player = get_node("/root/Level/Player")
        stats["Player Position"] = player.global_position
        stats["Player Health"] = player.health
    
    # Format and display stats
    var stats_text = "Debug Stats:\n"
    for key in stats.keys():
        stats_text += key + ": " + str(stats[key]) + "\n"
    
    $Panel/StatsLabel.text = stats_text
```

### Performance Monitor

```gdscript
extends Node

@export var show_performance: bool = true
var performance_label: Label

func _ready():
    if show_performance and OS.is_debug_build():
        performance_label = Label.new()
        performance_label.add_theme_font_size_override("font_size", 16)
        get_tree().current_scene.add_child(performance_label)

func _process(_delta):
    if show_performance and performance_label:
        var fps = Engine.get_frames_per_second()
        var memory = OS.get_static_memory_usage() / 1024.0 / 1024.0
        var objects = Performance.get_monitor(Performance.OBJECT_COUNT)
        
        performance_label.text = "FPS: %d | Memory: %.1f MB | Objects: %d" % [fps, memory, objects]
```

## Common Pitfalls to Avoid

1. **Missing `step` property on sliders** (causes binary behavior)
2. **Using wrong property names** (e.g., 'mix' on AudioEffectDelay)
3. **Incorrect async handling** in audio generation
4. **Missing null checks** for stream playback
5. **Assuming default values** without explicit setting

## Debug Commands

Create a debug console for runtime testing:

```gdscript
extends Node

var debug_commands = {
    "heal": _cmd_heal,
    "damage": _cmd_damage,
    "teleport": _cmd_teleport,
    "spawn": _cmd_spawn
}

func execute_command(cmd_string: String):
    var parts = cmd_string.split(" ")
    var command = parts[0]
    var args = parts.slice(1)
    
    if debug_commands.has(command):
        debug_commands[command].call(args)
    else:
        print("Unknown command: " + command)

func _cmd_heal(args: Array):
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.health = player.max_health
        print("Player healed")

func _cmd_damage(args: Array):
    if args.size() < 1:
        print("Usage: damage <amount>")
        return
        
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.take_damage(float(args[0]))
        print("Player damaged by " + args[0])
```

## Using Context7 for Debugging

When debugging Godot-specific issues, use Context7 to look up accurate documentation:

```
# Step 1: Get Godot library ID
mcp__context7-mcp__resolve-library-id:
  libraryName: "godot"

# Step 2: Look up specific class or feature
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <returned_id>
  topic: "get_stream_playback"  # Look up specific methods
  tokens: 5000

# Example: Debugging signal issues
mcp__context7-mcp__get-library-docs:
  context7CompatibleLibraryID: <returned_id>
  topic: "signal connect"
  tokens: 8000
```

This helps verify:
- Method signatures and return types
- Property names and types
- Signal parameters
- Class inheritance hierarchies
- Available constants and enums

## Best Practices

1. **Test Early and Often**: Don't wait until the end to start testing
2. **Use Assertions**: Make your tests clear about what they expect
3. **Test Edge Cases**: Don't just test the happy path
4. **Keep Tests Simple**: Each test should verify one thing
5. **Use Descriptive Names**: Test names should explain what they test
6. **Clean Up Resources**: Always free nodes created in tests
7. **Log Comprehensively**: More information is better when debugging
8. **Verify with Context7**: Always check official docs for accurate API information