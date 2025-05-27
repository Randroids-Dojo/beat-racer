# BEAT RACER - DEVELOPMENT BACKLOG

## Overview

Beat Racer is a game where players create music by driving vehicles on a track. Lane position determines sound generation, creating musical loops that build into complete tracks. This backlog prioritizes:

1. Desktop as primary platform
2. Basic sound generation first, then driving mechanics
3. Single vehicle implementation for the MVP
4. Clear, achievable tasks focused on the core game loop

---

## EPIC 1: AUDIO ENGINE FOUNDATION
**Priority: 1** 
Establish the basic audio system that will allow sound generation based on lane position.

### Stories:
- [x] **Story 001: Audio Bus Setup** ✓ COMPLETE  
  *Implement audio bus structure with basic effects for different sound types*
  - Create dedicated buses for melody, bass, percussion tracks
  - Set up basic effects (reverb, delay) on appropriate buses
  - Implement global volume controls
  
  **Implementation Notes:**
  - Created comprehensive audio bus system with 5 buses: Master, Melody, Bass, Percussion, SFX
  - Implemented volume controls with both dB and linear value handling
  - Added mute/solo functionality for each audio bus
  - Applied appropriate audio effects to each bus:
	- Melody: Reverb, Chorus
	- Bass: Distortion, Limiter
	- Percussion: Delay, Filter
	- SFX: Chorus, Compressor
  - Added test tone generation system for each bus
  - Implemented effect toggle controls for runtime configuration
  - Created visual feedback for audio bus states
  - Verified proper signal flow and bus routing
  - Full GUT test coverage for all audio functionality

- [x] **Story 002: Lane-based Sound Generator** ✓ COMPLETE
  *Create system to generate different sounds based on lane position*
  - Implement AudioStreamGenerator for procedural sound
  - Create sound mapping system for different lanes
  - Support basic waveforms (sine, square, triangle)
  - Add basic musical scale support
  
  **Implementation Notes:**
  - Created LaneSoundSystem class to manage lane-to-sound mapping
  - Implemented configurable sound parameters per lane (waveform, octave, scale degree)
  - Supports three lanes (Left, Center, Right) with independent sound generation
  - Integrated with existing AudioManager and audio bus system
  - Added resource-based configuration system (LaneSoundConfig, LaneMappingResource)
  - Created comprehensive test suite (unit and integration tests)
  - Built demonstration scene for testing lane sound functionality
  - Features include:
	- Real-time lane switching with audio feedback
	- Configurable waveforms (sine, square, triangle, saw)
	- Musical scale support (major, minor, pentatonic, blues, chromatic)
	- Independent volume and octave control per lane
	- Multi-lane simultaneous playback capability
	- Global root note and scale settings
  - Related stories: Forms foundation for Story 003 (Beat Sync) and Story 004 (Sound Playback Test)

- [x] **Story 003: Beat Synchronization System** ✓ COMPLETE
  *Build a system to keep sounds aligned to a consistent beat*
  - Implement BPM-based timing controller
  - Create beat/measure tracking system
  - Add quantization for aligning sounds to beat grid
  - Build visual indicators for beat visualization
  
  **Implementation Notes:**
  - Created BeatManager autoload for core beat tracking and timing
  - Implemented PlaybackSync system for audio synchronization
  - Built BeatEventSystem for quantized event scheduling
  - Added visual components (BeatIndicator, BeatVisualizationPanel)
  - Features include:
	- BPM support from 60-240 with real-time adjustment
	- Multiple quantization levels (beat, half-beat, measure, etc.)
	- Automatic sync detection and correction
	- Metronome functionality with audio feedback
	- Visual beat indicators with customizable appearance
	- Event system supporting delayed and repeating callbacks
	- Integration with lane sound system for rhythm gameplay
  - Created comprehensive test suite for all components
  - Built demo scene showcasing complete system integration
  - Full documentation in docs/beat-synchronization.md
  - Related stories: This system integrates with Story 002 (Lane-based Sound) and Story 004 (Sound Playback Test)

