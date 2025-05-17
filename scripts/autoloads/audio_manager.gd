extends Node

# Audio Bus Names
const MASTER_BUS = "Master"
const MELODY_BUS = "Melody"
const BASS_BUS = "Bass"
const PERCUSSION_BUS = "Percussion"
const SFX_BUS = "SFX"

# Default volumes in dB
const DEFAULT_MASTER_VOLUME = 0.0
const DEFAULT_MELODY_VOLUME = -6.0
const DEFAULT_BASS_VOLUME = -6.0
const DEFAULT_PERCUSSION_VOLUME = -6.0
const DEFAULT_SFX_VOLUME = -6.0

# Bus indices
var _master_idx: int
var _melody_idx: int
var _bass_idx: int
var _percussion_idx: int
var _sfx_idx: int

func _ready():
	_setup_audio_buses()
	_setup_effects()
	_set_default_volumes()
	
	print("Audio Manager initialized")
	_print_bus_info()

func _setup_audio_buses():
	# Get master bus index (already exists)
	_master_idx = AudioServer.get_bus_index(MASTER_BUS)
	
	# Create Melody bus
	AudioServer.add_bus()
	_melody_idx = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(_melody_idx, MELODY_BUS)
	AudioServer.set_bus_send(_melody_idx, MASTER_BUS)
	
	# Create Bass bus
	AudioServer.add_bus()
	_bass_idx = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(_bass_idx, BASS_BUS)
	AudioServer.set_bus_send(_bass_idx, MASTER_BUS)
	
	# Create Percussion bus
	AudioServer.add_bus()
	_percussion_idx = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(_percussion_idx, PERCUSSION_BUS)
	AudioServer.set_bus_send(_percussion_idx, MASTER_BUS)
	
	# Create SFX bus
	AudioServer.add_bus()
	_sfx_idx = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(_sfx_idx, SFX_BUS)
	AudioServer.set_bus_send(_sfx_idx, MASTER_BUS)

func _setup_effects():
	# Add reverb to Melody bus
	var melody_reverb = AudioEffectReverb.new()
	melody_reverb.wet = 0.3
	melody_reverb.room_size = 0.7
	melody_reverb.damping = 0.5
	AudioServer.add_bus_effect(_melody_idx, melody_reverb)
	
	# Add delay to Melody bus
	var melody_delay = AudioEffectDelay.new()
	melody_delay.mix = 0.2
	melody_delay.tap1_active = true
	melody_delay.tap1_delay_ms = 250.0
	melody_delay.tap1_level_db = -6.0
	melody_delay.feedback_active = true
	melody_delay.feedback_level_db = -12.0
	AudioServer.add_bus_effect(_melody_idx, melody_delay)
	
	# Add compressor to Bass bus
	var bass_compressor = AudioEffectCompressor.new()
	bass_compressor.threshold = -12.0
	bass_compressor.ratio = 4.0
	bass_compressor.attack_us = 20.0
	AudioServer.add_bus_effect(_bass_idx, bass_compressor)
	
	# Add subtle chorus to Bass bus
	var bass_chorus = AudioEffectChorus.new()
	bass_chorus.wet = 0.15
	bass_chorus.depth = 0.2
	bass_chorus.speed = 0.5
	AudioServer.add_bus_effect(_bass_idx, bass_chorus)
	
	# Add compressor to Percussion bus
	var percussion_compressor = AudioEffectCompressor.new()
	percussion_compressor.threshold = -10.0
	percussion_compressor.ratio = 6.0
	percussion_compressor.attack_us = 10.0
	AudioServer.add_bus_effect(_percussion_idx, percussion_compressor)
	
	# Add EQ to Percussion bus to enhance punch
	var percussion_eq = AudioEffectEQ.new()
	percussion_eq.set_band_gain_db(1, 3.0)  # Boost low-mids
	percussion_eq.set_band_gain_db(6, 2.0)  # Boost highs
	AudioServer.add_bus_effect(_percussion_idx, percussion_eq)
	
	# Add compressor to SFX bus
	var sfx_compressor = AudioEffectCompressor.new()
	sfx_compressor.threshold = -8.0
	sfx_compressor.ratio = 3.0
	AudioServer.add_bus_effect(_sfx_idx, sfx_compressor)

func _set_default_volumes():
	set_bus_volume_db(MASTER_BUS, DEFAULT_MASTER_VOLUME)
	set_bus_volume_db(MELODY_BUS, DEFAULT_MELODY_VOLUME)
	set_bus_volume_db(BASS_BUS, DEFAULT_BASS_VOLUME)
	set_bus_volume_db(PERCUSSION_BUS, DEFAULT_PERCUSSION_VOLUME)
	set_bus_volume_db(SFX_BUS, DEFAULT_SFX_VOLUME)

func _print_bus_info():
	print("Audio Bus Configuration:")
	print("  Master Bus: idx=%d" % _master_idx)
	print("  Melody Bus: idx=%d" % _melody_idx)
	print("  Bass Bus: idx=%d" % _bass_idx)
	print("  Percussion Bus: idx=%d" % _percussion_idx)
	print("  SFX Bus: idx=%d" % _sfx_idx)

# Public methods for volume control
func set_bus_volume_db(bus_name: String, volume_db: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)

func get_bus_volume_db(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.get_bus_volume_db(bus_idx)
	return 0.0

func set_bus_mute(bus_name: String, mute: bool):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, mute)

func is_bus_muted(bus_name: String) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.is_bus_mute(bus_idx)
	return false

func set_bus_solo(bus_name: String, solo: bool):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_solo(bus_idx, solo)

func is_bus_solo(bus_name: String) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.is_bus_solo(bus_idx)
	return false

# Convenience methods for linear volume control (0.0 to 1.0)
func set_bus_volume_linear(bus_name: String, volume_linear: float):
	var volume_db = linear_to_db(clamp(volume_linear, 0.0, 1.0))
	set_bus_volume_db(bus_name, volume_db)

func get_bus_volume_linear(bus_name: String) -> float:
	var volume_db = get_bus_volume_db(bus_name)
	return db_to_linear(volume_db)

# Effect bypass methods
func set_effect_enabled(bus_name: String, effect_idx: int, enabled: bool):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_effect_enabled(bus_idx, effect_idx, enabled)

func is_effect_enabled(bus_name: String, effect_idx: int) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.is_bus_effect_enabled(bus_idx, effect_idx)
	return false

# Get effect reference for advanced control
func get_bus_effect(bus_name: String, effect_idx: int) -> AudioEffect:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.get_bus_effect(bus_idx, effect_idx)
	return null

# Audio test method for testing different buses
func play_test_tone(bus_name: String = MELODY_BUS, frequency: float = 440.0, duration: float = 0.5):
	var player = AudioStreamPlayer.new()
	player.bus = bus_name
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	player.stream = generator
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback()
	var frames_to_generate = int(duration * generator.mix_rate)
	var phase = 0.0
	
	for i in range(frames_to_generate):
		var value = sin(phase * TAU) * 0.5
		playback.push_frame(Vector2(value, value))
		phase = fmod(phase + frequency / generator.mix_rate, 1.0)
		
		if i % int(generator.mix_rate * generator.buffer_length) == 0:
			await get_tree().process_frame
	
	await player.finished
	player.queue_free()