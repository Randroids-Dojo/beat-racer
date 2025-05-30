# Story 015: Vehicle Feel Improvements - Complete Documentation

## Overview
Story 015 focused on polishing vehicle controls and physics for better feel. This story implemented smooth acceleration/deceleration curves, vehicle banking on turns, momentum-based movement, and visual effects to enhance the driving experience.

## Implementation Details

### 1. Enhanced Vehicle Class (`EnhancedVehicle`)
Created a new vehicle class that extends the base `Vehicle` class with improved physics and visual effects.

**Key Features:**
- **Acceleration/Deceleration Curves**: Speed-dependent acceleration that feels more natural
- **Turn Resistance**: Harder to turn at high speeds for realism
- **Momentum Preservation**: Vehicles maintain momentum through turns
- **Slip Angle Calculation**: Realistic drift mechanics based on angle between velocity and heading
- **Visual Banking**: Vehicles lean into turns
- **Particle Effects**: Tire smoke when drifting, speed lines at high velocity
- **State Machine**: Tracks vehicle states (Idle, Accelerating, Cruising, Braking, Drifting)

### 2. Physics Improvements

#### Acceleration Curves
- High acceleration at low speeds that tapers off
- Deceleration increases with speed for realistic braking
- Turn resistance increases with speed

#### Momentum System
- Preserves vehicle momentum through turns
- Adjustable momentum preservation factor
- Creates natural drift behavior

#### Slip Angle Physics
- Calculates angle between velocity and vehicle heading
- Triggers drift state when slip exceeds threshold
- Applies lateral slip for realistic sliding

### 3. Visual Enhancements

#### Vehicle Banking
- Vehicles visually lean into turns
- Banking angle proportional to turn rate and speed
- Extra banking when drifting

#### Particle Systems
- **Tire Smoke**: 4 emitters (one per wheel) that activate during drift
- **Speed Particles**: Trail particles that emit at high speeds
- **Trail Effect**: Integrated `SoundReactiveTrail` for visual feedback

#### Screen Effects
- Camera shake during acceleration
- Impact shake on collisions
- Speed-based shake at high velocities

### 4. State Machine
Tracks vehicle behavior with states:
- **IDLE**: Vehicle at rest
- **ACCELERATING**: Throttle applied, gaining speed
- **CRUISING**: Maintaining speed without input
- **BRAKING**: Decelerating
- **DRIFTING**: High slip angle detected
- **AIRBORNE**: (Reserved for future jumps)

### 5. Configuration Options

#### Physics Parameters
- `acceleration_curve`: Curve defining acceleration vs speed
- `deceleration_curve`: Curve defining braking power vs speed
- `turn_resistance_at_speed`: Curve for steering resistance
- `momentum_preservation`: How much momentum to preserve (0.8-0.99)
- `slip_angle_threshold`: Degrees before drift begins
- `max_slip_angle`: Maximum allowed slip

#### Visual Parameters
- `enable_banking`: Toggle vehicle leaning
- `max_bank_angle`: Maximum lean angle in degrees
- `bank_speed`: How quickly to bank
- `bank_recovery_speed`: How quickly to return to neutral

#### Effect Parameters
- `enable_screen_shake`: Toggle camera shake
- `enable_tire_smoke`: Toggle drift smoke
- `enable_speed_particles`: Toggle speed lines

## Files Created/Modified

### New Files
1. **`scripts/components/vehicle/enhanced_vehicle.gd`**
   - Main enhanced vehicle implementation
   - Extends base Vehicle class
   - Implements all new physics and effects

2. **`scenes/test/vehicle_feel_demo.gd`**
   - Interactive demo scene script
   - UI controls for tweaking parameters
   - Physics presets (Arcade, Realistic, Drift, Heavy, Responsive)

3. **`scenes/test/vehicle_feel_demo.tscn`**
   - Demo scene with track and enhanced vehicle
   - UI panel for real-time adjustments
   - Camera setup for following vehicle

4. **`run_vehicle_feel_demo.sh`**
   - Convenience script to launch demo

5. **`tests/gut/unit/test_enhanced_vehicle.gd`**
   - Unit tests for enhanced vehicle physics
   - Tests state machine, curves, particles, etc.

6. **`tests/gut/integration/test_enhanced_vehicle_integration.gd`**
   - Integration tests with track system
   - Tests complete driving scenarios

### Modified Files
1. **`scripts/components/visual/sound_reactive_trail.gd`**
   - Fixed Godot 4 compatibility issue with `cap_mode`

## Usage Examples

### Creating an Enhanced Vehicle
```gdscript
var vehicle = preload("res://scripts/components/vehicle/enhanced_vehicle.gd").new()
vehicle.enable_banking = true
vehicle.enable_tire_smoke = true
vehicle.max_bank_angle = 15.0
add_child(vehicle)
```

### Adjusting Physics Feel
```gdscript
# Arcade feel
vehicle.momentum_preservation = 0.95
vehicle.turn_speed = 4.0
vehicle.drift_factor = 0.98

# Realistic feel
vehicle.momentum_preservation = 0.88
vehicle.turn_speed = 2.5
vehicle.drift_factor = 0.92

# Drift-focused
vehicle.momentum_preservation = 0.82
vehicle.slip_angle_threshold = 10.0
vehicle.drift_factor = 0.85
```

### Responding to Vehicle States
```gdscript
vehicle.state_changed.connect(_on_vehicle_state_changed)
vehicle.drift_started.connect(_on_drift_started)
vehicle.impact_occurred.connect(_on_impact)

func _on_vehicle_state_changed(old_state, new_state):
    print("Vehicle state: ", vehicle.get_state_name())

func _on_drift_started():
    # Trigger drift scoring, effects, etc.
    pass
```

## Demo Controls
- **Arrow Keys/WASD**: Drive the vehicle
- **R**: Reset position
- **Tab**: Toggle UI panel
- **1-5**: Apply physics presets
- **Space**: Handbrake (for testing drift)

## Testing
Run the vehicle feel demo:
```bash
./run_vehicle_feel_demo.sh
```

Run unit tests:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut/unit/test_enhanced_vehicle.gd
```

## Performance Considerations
- Particle systems are pooled and reused
- Trail points are limited and expire over time
- Visual effects can be toggled for performance
- Physics calculations are optimized for 60 FPS

## Future Enhancements
- Jump/airborne physics
- Surface-specific handling (ice, dirt, etc.)
- Damage model affecting performance
- More sophisticated tire model
- Engine sound synthesis based on RPM

## Story Completion
Story 015 has been successfully implemented with:
- ✅ Subtle drift for smoother turning
- ✅ Acceleration/deceleration curves
- ✅ Screen shake and feedback effects
- ✅ Vehicle state machine for different driving modes
- ✅ Comprehensive test coverage
- ✅ Interactive demo for testing feel

The enhanced vehicle provides a much more satisfying driving experience with realistic physics, visual feedback, and extensive customization options.