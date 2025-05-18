# Audio Implementation

## Audio Architecture

Create a flexible audio system using buses:

### Configure Audio Buses

```gdscript
# In an autoloaded audio manager
func _ready():
    # Get default bus indices
    var master_idx = AudioServer.get_bus_index("Master")
    
    # Create music bus
    AudioServer.add_bus()
    var music_idx = AudioServer.get_bus_count() - 1
    AudioServer.set_bus_name(music_idx, "Music")
    AudioServer.set_bus_send(music_idx, "Master")
    
    # Add reverb to music
    var reverb = AudioEffectReverb.new()
    reverb.wet = 0.2
    AudioServer.add_bus_effect(music_idx, reverb)
    
    # Create SFX bus with compression
    AudioServer.add_bus()
    var sfx_idx = AudioServer.get_bus_count() - 1
    AudioServer.set_bus_name(sfx_idx, "SFX")
    AudioServer.set_bus_send(sfx_idx, "Master")
    
    var compressor = AudioEffectCompressor.new()
    AudioServer.add_bus_effect(sfx_idx, compressor)
```

### Audio Pools for Efficient Playback

```gdscript
var _sfx_players: Array[AudioStreamPlayer] = []
const _pool_size: int = 10

func _ready():
    # Setup pools
    for i in range(_pool_size):
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        player.finished.connect(func(): _return_to_pool(player))
        _sfx_players.append(player)

func play_sound(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0):
    var player = _get_available_player()
    if player:
        player.stream = stream
        player.volume_db = volume_db
        player.pitch_scale = pitch_scale
        player.play()

func _get_available_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            return player
    return null  # All players are busy

func _return_to_pool(player: AudioStreamPlayer):
    # Reset player state
    player.volume_db = 0.0
    player.pitch_scale = 1.0
```

## Procedural Audio

For dynamic sound generation (useful for Beat Racer):

```gdscript
extends Node

var _stream_player: AudioStreamPlayer
var _stream_playback: AudioStreamGeneratorPlayback
var _generator: AudioStreamGenerator

# Sound parameters
var frequency: float = 440.0  # Hz
var volume: float = 0.5
var sample_hz: float = 44100.0

func _ready():
    # Create generator stream
    _generator = AudioStreamGenerator.new()
    _generator.mix_rate = sample_hz
    _generator.buffer_length = 0.1  # 100ms buffer
    
    # Setup player
    _stream_player = AudioStreamPlayer.new()
    _stream_player.stream = _generator
    add_child(_stream_player)
    _stream_player.play()
    
    # Get playback interface
    _stream_playback = _stream_player.get_stream_playback()

func _process(_delta):
    _fill_buffer()

func _fill_buffer():
    var frames_available = _stream_playback.get_frames_available()
    if frames_available > 0:
        var phase = 0.0
        for i in range(frames_available):
            var frame_value = sin(phase * TAU) * volume
            _stream_playback.push_frame(Vector2(frame_value, frame_value))  # Stereo: left, right
            
            # Advance phase for next sample
            phase = fmod(phase + (frequency / sample_hz), 1.0)

func set_note(note_frequency: float):
    frequency = note_frequency
```

## Beat Racer Specific Audio

### Music Timing System

```gdscript
extends Node

signal beat_occurred(beat_number: int)
signal measure_completed(measure_number: int)

var bpm: float = 120.0
var beats_per_measure: int = 4
var current_beat: int = 0
var current_measure: int = 0
var time_since_last_beat: float = 0.0

func _ready():
    var beat_duration = 60.0 / bpm
    var timer = Timer.new()
    timer.wait_time = beat_duration
    timer.timeout.connect(_on_beat)
    add_child(timer)
    timer.start()

func _on_beat():
    current_beat += 1
    beat_occurred.emit(current_beat)
    
    if current_beat % beats_per_measure == 0:
        current_measure += 1
        measure_completed.emit(current_measure)
```

### Dynamic Music Layers

```gdscript
extends Node

var music_layers: Dictionary = {}
var current_intensity: float = 0.0

func _ready():
    # Load music layers
    music_layers["drums"] = AudioStreamPlayer.new()
    music_layers["bass"] = AudioStreamPlayer.new()
    music_layers["melody"] = AudioStreamPlayer.new()
    
    for layer_name in music_layers:
        var player = music_layers[layer_name]
        player.stream = load("res://assets/audio/music/%s.ogg" % layer_name)
        player.bus = "Music"
        add_child(player)

func start_music():
    for player in music_layers.values():
        player.play()
    
    # Start with only drums
    set_intensity(0.3)

func set_intensity(value: float):
    current_intensity = clamp(value, 0.0, 1.0)
    
    # Fade layers based on intensity
    music_layers["drums"].volume_db = linear_to_db(1.0)  # Always on
    music_layers["bass"].volume_db = linear_to_db(smoothstep(0.3, 0.6, current_intensity))
    music_layers["melody"].volume_db = linear_to_db(smoothstep(0.6, 1.0, current_intensity))
```

### Sound Effect Variations

```gdscript
extends Node

var hit_sounds: Array[AudioStream] = []
var pitch_variation: float = 0.1

func _ready():
    # Load hit sound variations
    for i in range(5):
        hit_sounds.append(load("res://assets/audio/sfx/hit_%d.wav" % i))

func play_hit_sound():
    var sound = hit_sounds.pick_random()
    var pitch = 1.0 + randf_range(-pitch_variation, pitch_variation)
    AudioManager.play_sfx(sound, 0.0, pitch)
```

## Volume Control System

### Save/Load Volume Settings

```gdscript
extends Node

const SAVE_PATH = "user://audio_settings.save"

var volume_settings: Dictionary = {
    "master": 1.0,
    "music": 0.8,
    "sfx": 1.0
}

func _ready():
    load_settings()
    apply_settings()

func set_bus_volume(bus_name: String, linear_value: float):
    volume_settings[bus_name.to_lower()] = linear_value
    var bus_idx = AudioServer.get_bus_index(bus_name)
    AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_value))
    save_settings()

func save_settings():
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_var(volume_settings)
    file.close()

func load_settings():
    if FileAccess.file_exists(SAVE_PATH):
        var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
        volume_settings = file.get_var()
        file.close()

func apply_settings():
    for bus_name in volume_settings:
        set_bus_volume(bus_name.capitalize(), volume_settings[bus_name])
```

## Important Notes (CRITICAL)

1. **AudioEffectDelay Properties**: 
   - Does NOT have a 'mix' property
   - Use 'dry' property instead
   - Always verify with test_audio_effect_properties.gd

2. **Audio Stream Generation**:
   - Generate all frames immediately
   - Check for null stream playback
   - Add comprehensive error checking

3. **Volume Controls**:
   - Sliders MUST have step = 0.01
   - Use linear_to_db() for conversions
   - Default linear 0.5 = -6dB

4. **Testing**:
   - Always run audio tests before implementation
   - Use Context7 to verify property names
   - Log all operations for debugging

See [Audio Effect Guidelines](audio-effect-guidelines.md) for more details.