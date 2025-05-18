## Resource Validation Test Suite
## Tests configuration validation for LaneSoundConfig resources

extends "res://addons/gut/test.gd"

var LaneSoundSystem = preload("res://scripts/components/sound/lane_sound_system.gd")
var LaneSoundConfig = preload("res://scripts/resources/lane_sound_config.gd")
var SoundGenerator = preload("res://scripts/components/sound/sound_generator.gd")

var lane_sound_system: LaneSoundSystem

func before_each():
	lane_sound_system = LaneSoundSystem.new()
	add_child_autofree(lane_sound_system)
	# Make sure we have audio buses
	if AudioServer.get_bus_index("Melody") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Melody")

func test_valid_configuration():
	# Test a valid configuration
	var config = LaneSoundConfig.new()
	config.waveform = SoundGenerator.WaveType.SINE
	config.audio_bus = "Melody"
	config.octave = 0
	config.root_note = SoundGenerator.Note.C
	config.volume = 0.5
	config.scale_type = SoundGenerator.Scale.MAJOR
	config.scale_degree = 1
	config.detune = 0.0
	config.attack_time = 0.01
	config.release_time = 0.1
	
	assert_true(config.validate_config())

func test_invalid_audio_bus():
	# Test with non-existent audio bus
	var config = LaneSoundConfig.new()
	config.audio_bus = "NonExistentBus"
	
	assert_false(config.validate_config())

func test_invalid_volume_range():
	# Test volume out of range
	var config = LaneSoundConfig.new()
	config.audio_bus = "Melody"
	
	# Test too low
	config.volume = -0.1
	assert_false(config.validate_config())
	
	# Test too high
	config.volume = 1.1
	assert_false(config.validate_config())
	
	# Test valid range
	config.volume = 0.0
	assert_true(config.validate_config())
	
	config.volume = 1.0
	assert_true(config.validate_config())

func test_invalid_octave_range():
	# Test octave out of reasonable range
	var config = LaneSoundConfig.new()
	config.audio_bus = "Melody"
	
	# Test too low
	config.octave = -4
	assert_false(config.validate_config())
	
	# Test too high
	config.octave = 4
	assert_false(config.validate_config())
	
	# Test valid range
	config.octave = -3
	assert_true(config.validate_config())
	
	config.octave = 3
	assert_true(config.validate_config())

func test_invalid_scale_degree():
	# Test scale degree out of range
	var config = LaneSoundConfig.new()
	config.audio_bus = "Melody"
	
	# Test too low
	config.scale_degree = 0
	assert_false(config.validate_config())
	
	# Test too high
	config.scale_degree = 8
	assert_false(config.validate_config())
	
	# Test valid range
	config.scale_degree = 1
	assert_true(config.validate_config())
	
	config.scale_degree = 7
	assert_true(config.validate_config())

func test_invalid_detune_range():
	# Test detune out of range
	var config = LaneSoundConfig.new()
	config.audio_bus = "Melody"
	
	# Test too low
	config.detune = -101.0
	assert_false(config.validate_config())
	
	# Test too high
	config.detune = 101.0
	assert_false(config.validate_config())
	
	# Test valid range
	config.detune = -100.0
	assert_true(config.validate_config())
	
	config.detune = 100.0
	assert_true(config.validate_config())

func test_invalid_timing_values():
	# Test attack and release times out of range
	var config = LaneSoundConfig.new()
	config.audio_bus = "Melody"
	
	# Test attack time
	config.attack_time = -0.1
	assert_false(config.validate_config())
	
	config.attack_time = 1.1
	assert_false(config.validate_config())
	
	config.attack_time = 0.5
	assert_true(config.validate_config())
	
	# Test release time
	config.release_time = -0.1
	assert_false(config.validate_config())
	
	config.release_time = 1.1
	assert_false(config.validate_config())
	
	config.release_time = 0.5
	assert_true(config.validate_config())

func test_loading_valid_config():
	# Test loading a valid configuration into lane sound system
	var config = LaneSoundConfig.new()
	config.waveform = SoundGenerator.WaveType.SQUARE
	config.audio_bus = "Melody"
	config.octave = 1
	config.root_note = SoundGenerator.Note.D
	config.volume = 0.7
	config.scale_type = SoundGenerator.Scale.MINOR
	config.scale_degree = 3
	config.config_name = "Test Config"
	
	# Load into left lane
	var success = lane_sound_system.load_lane_config(LaneSoundSystem.LaneType.LEFT, config)
	assert_true(success)
	
	# Verify configuration was applied
	assert_eq(lane_sound_system.get_lane_waveform(LaneSoundSystem.LaneType.LEFT), SoundGenerator.WaveType.SQUARE)
	assert_eq(lane_sound_system.get_lane_bus(LaneSoundSystem.LaneType.LEFT), "Melody")
	assert_eq(lane_sound_system.get_lane_octave(LaneSoundSystem.LaneType.LEFT), 1)
	assert_eq(lane_sound_system.get_lane_note(LaneSoundSystem.LaneType.LEFT), SoundGenerator.Note.D)
	assert_eq(lane_sound_system.get_lane_volume(LaneSoundSystem.LaneType.LEFT), 0.7)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.LEFT), 3)

func test_loading_invalid_config():
	# Test loading an invalid configuration
	var config = LaneSoundConfig.new()
	config.audio_bus = "InvalidBus"
	config.volume = 2.0  # Invalid
	
	# Try to load into center lane
	var success = lane_sound_system.load_lane_config(LaneSoundSystem.LaneType.CENTER, config)
	assert_false(success)

func test_loading_null_config():
	# Test loading null configuration
	var success = lane_sound_system.load_lane_config(LaneSoundSystem.LaneType.RIGHT, null)
	assert_false(success)

func test_loading_config_invalid_lane():
	# Test loading config into invalid lane
	var config = LaneSoundConfig.new()
	config.audio_bus = "Melody"
	
	# Try to load into invalid lane index
	var success = lane_sound_system.load_lane_config(999, config)
	assert_false(success)

func test_multiple_config_errors():
	# Test configuration with multiple errors
	var config = LaneSoundConfig.new()
	config.audio_bus = "InvalidBus"
	config.volume = -0.5
	config.octave = 10
	config.scale_degree = 0
	config.detune = 200.0
	config.attack_time = 2.0
	config.release_time = -1.0
	
	assert_false(config.validate_config())

func test_edge_case_values():
	# Test edge case values that should be valid
	var config = LaneSoundConfig.new()
	config.audio_bus = "Melody"
	
	# Test boundary values
	config.volume = 0.0
	assert_true(config.validate_config())
	
	config.volume = 1.0
	assert_true(config.validate_config())
	
	config.detune = -100.0
	assert_true(config.validate_config())
	
	config.detune = 100.0
	assert_true(config.validate_config())
	
	config.attack_time = 0.0
	assert_true(config.validate_config())
	
	config.attack_time = 1.0
	assert_true(config.validate_config())