extends Node
class_name MetronomeGenerator

# Simple metronome sound generator
# Generates beep sounds for tick and tock

var _tick_player: AudioStreamPlayer
var _tock_player: AudioStreamPlayer

# Audio streams
var _tick_stream: AudioStreamGenerator
var _tock_stream: AudioStreamGenerator

# Playback
var _tick_playback: AudioStreamGeneratorPlayback
var _tock_playback: AudioStreamGeneratorPlayback

# Properties
var _tick_frequency: float = 800.0  # Higher pitch
var _tock_frequency: float = 600.0  # Lower pitch
var _duration: float = 0.05  # 50ms beep
var _sample_rate: float = 44100.0

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

func play_tick(volume_db: float = -6.0):
	_generate_beep(_tick_player, _tick_frequency, volume_db)

func play_tock(volume_db: float = -6.0):
	_generate_beep(_tock_player, _tock_frequency, volume_db)

func _generate_beep(player: AudioStreamPlayer, frequency: float, volume_db: float):
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()
	
	# Get the playback buffer
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	
	# Generate the beep sound
	var frames_to_generate = int(_duration * _sample_rate)
	var attack_frames = int(frames_to_generate * 0.1)  # 10% attack
	var release_frames = int(frames_to_generate * 0.3)  # 30% release
	var sustain_frames = frames_to_generate - attack_frames - release_frames
	
	for i in range(frames_to_generate):
		var amplitude = 1.0
		
		# Apply envelope
		if i < attack_frames:
			amplitude = float(i) / float(attack_frames)
		elif i >= attack_frames + sustain_frames:
			var release_progress = float(i - attack_frames - sustain_frames) / float(release_frames)
			amplitude = 1.0 - release_progress
		
		# Generate sine wave sample
		var phase = float(i) * frequency / _sample_rate
		var sample = sin(phase * TAU) * amplitude * 0.5
		
		# Push to buffer
		if playback.get_frames_available() > 0:
			playback.push_frame(Vector2(sample, sample))
		else:
			break
	
	# Schedule stop after duration
	var timer = Timer.new()
	timer.wait_time = _duration * 2  # Give extra time for release
	timer.one_shot = true
	timer.timeout.connect(func(): player.stop(); timer.queue_free())
	add_child(timer)
	timer.start()

func set_tick_frequency(freq: float):
	_tick_frequency = freq

func set_tock_frequency(freq: float):
	_tock_frequency = freq

func set_beep_duration(duration: float):
	_duration = clamp(duration, 0.01, 1.0)