- [x] **Story 004: Simple Sound Playback Test** ✓ COMPLETE
  *Create a standalone test for playing sounds through the systems above*
  - Add keyboard input to trigger lane sounds
  - Implement visual feedback when sounds play
  - Support adjustable BPM  
  - Allow for basic sound parameter adjustments
  
  **Implementation Notes:**
  - Created comprehensive test scene (`simple_sound_playback_test.tscn`)
  - Keyboard controls: Q/W/E for lanes, SPACE for play/stop, ESC to clear
  - Visual indicators with lane-specific colors and shapes
  - Adjustable BPM slider (60-240 range)
  - Sound parameters: waveform, volume, octave, scale selection
  - Beat visualization panel integration
  - Full GUT integration test coverage
  - Created convenience script `run_simple_sound_test.sh`
  - Documented in `/docs/testing-debugging.md`

---

## EPIC 2: TRACK AND VEHICLE CORE
**Priority: 2**
Create the fundamental track environment and basic vehicle with functional lane detection.

### Stories:
- [x] **Story 005: Basic Track Layout** ✓ COMPLETE  
  *Implement a simple oval track with three lanes*
  - Create track with clear visual distinction between lanes
  - Add start/finish line indicator
  - Implement beat markers along track
  - Support track boundaries
  
  **Implementation Notes:**
  - Created TrackGeometry class with oval track generation
  - Implemented three lanes with visual dividers (dashed white, solid yellow center)
  - Added StartFinishLine with checkered pattern and lap timing
  - Created BeatMarker components synchronized with BeatManager
  - Implemented TrackBoundaries with collision detection
  - TrackSystem combines all components into a complete track
  - Created multiple test scenes for verification
  - Full test coverage with unit and integration tests

- [x] **Story 006: Single Vehicle Implementation** ✓ COMPLETE  
  *Create a basic vehicle that can be driven on the track*
  - Implement top-down vehicle physics
  - Add basic steering and acceleration
  - Create simple vehicle sprite  
  - Add basic collision detection
  
  **Implementation Notes:**
  - Created Vehicle class with realistic top-down physics
  - Implemented drift mechanics for realistic car behavior
  - Added steering that requires movement (no rotation when stationary)
  - Created simple visual representation with direction indicator
  - Added collision shape for boundary detection
  - Implemented signals for speed and direction updates
  - Created test scene for vehicle-track integration
  - Full test coverage with unit and integration tests

- [x] **Story 007: Lane Detection System** ✓ COMPLETE
  *Implement system to accurately track which lane the vehicle is in*
  - Create lane boundaries detection
  - Implement current lane tracking
  - Add lane transition detection
  - Create lane position debug visualization
  
  **Implementation Notes:**
  - Created LaneDetectionSystem for accurate lane tracking
  - Implemented vehicle integration with RhythmVehicleWithLanes class
  - Added visual feedback with LaneVisualFeedback component
  - Created comprehensive test coverage (unit and integration)
  - Built interactive test scene for manual verification
  - Features include:
	- Real-time lane position detection
	- Lane boundary calculations
	- Transition detection between lanes
	- Visual debug overlay with lane indicators
	- Optional lane centering assistance
	- Signal system for lane-based events
  - Story 007 title was "Lane Detection System" in backlog but "Visual Feedback System" in CLAUDE.md
  - Both aspects were implemented in this story

- [x] **Story 008: Visual Feedback System** ✓ COMPLETE  
  *Implement visual feedback for rhythm gameplay*
  - Created RhythmFeedbackManager for centralized feedback
  - Added PerfectHitIndicator with particle effects
  - Implemented MissIndicator for timing failures
  - Enhanced BeatIndicator with combo effects
  - Added performance tracking and multipliers
  - Created comprehensive visual feedback demo
  - Full test coverage for all components

---

## EPIC 3: CORE GAME LOOP
**Priority: 3**
Connect audio and driving systems to create the fundamental gameplay experience.

### Stories:
- [x] **Story 009: Lane Position to Sound Mapping** ✓ COMPLETE  
  *Connect lane detection system to sound generator*
  - Created LaneAudioController to bridge systems
  - Implemented smooth volume transitions
  - Added center lane silence option
  - Created fade curves for natural transitions
  - Integrated with beat synchronization
  - Built comprehensive test coverage

- [x] **Story 010: Lap Recording System** ✓ COMPLETE  
  *Create system to record vehicle path during a lap*
  - Created LapRecorder with configurable sample rates
  - Implemented comprehensive position/lane/velocity tracking
  - Added automatic lap completion detection
  - Created RecordingIndicator UI component
  - Stored beat alignment and timing data
  - Built resource-based recording format

