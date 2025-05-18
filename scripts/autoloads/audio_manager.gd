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

# Enable detailed logging
var _debug_logging: bool = true

func _ready():
	_log("=== AudioManager Starting Initialization ===")
	_log("Godot version: " + Engine.get_version_info().string)
	_log("Project name: " + ProjectSettings.get_setting("application/config/name"))
	
	# Safely check for scene tree and current scene
	var tree = null
	if has_method("get_tree"):
		tree = get_tree()
	
	if tree != null and tree.current_scene != null:
		_log("Current scene: " + str(tree.current_scene))
	else:
		_log("Current scene: <null - test environment>")
	
	_setup_audio_buses()
	_setup_effects()
	_set_default_volumes()
	
	_log("Audio Manager initialization complete")
	_print_bus_info()
	_log("========================================")

func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] AudioManager: %s" % [timestamp, message])

func _setup_audio_buses():
	_log("Setting up audio buses...")
	
	# Get master bus index (already exists)
	_master_idx = AudioServer.get_bus_index(MASTER_BUS)
	_log("Master bus index: %d" % _master_idx)
	
	# Create Melody bus
	AudioServer.add_bus()
	_melody_idx = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(_melody_idx, MELODY_BUS)
	AudioServer.set_bus_send(_melody_idx, MASTER_BUS)
	_log("Created Melody bus at index: %d" % _melody_idx)
	
	# Create Bass bus
	AudioServer.add_bus()
	_bass_idx = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(_bass_idx, BASS_BUS)
	AudioServer.set_bus_send(_bass_idx, MASTER_BUS)
	_log("Created Bass bus at index: %d" % _bass_idx)
	
	# Create Percussion bus
	AudioServer.add_bus()
	_percussion_idx = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(_percussion_idx, PERCUSSION_BUS)
	AudioServer.set_bus_send(_percussion_idx, MASTER_BUS)
	_log("Created Percussion bus at index: %d" % _percussion_idx)
	
	# Create SFX bus
	AudioServer.add_bus()
	_sfx_idx = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(_sfx_idx, SFX_BUS)
	AudioServer.set_bus_send(_sfx_idx, MASTER_BUS)
	_log("Created SFX bus at index: %d" % _sfx_idx)
	
	_log("Total buses: %d" % AudioServer.get_bus_count())

