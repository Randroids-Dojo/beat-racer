# Beat Racer Audio Test Framework

This comprehensive test framework ensures the audio system functions correctly and follows the guidelines in CLAUDE.md.

## Test Structure

```
tests/
├── test_runner.gd              # Main test orchestrator
├── unit/                       # Unit tests for individual components
│   ├── test_audio_effects.gd   # Audio effect property tests
│   └── test_audio_generation.gd # Audio stream generation tests
├── integration/                # Integration tests
│   └── test_audio_system_integration.gd
├── verification/               # Property verification tests
│   └── test_effect_property_verification.gd
├── ui/                        # UI configuration tests
│   └── test_ui_configuration.gd
└── README.md                  # This file
```

## Key Test Areas

### 1. Audio Effect Properties
- Verifies correct properties exist for each effect type
- **Critical**: Confirms AudioEffectDelay doesn't have 'mix' property (uses dry/wet instead)
- Tests property access and value setting

### 2. Audio Stream Generation
- Tests AudioStreamGenerator configuration
- Verifies proper stream playback setup
- Tests frame generation and buffer handling

### 3. UI Configuration
- **Critical**: Tests slider step values (must be 0.01 for smooth control)
- Verifies default values are appropriate
- Tests common configuration errors

### 4. Integration Testing
- Tests complete audio system initialization
- Verifies bus creation and routing
- Tests effect chains and interactions

## Running Tests

### Run All Tests
```bash
./build_and_test.sh
```

### Run with Report Generation
```bash
./build_and_test.sh --report
```

### Run Individual Test
```bash
godot --headless --path . --script res://tests/test_runner.gd
```

## Important Findings

### AudioEffectDelay Properties
- ❌ Does NOT have 'mix' property
- ✅ Uses 'dry' property instead
- ✅ Has tap1/tap2 and feedback controls

### UI Slider Configuration
- **Must** set `step = 0.01` for smooth operation
- Without proper step, sliders show binary (0/1) behavior
- Always configure in code as failsafe

### Best Practices
1. Always use Context7 to verify properties before implementation
2. Test property existence before setting values
3. Configure UI controls programmatically
4. Log all operations for debugging
5. Test after every major change

## Test Output

Tests provide detailed output including:
- Property listings for all effects
- Pass/fail status for each test
- Specific error messages when properties don't match expectations
- Verification that CLAUDE.md guidelines are followed

## Adding New Tests

1. Create test file in appropriate directory (unit/integration/etc)
2. Extend SceneTree for standalone execution
3. Follow naming convention: `test_*.gd`
4. Update test_runner.gd to include new test
5. Add to build_and_test.sh

## Common Issues and Solutions

### Issue: Slider only shows 0 or 1
**Cause**: Missing or incorrect step value
**Solution**: Set `slider.step = 0.01`

### Issue: AudioEffectDelay mix property error
**Cause**: Attempting to use non-existent 'mix' property
**Solution**: Use 'dry' property instead

### Issue: Audio stream not playing
**Cause**: Incorrect buffer handling or async issues
**Solution**: Generate all frames immediately, then await finished signal

## Maintenance

- Regularly run tests after implementing new features
- Update tests when Godot API changes
- Document any new findings in this README
- Keep CLAUDE.md synchronized with test results