# Beat Racer Test Suite

## Overview

The Beat Racer test suite uses the Godot Unit Test (GUT) framework with a zero-orphan policy for clean, maintainable testing.

## Directory Structure

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
├── TESTING_BEST_PRACTICES.md # Testing patterns and guidelines
├── TEST_TEMPLATE.gd          # Template for new tests
├── GUT_TESTING_GUIDE.md      # Comprehensive GUT testing guide
└── README.md                 # This file
```

## Current Status

✅ **Production-ready test suite**
- All tests use GUT test structure
- Command line execution supported
- CI/CD ready with JUnit XML reports
- **Zero orphan policy** - all tests run clean
- Comprehensive testing patterns documented
- Test template for consistent new tests

### Test Categories

#### Unit Tests (`gut/unit/`)
- **test_audio_effect_properties.gd**: Validates audio effect properties and behaviors
- **test_audio_generation.gd**: Tests audio stream generation capabilities
- **test_ui_configuration.gd**: Verifies UI control configurations (especially sliders)

#### Integration Tests (`gut/integration/`)
- **test_audio_system_integration.gd**: Tests complete audio system integration

#### Verification Tests (`gut/verification/`)
- **test_gut_conversion_validation.gd**: Validates GUT framework functionality

## Running Tests

### Quick Start
```bash
# Run all tests
./run_gut_tests.sh

# Run with JUnit XML report
./run_gut_tests.sh --report

# Run specific test category
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut/unit/
```

### Detailed Documentation
See [GUT_TESTING_GUIDE.md](GUT_TESTING_GUIDE.md) for comprehensive testing information.

## Key Files

- **`.gutconfig.json`**: GUT configuration file
- **`run_gut_tests.sh`**: Shell script for running tests (CI/CD compatible)
- **`GUT_TESTING_GUIDE.md`**: Complete testing guide

## Testing Focus Areas

The Beat Racer test suite focuses on:

1. **Audio Effect Properties**: Verifying Godot audio effects have expected properties
2. **Audio Bus Management**: Testing bus creation, routing, and effects
3. **Sound Generation**: Validating procedural audio generation
4. **UI Configuration**: Ensuring proper slider configuration (critical for smooth control)
5. **System Integration**: Testing interactions between components

## Important Notes

- AudioEffectDelay uses 'dry' property instead of 'mix' (verified in tests)
- Sliders must have step=0.01 for smooth operation
- Tests use dummy audio driver for headless execution
- All tests are designed for command line execution

## CI/CD Integration

The test suite is designed for CI/CD pipelines:
- Headless execution support
- JUnit XML report generation
- Exit codes for success/failure
- Configurable verbosity levels

See `run_gut_tests.sh` for integration examples.

## Contributing

When adding new tests:
1. Copy `TEST_TEMPLATE.gd` to start a new test file
2. Follow patterns in `TESTING_BEST_PRACTICES.md`
3. Track all created nodes for proper cleanup
4. Place tests in appropriate category folder
5. Run tests and ensure 0 orphans
6. Update this README if adding new test categories

## Zero Orphan Policy

This test suite maintains a strict zero orphan policy:
- All created nodes must be tracked
- Proper cleanup in `after_each()` functions
- AudioStreamPlayer nodes must be stopped
- Nodes with `_ready()` should be added to scene tree
- Always await frame processing for cleanup

See `TESTING_BEST_PRACTICES.md` for detailed patterns.