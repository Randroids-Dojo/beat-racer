# Beat Racer Testing Guide

## Overview

The Beat Racer test suite uses the Godot Unit Test (GUT) framework with a zero-orphan policy for clean, maintainable testing. This guide consolidates all testing information into a single reference.

## Directory Structure

```
tests/
├── gut/                       # All GUT-based tests
│   ├── unit/                 # Unit tests for individual components
│   │   ├── test_audio_effect_properties.gd
│   │   ├── test_audio_generation.gd
│   │   └── test_ui_configuration.gd
│   └── integration/          # Integration tests for system interactions
│       └── test_audio_system_integration.gd
├── TEST_TEMPLATE.gd          # Template for new tests
└── README.md                 # This comprehensive guide
```

## Quick Start

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

## Writing Tests

### Basic Test Structure

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

### Common Assertions

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

## Best Practices

### 1. Zero Orphan Policy

Every test must clean up all created resources:

```gdscript
func test_audio_player():
    var player = AudioStreamPlayer.new()
    _created_nodes.append(player)  # Track the node
    add_child(player)              # Add to scene if needed
    
    # Test logic...
    # Cleanup handled by after_each()
```

### 2. Audio Testing

```gdscript
func test_audio_manager():
    var manager = preload("res://scripts/autoloads/audio_manager.gd").new()
    _created_nodes.append(manager)
    manager._ready()  # Initialize
    
    # Test bus creation
    assert_gt(AudioServer.bus_count, 1, "Should create audio buses")
```

### 3. UI Testing

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

### 4. Scene Tree Requirements

Some nodes require scene tree attachment:

```gdscript
func test_sound_generator():
    var generator = preload("res://scripts/components/sound/sound_generator.gd").new()
    _created_nodes.append(generator)
    add_child(generator)  # Required for _ready() and child nodes
    
    # Test logic...
```

## Test Categories

### Unit Tests (`/tests/gut/unit/`)
- Test individual components in isolation
- Mock dependencies when possible
- Focus on single functionality

### Integration Tests (`/tests/gut/integration/`)
- Test multiple components working together
- Use real implementations
- Verify system-wide behavior

## Command Line Options

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

## CI/CD Integration

### GitHub Actions Example

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

## Configuration

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

## Common Issues and Solutions

### Finding Orphans
```bash
# Run with higher log level
godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -glog=3
```

### Common Orphan Sources
- Untracked nodes
- Nodes with `_ready()` not added to scene tree  
- AudioStreamPlayer not stopped
- Custom classes creating child nodes

### Audio Testing Notes
- AudioEffectDelay uses 'dry' property instead of 'mix'
- Always verify property names before use
- Use dummy audio driver for headless testing

## Adding New Tests

1. Copy `TEST_TEMPLATE.gd` to appropriate directory
2. Rename following convention: `test_feature_name.gd`
3. Implement test methods with `test_` prefix
4. Track all created nodes
5. Run tests and verify 0 orphans
6. Update documentation if adding new patterns

## Debugging

```bash
# Enable verbose logging
./run_gut_tests.sh --verbose

# Run with visual output (not headless)
godot -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

## Pre-Commit Checklist

- [ ] All created nodes are tracked in `_created_nodes`
- [ ] Nodes with children are added to scene tree
- [ ] AudioStreamPlayer nodes are stopped before cleanup
- [ ] Test runs with 0 orphans
- [ ] All tests pass
- [ ] No parser errors or warnings

## Additional Resources

- [GUT Documentation](https://github.com/bitwes/Gut/wiki)
- [Godot Testing Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/testing.html)