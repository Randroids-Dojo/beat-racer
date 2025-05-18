# Beat Synchronization System

The Beat Synchronization System provides accurate beat tracking and synchronization for Beat Racer. It consists of several interconnected components that work together to create a rhythm-based gameplay experience.

## Components

### 1. BeatManager (Autoload)
- Core beat detection and timing system
- Manages BPM, beats per measure, and timing calculations
- Emits signals for beat events
- Location: `scripts/autoloads/beat_manager.gd`

### 2. PlaybackSync
- Coordinates audio playback with beat events
- Manages metronome and music track synchronization
- Handles sync detection and correction
- Location: `scripts/components/sound/playback_sync.gd`

### 3. BeatEventSystem
- Event system tied to beat timing
- Allows registration of callbacks for different quantization levels
- Supports delayed and repeating events
- Location: `scripts/components/sound/beat_event_system.gd`

### 4. Visual Components
- BeatIndicator: Visual beat pulse indicator
- BeatVisualizationPanel: Complete UI panel for beat sync display
- Location: `scripts/components/visual/`

## Usage

### Basic Setup

```gdscript
# Start beat tracking
BeatManager.bpm = 120.0
BeatManager.start()

# Create sync components
var playback_sync = PlaybackSync.new()
var beat_event_system = BeatEventSystem.new()

add_child(playback_sync)
add_child(beat_event_system)

# Start synchronization
playback_sync.start_sync()
```

### Registering Beat Events

```gdscript
# Register event on every beat
beat_event_system.register_event(
    "my_beat_event",
    Callable(self, "_on_beat"),
    BeatEventSystem.Quantization.BEAT
)

# Register event on measures
beat_event_system.register_event(
    "measure_event", 
    Callable(self, "_on_measure"),
    BeatEventSystem.Quantization.MEASURE
)

# Delayed event (2 beats)
beat_event_system.register_event(
    "delayed_event",
    Callable(self, "_on_delayed"),
    BeatEventSystem.Quantization.BEAT,
    2.0  # Delay in beats
)
```

### Visual Feedback

```gdscript
# Create beat indicator
var indicator = BeatIndicator.new()
indicator.pulse_color = Color.CYAN
indicator.indicator_size = 100.0
add_child(indicator)

# Create visualization panel
var vis_panel = BeatVisualizationPanel.new()
vis_panel.show_bpm = true
vis_panel.show_beat_count = true
add_child(vis_panel)
```

## BPM and Timing

The system supports BPM from 60 to 240, with automatic timing calculations:

```gdscript
# Change BPM
BeatManager.bpm = 140.0

# Get timing info
var beat_duration = BeatManager.beat_duration
var progress = BeatManager.get_beat_progress()
var time_to_next = BeatManager.get_time_to_next_beat()

# Check if on beat (with tolerance)
if BeatManager.is_on_beat(0.1):  # 100ms tolerance
    # Do something on beat
```

## Integration with Lane Sound System

The beat system integrates with the lane sound system for rhythm-based gameplay:

```gdscript
# Synchronize lane changes to beats
beat_event_system.register_event(
    "lane_change",
    Callable(self, "_change_lane"),
    BeatEventSystem.Quantization.MEASURE
)

func _change_lane(data: Dictionary):
    var next_lane = (lane_sound_system.get_current_lane() + 1) % 3
    lane_sound_system.set_current_lane(next_lane)
```

## Quantization Levels

The event system supports multiple quantization levels:
- `BEAT`: Every beat
- `HALF_BEAT`: Every half beat
- `QUARTER_BEAT`: Every quarter beat
- `MEASURE`: Every measure (bar)
- `TWO_MEASURES`: Every 2 measures
- `FOUR_MEASURES`: Every 4 measures

## Demo Scene

A complete demo scene is available at `scenes/test/beat_sync_demo.gd` that showcases:
- BPM control
- Metronome toggle
- Lane switching
- Visual beat indicators
- Complete system integration

## Testing

Comprehensive tests are available in:
- `tests/gut/unit/test_beat_manager.gd`
- `tests/gut/unit/test_playback_sync.gd`
- `tests/gut/unit/test_beat_event_system.gd`
- `tests/gut/integration/test_beat_sync_integration.gd`

Note: Some tests may fail in isolated test environments due to singleton dependencies.

## Best Practices

1. Always check if BeatManager is available before using dependent components
2. Use appropriate quantization levels for different game events
3. Consider audio latency when setting up sync tolerance
4. Test with different BPM values to ensure smooth gameplay
5. Use visual indicators during development to verify sync accuracy

## Performance Considerations

- The beat system uses timers and signals for minimal performance impact
- Event callbacks should be lightweight to avoid timing issues
- Consider using the event queue for complex operations
- Monitor sync accuracy with the built-in accuracy methods