- [x] **Story 011: Path Playback System** ✓ COMPLETE  
  *Create system to automatically replay recorded paths*
  - Created PathPlayer with multiple interpolation modes
  - Implemented PlaybackVehicle as ghost with trails
  - Added automatic sound triggering during playback
  - Created PlaybackModeIndicator UI component
  - Supported infinite loops with speed control
  - Built comprehensive demo and test coverage

- [ ] **Story 012: Basic UI Elements**  
  *Add minimal UI elements needed for core game loop*
  - Implement recording/playback status indicator
  - Add beat/measure counter
  - Create BPM display and control
  - Implement basic vehicle selection

---

## EPIC 4: PLAYABILITY ENHANCEMENTS
**Priority: 4**
Add polish features that improve the core gameplay experience.

### Stories:
- [ ] **Story 013: Sound Visualization**  
  *Add visual effects that respond to generated sounds*
  - Implement beat-synced visual pulses
  - Add lane-specific visual effects
  - Create vehicle light trails based on sound
  - Implement environment reactions to music

- [ ] **Story 014: Audio Mixing Controls**  
  *Add basic controls for adjusting sound parameters*
  - Implement volume sliders for sound types
  - Add effect controls (reverb, delay)
  - Create mute/solo functionality
  - Support sound preset saving

- [ ] **Story 015: Vehicle Feel Improvements**  
  *Polish vehicle controls and physics for better feel*
  - Add subtle drift for smoother turning 
  - Implement acceleration/deceleration curves
  - Add screen shake and feedback effects
  - Create vehicle state machine for different driving modes

- [ ] **Story 016: Camera System**  
  *Implement a dynamic camera that follows vehicle movement*
  - Create smooth camera follow
  - Add subtle zoom based on speed
  - Implement camera transitions between vehicles
  - Support overview mode for seeing entire track

---

## EPIC 5: EXTENDED FUNCTIONALITY
**Priority: 5**
Expand beyond the core game loop with additional features.

### Stories:
- [ ] **Story 017: Multiple Sound Banks**  
  *Create different sound sets for greater variety*
  - Implement at least 3 different sound banks
  - Add sound bank selection UI
  - Create save/load system for custom sound banks
  - Support runtime sound parameter adjustments

- [ ] **Story 018: Save/Load System**  
  *Allow players to save and load their compositions*
  - Create composition data structure
  - Implement save file format
  - Add load functionality
  - Create simple composition browser

- [ ] **Story 019: Audio Export**  
  *Allow players to export their compositions as audio files*
  - Implement audio capture during playback
  - Create WAV export functionality
  - Add export options (format, quality)
  - Support metadata in exported files

- [ ] **Story 020: Track Editor**  
  *Create a basic system for customizing track layouts*
  - Implement track parameter adjustments
  - Create beat marker customization
  - Support track shape variations
  - Add track theme selection

---

## Development Guidelines

### Godot Project Structure
- Use `res://assets/` for all visual and audio assets
- Use `res://scenes/` for scene files, organized by type
- Use `res://scripts/` for GDScript files
- Use `res://resources/` for shared resources and presets

### Coding Standards
- Use static typing in GDScript where practical
- Follow "Call Down, Signal Up" principle for node communication
- Use comments for complex algorithms
- Implement resource-based data where appropriate

### Testing Milestones
1. **Audio Test**: Keyboard-driven sound generation (Story 004)
   - Run with: `./run_simple_sound_test.sh`
2. **Driving Test**: Vehicle control and lane detection (Story 008)
3. **Core Loop Test**: Record and playback a simple pattern (Story 011)
4. **Complete MVP**: Functional composition creation (Story 016)

### Test Commands
- Run all tests: `./run_gut_tests.sh`
- Run with JUnit report: `./run_gut_tests.sh --report`
- Run specific test file: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut/unit/test_name.gd`
- Run simple sound test: `./run_simple_sound_test.sh`

### Development Process
1. Focus on one story at a time
2. Create feature branch for each story
3. Test thoroughly before moving to next story
4. Regularly test on target hardware
5. Maintain documentation alongside code

---

*Note: This backlog represents the minimum viable path to a working prototype. Additional features like multiple vehicles, advanced effects, and additional game modes will be considered after the core functionality is established.*
