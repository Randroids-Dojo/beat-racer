extends Node
class_name MetronomeGeneratorFixed

# Fixed metronome sound generator that properly fills the audio buffer
# Generates audible tick and tock sounds

var _tick_player: AudioStreamPlayer
var _tock_player: AudioStreamPlayer

# Audio streams
var _tick_stream: AudioStreamGenerator
var _tock_stream: AudioStreamGenerator

# Active playbacks
var _active_playbacks: Array = []

# Properties
var _tick_frequency: float = 800.0  # Higher pitch
var _tock_frequency: float = 600.0  # Lower pitch
var _duration: float = 0.05  # 50ms beep
var _sample_rate: float = 44100.0

# Playback state
class PlaybackState:
	var player: AudioStreamPlayer
	var playback: AudioStreamGeneratorPlayback
	var frequency: float
	var phase: float = 0.0
	var sample_count: int = 0
	var total_samples: int
	var attack_samples: int
	var release_samples: int
	var sustain_samples: int
	var is_active: bool = true

func _ready():
	# Create audio stream generators
	_tick_stream = AudioStreamGenerator.new()
	_tick_stream.mix_rate = _sample_rate
	_tick_stream.buffer_length = 0.1
	
	_tock_stream = AudioStreamGenerator.new()
	_tock_stream.mix_rate = _sample_rate  
	_tock_stream.buffer_length = 0.1
	
	# Create audio players
	_tick_player = AudioStreamPlayer.new()
	_tick_player.stream = _tick_stream
	_tick_player.bus = "SFX"
	add_child(_tick_player)
	
	_tock_player = AudioStreamPlayer.new()
	_tock_player.stream = _tock_stream
	_tock_player.bus = "SFX"
	add_child(_tock_player)
	
	set_process(true)

func _process(_delta):
	# Fill all active playback buffers
	var completed_playbacks = []
	
	for state in _active_playbacks:
		if not state.is_active:
			completed_playbacks.append(state)
			continue
			
		if state.playback and state.playback.can_push_frame():
			var frames_available = state.playback.get_frames_available()
			
			for i in range(frames_available):
				if state.sample_count >= state.total_samples:
					state.is_active = false
					break
					
				# Calculate envelope amplitude
				var amplitude = _calculate_envelope(state)
				
				# Generate sine wave sample
				var sample = sin(state.phase * TAU) * amplitude * 0.7
				state.playback.push_frame(Vector2(sample, sample))
				
				# Update phase and sample count
				state.phase = fmod(state.phase + state.frequency / _sample_rate, 1.0)
				state.sample_count += 1
	
	# Remove completed playbacks
	for state in completed_playbacks:
		state.player.stop()
		_active_playbacks.erase(state)

func _calculate_envelope(state: PlaybackState) -> float:
	var amplitude = 1.0
	
	if state.sample_count < state.attack_samples:
		# Attack phase
		amplitude = float(state.sample_count) / float(state.attack_samples)
	elif state.sample_count >= state.attack_samples + state.sustain_samples:
		# Release phase
		var release_progress = float(state.sample_count - state.attack_samples - state.sustain_samples) / float(state.release_samples)
		amplitude = 1.0 - release_progress
	
	return amplitude

func play_tick(volume_db: float = -6.0):
	_play_beep(_tick_player, _tick_frequency, volume_db)

func play_tock(volume_db: float = -6.0):
	_play_beep(_tock_player, _tock_frequency, volume_db)

func _play_beep(player: AudioStreamPlayer, frequency: float, volume_db: float):
	player.volume_db = volume_db
	player.play()
	
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		push_error("Failed to get playback stream")
		return
	
	# Create playback state
	var state = PlaybackState.new()
	state.player = player
	state.playback = playback
	state.frequency = frequency
	state.total_samples = int(_duration * _sample_rate)
	state.attack_samples = int(state.total_samples * 0.1)  # 10% attack
	state.release_samples = int(state.total_samples * 0.3)  # 30% release
	state.sustain_samples = state.total_samples - state.attack_samples - state.release_samples
	
	_active_playbacks.append(state)

func set_tick_frequency(freq: float):
	_tick_frequency = freq

func set_tock_frequency(freq: float):
	_tock_frequency = freq

func set_beep_duration(duration: float):
	_duration = clamp(duration, 0.01, 1.0)