func _setup_effects():
	_log("Setting up audio effects...")
	
	# Add reverb to Melody bus
	var melody_reverb = AudioEffectReverb.new()
	melody_reverb.wet = 0.3
	melody_reverb.room_size = 0.7
	melody_reverb.damping = 0.5
	AudioServer.add_bus_effect(_melody_idx, melody_reverb)
	_log("Added Reverb to Melody bus (wet: %f, room_size: %f)" % [melody_reverb.wet, melody_reverb.room_size])
	
	# Add delay to Melody bus
	var melody_delay = AudioEffectDelay.new()
	melody_delay.tap1_active = true
	melody_delay.tap1_delay_ms = 250.0
	melody_delay.tap1_level_db = -6.0
	melody_delay.feedback_active = true
	melody_delay.feedback_delay_ms = 250.0
	melody_delay.feedback_level_db = -12.0
	AudioServer.add_bus_effect(_melody_idx, melody_delay)
	_log("Added Delay to Melody bus (tap1: %fms, feedback: %fms)" % [melody_delay.tap1_delay_ms, melody_delay.feedback_delay_ms])
	
	# Add compressor to Bass bus
	var bass_compressor = AudioEffectCompressor.new()
	bass_compressor.threshold = -12.0
	bass_compressor.ratio = 4.0
	bass_compressor.attack_us = 20.0
	AudioServer.add_bus_effect(_bass_idx, bass_compressor)
	_log("Added Compressor to Bass bus (threshold: %f, ratio: %f)" % [bass_compressor.threshold, bass_compressor.ratio])
	
	# Add subtle chorus to Bass bus
	var bass_chorus = AudioEffectChorus.new()
	bass_chorus.wet = 0.15
	bass_chorus.dry = 0.85
	bass_chorus.voice_count = 2
	# Configure voice 1
	bass_chorus.set("voice/1/delay_ms", 20.0)
	bass_chorus.set("voice/1/rate_hz", 0.5)
	bass_chorus.set("voice/1/depth_ms", 2.0)
	bass_chorus.set("voice/1/level_db", 0.0)
	# Configure voice 2
	bass_chorus.set("voice/2/delay_ms", 25.0)
	bass_chorus.set("voice/2/rate_hz", 0.7)
	bass_chorus.set("voice/2/depth_ms", 3.0)
	bass_chorus.set("voice/2/level_db", -3.0)
	AudioServer.add_bus_effect(_bass_idx, bass_chorus)
	_log("Added Chorus to Bass bus (voices: %d, wet: %f)" % [bass_chorus.voice_count, bass_chorus.wet])
	
	# Add compressor to Percussion bus
	var percussion_compressor = AudioEffectCompressor.new()
	percussion_compressor.threshold = -10.0
	percussion_compressor.ratio = 6.0
	percussion_compressor.attack_us = 10.0
	AudioServer.add_bus_effect(_percussion_idx, percussion_compressor)
	_log("Added Compressor to Percussion bus (threshold: %f, ratio: %f)" % [percussion_compressor.threshold, percussion_compressor.ratio])
	
	# Add EQ to Percussion bus to enhance punch
	var percussion_eq = AudioEffectEQ.new()
	# AudioEffectEQ has bands 0-5 (total 6 bands)
	percussion_eq.set_band_gain_db(1, 3.0)  # Boost low-mids
	percussion_eq.set_band_gain_db(5, 2.0)  # Boost highs (max band index is 5)
	AudioServer.add_bus_effect(_percussion_idx, percussion_eq)
	_log("Added EQ to Percussion bus (low-mid boost: 3dB, high boost: 2dB)")
	
	# Add compressor to SFX bus
	var sfx_compressor = AudioEffectCompressor.new()
	sfx_compressor.threshold = -8.0
	sfx_compressor.ratio = 3.0
	AudioServer.add_bus_effect(_sfx_idx, sfx_compressor)
	_log("Added Compressor to SFX bus (threshold: %f, ratio: %f)" % [sfx_compressor.threshold, sfx_compressor.ratio])
	
	_log("Effects setup complete - Total effects added: %d" % _count_total_effects())

func _count_total_effects() -> int:
	var total = 0
	for i in range(AudioServer.get_bus_count()):
		total += AudioServer.get_bus_effect_count(i)
	return total

func _set_default_volumes():
	_log("Setting default volumes...")
	set_bus_volume_db(MASTER_BUS, DEFAULT_MASTER_VOLUME)
	set_bus_volume_db(MELODY_BUS, DEFAULT_MELODY_VOLUME)
	set_bus_volume_db(BASS_BUS, DEFAULT_BASS_VOLUME)
	set_bus_volume_db(PERCUSSION_BUS, DEFAULT_PERCUSSION_VOLUME)
	set_bus_volume_db(SFX_BUS, DEFAULT_SFX_VOLUME)
	_log("Default volumes set (Master: %fdB, Melody: %fdB, Bass: %fdB, Percussion: %fdB, SFX: %fdB)" % 
		[DEFAULT_MASTER_VOLUME, DEFAULT_MELODY_VOLUME, DEFAULT_BASS_VOLUME, DEFAULT_PERCUSSION_VOLUME, DEFAULT_SFX_VOLUME])

