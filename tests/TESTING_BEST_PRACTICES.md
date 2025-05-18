# Beat Racer Testing Best Practices

## Overview
This guide ensures consistent, clean test implementation that prevents memory leaks and orphan nodes.

## 1. Core Testing Pattern

Every test file should follow this structure:

```gdscript
extends GutTest

# Always track created nodes
var _created_nodes = []

# Initialize any required classes
func before_all():
    # Load scripts/resources needed for all tests
    pass

# Setup for each test
func before_each():
    # Initialize test-specific data
    pass

# CRITICAL: Proper cleanup
func after_each():
    # Clean up all tracked nodes
    for node in _created_nodes:
        if is_instance_valid(node):
            if node.has_method("stop") and node.has_method("playing"):
                if node.playing:
                    node.stop()
            if node.is_inside_tree():
                node.get_parent().remove_child(node)
            node.queue_free()
    _created_nodes.clear()
    # Wait for nodes to be freed
    await get_tree().process_frame

# Individual test methods
func test_example():
    var node = Node.new()
    _created_nodes.append(node)  # ALWAYS track created nodes
    # ... test logic ...
```

## 2. Audio-Specific Testing

### AudioStreamPlayer Nodes
```gdscript
func test_audio_player():
    var player = AudioStreamPlayer.new()
    _created_nodes.append(player)
    add_child(player)  # Add to scene tree if needed
    
    # Test logic...
    
    # No manual cleanup needed - after_each() handles it
```

### AudioManager Testing
```gdscript
func test_audio_manager():
    var manager = AudioManager.new()
    _created_nodes.append(manager)
    manager._ready()  # Initialize
    
    # Test logic...
```

### Sound Generator Testing
```gdscript
func test_sound_generator():
    var generator = SoundGenerator.new()
    _created_nodes.append(generator)
    add_child(generator)  # Required: SoundGenerator creates child nodes
    
    # Test logic...
```

## 3. UI Control Testing

### Slider Testing
```gdscript
func test_sliders():
    var sliders = []
    for i in range(3):
        var slider = HSlider.new()
        slider.step = 0.01  # CRITICAL for smooth operation
        _created_nodes.append(slider)
        sliders.append(slider)
        add_child(slider)
    
    # Test logic...
```

## 4. Common Pitfalls to Avoid

### ❌ DON'T: Create nodes without tracking
```gdscript
# BAD - Creates orphan
func test_bad():
    var node = Node.new()
    # Test logic...
    node.queue_free()  # Might not complete before test ends
```

### ✅ DO: Always track and use after_each
```gdscript
# GOOD - Proper cleanup
func test_good():
    var node = Node.new()
    _created_nodes.append(node)
    # Test logic...
    # Cleanup handled by after_each()
```

### ❌ DON'T: Forget scene tree for complex nodes
```gdscript
# BAD - SoundGenerator won't initialize child nodes
func test_bad_generator():
    var gen = SoundGenerator.new()
    _created_nodes.append(gen)
    # Child nodes won't be created/tracked
```

### ✅ DO: Add to scene tree when needed
```gdscript
# GOOD - Ensures proper initialization
func test_good_generator():
    var gen = SoundGenerator.new()
    _created_nodes.append(gen)
    add_child(gen)  # Triggers _ready() and child creation
```

## 5. Running Tests

### Basic Test Run
```bash
./run_gut_tests.sh
```

### With JUnit Report
```bash
./run_gut_tests.sh --report
```

### Check for Orphans
Always verify no orphans appear in test output:
```
Total orphans in run: 0
```

## 6. Pre-Commit Checklist

Before committing new tests:

- [ ] All created nodes are tracked in `_created_nodes`
- [ ] Nodes with children are added to scene tree
- [ ] AudioStreamPlayer nodes are stopped before cleanup
- [ ] Test runs with 0 orphans
- [ ] All tests pass
- [ ] No parser errors or warnings

## 7. Test Categories

### Unit Tests (`/tests/gut/unit/`)
- Test individual components in isolation
- Mock dependencies when possible
- Focus on single functionality

### Integration Tests (`/tests/gut/integration/`)
- Test multiple components working together
- Use real implementations
- Verify system-wide behavior

### Verification Tests (`/tests/gut/verification/`)
- Validate test framework functionality
- Ensure testing tools work correctly
- Meta-tests for the test suite

## 8. Extending Tests

When adding new features:

1. Create test file following naming convention: `test_feature_name.gd`
2. Use the core testing pattern template
3. Add to appropriate category folder
4. Run tests to ensure 0 orphans
5. Update test documentation if needed

## 9. Debugging Test Issues

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

## 10. Continuous Improvement

- Review test patterns quarterly
- Update this guide with new discoveries
- Share knowledge with team
- Maintain 0 orphan policy

---

Remember: Clean tests = Clean codebase = Happy developers! 🎮✨