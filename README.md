# Beat Racer 🎮🎵

A rhythm-based racing game built with Godot 4 where your vehicle's performance is enhanced by staying in sync with the beat!

## 🎯 Game Concept

Beat Racer combines traditional racing mechanics with rhythm game elements. Drive your vehicle around a circular track while timing your acceleration with the beat to gain speed boosts. Perfect timing rewards you with extra power!

## 🚀 Quick Start

### Play the Demo
```bash
./run_rhythm_vehicle_demo.sh
```

### Controls
- **Arrow Keys**: Drive the vehicle
- **Space**: Toggle metronome
- **R**: Reset position
- **ESC**: Exit

### Gameplay Tips
- Accelerate in sync with the beat for speed boosts
- Perfect timing (within 30% of beat window) gives 50% extra boost
- Watch the rhythm stats to improve your timing

## 🏗️ Project Status

### Completed Stories
- ✅ **Story 001**: Audio Bus Setup
- ✅ **Story 002**: Lane-based Sound Generator
- ✅ **Story 003**: Beat Synchronization System
- ✅ **Story 004**: Simple Sound Playback Test
- ✅ **Story 005**: Basic Track Layout
- ✅ **Story 006**: Single Vehicle Implementation

### Next Up
- 🔮 **Story 007**: Visual Feedback System
- 🔮 **Story 008**: HUD Implementation
- 🔮 **Story 009**: Multiple Vehicles

## 🛠️ Development

### Running Tests
```bash
# Run all tests
./run_gut_tests.sh

# Run specific test demos
./run_metronome_test.sh
./run_track_test.sh
./run_vehicle_track_test.sh
```

### Project Structure
```
beat-racer/
├── scripts/          # Core game logic
│   ├── autoloads/   # Global systems (AudioManager, BeatManager)
│   └── components/  # Game components
├── scenes/          # Godot scenes and visual elements
├── tests/           # Comprehensive test suite
└── docs/           # Documentation
```

## 🎵 Key Features

### Audio System
- Multi-bus audio architecture with effects
- Procedural sound generation
- Multiple musical scales support
- Beat-synchronized audio events

### Beat System
- Accurate beat tracking with sub-frame precision
- Visual and audio metronome
- Beat event system for gameplay mechanics

### Track System
- Circular track with 3 lanes
- Collision boundaries
- Beat markers for visual feedback
- Lap timing system

### Vehicle System
- Physics-based movement
- Rhythm-based boost mechanics
- Perfect timing detection
- Visual and audio feedback

## 📚 Documentation

- [Project Review](PROJECT_REVIEW.md) - Comprehensive project status
- [Critical Audio Notes](docs/critical-audio-notes.md) - Important audio implementation details
- [Story Documentation](docs/) - Detailed story implementations

## 🧪 Testing

The project follows a zero-orphan testing policy with comprehensive coverage:
- Unit tests for individual components
- Integration tests for system interactions
- Visual test scenes for gameplay verification

## 🤝 Contributing

This project is actively developed. Check the documentation and existing patterns before contributing.

## 📝 License

[License information to be added]

---

Built with Godot 4.4.1 | 🤖 Generated with [Claude Code](https://claude.ai/code)