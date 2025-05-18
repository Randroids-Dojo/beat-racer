extends AudioStreamPlayer
class_name MetronomeSimple

# Simplest possible metronome implementation
# Uses pre-generated AudioStreamWAV for reliable sound

var _tick_sample: AudioStreamWAV
var _tock_sample: AudioStreamWAV

func _ready():
	bus = "SFX"
	_generate_samples()

func _generate_samples():
	# Generate tick sound (high pitch beep)
	_tick_sample = _create_beep_sample(800.0, 0.1)
	
	# Generate tock sound (low pitch beep)
	_tock_sample = _create_beep_sample(600.0, 0.1)

func _create_beep_sample(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 44100
	var sample_count = int(duration * sample_rate)
	
	var audio_data = PackedByteArray()
	audio_data.resize(sample_count * 2)  # 16-bit samples
	
	for i in range(sample_count):
		# Generate sine wave
		var phase = float(i) * frequency / sample_rate
		var sample_float = sin(phase * TAU * 2.0)
		
		# Apply simple envelope
		var envelope = 1.0
		if i < sample_count * 0.1:  # Attack
			envelope = float(i) / (sample_count * 0.1)
		elif i > sample_count * 0.9:  # Release
			envelope = 1.0 - (float(i - sample_count * 0.9) / (sample_count * 0.1))
			
		sample_float *= envelope * 0.5  # Scale down to avoid clipping
		
		# Convert to 16-bit integer
		var sample_int = int(sample_float * 32767)
		
		# Store as little-endian 16-bit
		audio_data[i * 2] = sample_int & 0xFF
		audio_data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	# Create AudioStreamWAV
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = audio_data
	
	return wav

func play_tick(vol_db: float = -6.0):
	stream = _tick_sample
	volume_db = vol_db
	pitch_scale = 1.0
	play()

func play_tock(vol_db: float = -6.0):
	stream = _tock_sample
	volume_db = vol_db
	pitch_scale = 1.0
	play()

func play_metronome_beat(is_downbeat: bool, volume_db: float = -6.0):
	if is_downbeat:
		play_tick(volume_db)
	else:
		play_tock(volume_db)