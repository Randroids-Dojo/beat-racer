# GUT Testing Guide for Beat Racer

This guide explains how to use the Godot Unit Test (GUT) framework for testing the Beat Racer project.

## Overview

Beat Racer's test suite has been converted to use GUT, providing:
- Standardized test structure
- Better assertion methods
- Command line execution support
- CI/CD integration capabilities
- JUnit XML report generation

## Directory Structure

```
tests/
├── gut_converted/           # GUT-compatible tests
│   ├── test_audio_effect_properties.gd
│   ├── test_audio_system_integration.gd
│   ├── test_audio_generation.gd
│   └── test_ui_configuration.gd
├── unit/                    # Original unit tests (to be converted)
├── integration/             # Original integration tests (to be converted)
└── GUT_TESTING_GUIDE.md     # This file
```

## Command Line Execution

### Basic Test Run

Run all tests using the shell script:
```bash
./run_gut_tests.sh
```

### Advanced Options

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

### Direct GUT Command

Run tests directly with Godot:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

### Running Specific Tests

To run a specific test file:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut_converted/test_audio_effect_properties.gd
```

To run a specific test method:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gunit_test_name=test_audio_effect_delay_properties
```

## Writing GUT Tests

### Basic Test Structure

```gdscript
extends GutTest

func before_all():
    # Setup that runs once before all tests
    pass

func before_each():
    # Setup that runs before each test
    pass

func after_each():
    # Cleanup that runs after each test
    pass

func after_all():
    # Cleanup that runs once after all tests
    pass

func test_example():
    describe("What this test validates")
    
    # Your test code here
    assert_eq(1 + 1, 2, "Basic math should work")
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
assert_gte(value, minimum, "Should be greater than or equal")
assert_lt(value, maximum, "Should be less than")
assert_lte(value, maximum, "Should be less than or equal")
assert_between(value, min, max, "Should be between min and max")

# Floating point
assert_almost_eq(actual, expected, tolerance, "Should be approximately equal")

# Type checking
assert_is(object, expected_type, "Should be of type")
```

### Test Categories

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test interactions between components
3. **Verification Tests**: Validate assumptions about Godot's behavior

## Converting Legacy Tests

To convert existing tests to GUT:

1. Change the base class:
   ```gdscript
   # Old
   extends SceneTree
   
   # New
   extends GutTest
   ```

2. Rename the initialization method:
   ```gdscript
   # Old
   func _init():
   
   # New
   func before_all():
   ```

3. Prefix test methods with `test_`:
   ```gdscript
   # Old
   func check_audio_properties():
   
   # New
   func test_audio_properties():
   ```

4. Replace custom assertions:
   ```gdscript
   # Old
   if property_exists:
       print("✓ Property exists")
   else:
       print("✗ Property missing")
   
   # New
   assert_true(property_exists, "Property should exist")
   ```

5. Remove manual result tracking:
   ```gdscript
   # Old
   test_results[test_name]["passed"] += 1
   
   # New
   # GUT handles this automatically
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
        path: test_results/
```

### GitLab CI Example

```yaml
test:
  image: barichello/godot-ci:4.0
  script:
    - ./run_gut_tests.sh --report
  artifacts:
    when: always
    reports:
      junit: test_results/junit_report.xml
    paths:
      - test_results/
```

## Best Practices

1. **Use descriptive test names**: Test method names should clearly indicate what they test
2. **One assertion per test**: When possible, keep tests focused on a single assertion
3. **Use `describe()`**: Add context to your tests with descriptive messages
4. **Clean up resources**: Always clean up created nodes in `after_each()`
5. **Test edge cases**: Include tests for boundary conditions and error cases
6. **Keep tests fast**: Avoid long delays or complex setup in tests
7. **Use parameterized tests**: For testing multiple inputs, use GUT's parameterized test features

## Troubleshooting

### Common Issues

1. **Tests not found**: Ensure test files are in the configured directory and follow naming conventions
2. **Import errors**: Verify all dependencies are available in the test environment
3. **Timeout issues**: Increase timeout in config if tests need more time
4. **Audio driver issues**: Tests use dummy audio driver to avoid hardware dependencies

### Debug Options

```bash
# Enable verbose logging
./run_gut_tests.sh --verbose

# Run with visual output (not headless)
godot -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

## Configuration Reference

The `.gutconfig.json` file controls GUT behavior:

```json
{
  "dirs": ["res://tests/gut_converted/"],  // Test directories
  "prefix": "test_",                       // Test file prefix
  "log_level": 1,                         // 0=quiet, 1=normal, 2=verbose
  "should_exit": true,                    // Exit after tests
  "junit_xml_file": "test_results.xml",   // JUnit output
  "audio_driver": "Dummy",                // Audio driver for tests
  "rendering_driver": "opengl3"           // Rendering driver
}
```

## Additional Resources

- [GUT Documentation](https://github.com/bitwes/Gut/wiki)
- [Godot Testing Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/testing.html)
- [Beat Racer Testing Requirements](../TESTING.md)