func _print_bus_info():
	_log("=== Audio Bus Configuration ===")
	_log("  Master Bus: idx=%d, effects=%d, volume=%fdB" % [_master_idx, AudioServer.get_bus_effect_count(_master_idx), AudioServer.get_bus_volume_db(_master_idx)])
	_log("  Melody Bus: idx=%d, effects=%d, volume=%fdB" % [_melody_idx, AudioServer.get_bus_effect_count(_melody_idx), AudioServer.get_bus_volume_db(_melody_idx)])
	_log("  Bass Bus: idx=%d, effects=%d, volume=%fdB" % [_bass_idx, AudioServer.get_bus_effect_count(_bass_idx), AudioServer.get_bus_volume_db(_bass_idx)])
	_log("  Percussion Bus: idx=%d, effects=%d, volume=%fdB" % [_percussion_idx, AudioServer.get_bus_effect_count(_percussion_idx), AudioServer.get_bus_volume_db(_percussion_idx)])
	_log("  SFX Bus: idx=%d, effects=%d, volume=%fdB" % [_sfx_idx, AudioServer.get_bus_effect_count(_sfx_idx), AudioServer.get_bus_volume_db(_sfx_idx)])
	_log("================================")

# Public methods for volume control
func set_bus_volume_db(bus_name: String, volume_db: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)
		_log("Set volume for bus '%s' to %fdB" % [bus_name, volume_db])
	else:
		_log("WARNING: Bus '%s' not found when setting volume" % bus_name)

func get_bus_volume_db(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.get_bus_volume_db(bus_idx)
	return -80.0

# Public methods for effect control
func set_bus_effect_enabled(bus_name: String, effect_idx: int, enabled: bool):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_effect_enabled(bus_idx, effect_idx, enabled)
		_log("Set effect %d on bus '%s' to %s" % [effect_idx, bus_name, "enabled" if enabled else "disabled"])

func is_bus_effect_enabled(bus_name: String, effect_idx: int) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.is_bus_effect_enabled(bus_idx, effect_idx)
	return false

# Public methods for mute/solo control
func set_bus_mute(bus_name: String, mute: bool):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, mute)
		_log("Set bus '%s' mute to %s" % [bus_name, "true" if mute else "false"])

func is_bus_muted(bus_name: String) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.is_bus_mute(bus_idx)
	return false

func set_bus_solo(bus_name: String, solo: bool):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_solo(bus_idx, solo)
		_log("Set bus '%s' solo to %s" % [bus_name, "true" if solo else "false"])

func is_bus_soloed(bus_name: String) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.is_bus_solo(bus_idx)
	return false

# Access effects by type
func get_bus_effect(bus_name: String, effect_idx: int):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.get_bus_effect(bus_idx, effect_idx)
	return null

# Audio test method for testing different buses
func play_test_tone(bus_name: String = MELODY_BUS, frequency: float = 440.0, duration: float = 0.5):
	_log("Playing test tone on bus '%s': frequency=%fHz, duration=%fs" % [bus_name, frequency, duration])
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

func reset_for_testing():
	# Comprehensive reset method for unit testing
	# Resets audio buses to their default state
	_log("Resetting AudioManager for testing...")
	
	# Reset all bus volumes to defaults
	set_bus_volume_db(MASTER_BUS, DEFAULT_MASTER_VOLUME)
	set_bus_volume_db(MELODY_BUS, DEFAULT_MELODY_VOLUME)
	set_bus_volume_db(BASS_BUS, DEFAULT_BASS_VOLUME)
	set_bus_volume_db(PERCUSSION_BUS, DEFAULT_PERCUSSION_VOLUME)
	set_bus_volume_db(SFX_BUS, DEFAULT_SFX_VOLUME)
	
	# Unmute all buses
	var buses = [MASTER_BUS, MELODY_BUS, BASS_BUS, PERCUSSION_BUS, SFX_BUS]
	for bus_name in buses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_solo(bus_idx, false)
	
	# Re-enable effects
	for i in range(AudioServer.get_bus_count()):
		for j in range(AudioServer.get_bus_effect_count(i)):
			AudioServer.set_bus_effect_enabled(i, j, true)
	
	# Disable debug logging in tests
	_debug_logging = false
	
	_log("AudioManager reset for testing complete")