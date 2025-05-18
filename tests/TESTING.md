# Beat Racer Testing Documentation

## Overview

This document describes the comprehensive testing approach for the Beat Racer audio system, following the guidelines established in CLAUDE.md.

## Key Test Requirements

### 1. Audio Effect Property Verification

As documented in CLAUDE.md, always verify effect properties before using them:

- **AudioEffectDelay does NOT have a 'mix' property** - use 'dry' instead
- Different audio effects have different property names for similar concepts
- Use Context7 documentation or verification helpers to check properties

### 2. UI Configuration Testing

Sliders MUST have appropriate step values:
```gdscript
slider.step = 0.01  # Critical for smooth operation
```

Without proper step values, sliders may only show 0 or 1 values.

### 3. Audio Stream Generation

Test audio stream generation with proper error checking:
- Always check if stream playback is available
- Generate all audio frames immediately (not across multiple frames)
- Add comprehensive logging for debugging

## Test Structure

### Comprehensive Test (`test_comprehensive_audio.gd`)

Our main test suite verifies:

1. **Audio Effect Properties**
   - Confirms AudioEffectDelay lacks 'mix' property
   - Verifies correct properties exist (tap1_active, feedback_active, dry)
   
2. **Audio Bus Setup**
   - Tests creation of all required buses
   - Verifies effects are added to buses
   
3. **Volume Controls**
   - Tests dB and linear volume settings
   - Verifies conversion between formats
   
4. **Effect Verification**
   - Tests property_exists() helper function
   - Validates property checking utilities
   
5. **UI Configuration**
   - Tests slider step configuration
   - Verifies precise value handling

### Running Tests

Basic test run:
```bash
./build_and_test.sh
```

With test report:
```bash
./build_and_test.sh --report
```

Individual test:
```bash
godot --headless --path . --script res://tests/test_comprehensive_audio.gd
```

## Expected Results

The comprehensive test provides detailed output with:
- ✓ Pass indicators for successful tests
- ✗ Fail indicators with explanations
- Overall success rate percentage
- Detailed logging for debugging

## Common Issues and Solutions

### 1. Audio Bus Not Found
- **Issue**: Buses not created in test environment
- **Solution**: Ensure AudioManager._ready() is called in tests

### 2. Property Access Errors
- **Issue**: Trying to access non-existent properties
- **Solution**: Always use verification helpers before property access

### 3. Slider Binary Behavior
- **Issue**: Sliders only showing 0 or 1
- **Solution**: Set step = 0.01 on all continuous sliders

### 4. Headless Mode Limitations
- **Issue**: Some methods not available in SceneTree
- **Solution**: Use simple test structure without complex scene operations

## Best Practices

1. **Always Verify Properties First**
   ```gdscript
   if property_exists(effect, "property_name"):
       effect.property_name = value
   ```

2. **Use Comprehensive Logging**
   ```gdscript
   _log("Operation: parameter=%s, result=%s" % [param, result])
   ```

3. **Test Edge Cases**
   - Min/max values
   - Invalid inputs
   - Rapid operations

4. **Document Test Failures**
   - Include expected vs actual values
   - Provide context for debugging

## Future Improvements

1. Add performance benchmarking for audio generation
2. Create automated UI interaction tests
3. Add stress tests for rapid sound generation
4. Implement integration tests with actual game scenes