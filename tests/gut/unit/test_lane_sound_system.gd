extends "res://addons/gut/test.gd"

var LaneSoundSystem = preload("res://scripts/components/sound/lane_sound_system.gd")
var lane_sound_system: LaneSoundSystem

func before_each():
	lane_sound_system = LaneSoundSystem.new()
	add_child_autofree(lane_sound_system)

func test_initialization():
	assert_not_null(lane_sound_system)
	assert_eq(lane_sound_system.get_current_lane(), LaneSoundSystem.LaneType.CENTER)
	assert_false(lane_sound_system.is_playing())

func test_lane_switching():
	# Test changing lanes
	lane_sound_system.set_current_lane(LaneSoundSystem.LaneType.LEFT)
	assert_eq(lane_sound_system.get_current_lane(), LaneSoundSystem.LaneType.LEFT)
	
	lane_sound_system.set_current_lane(LaneSoundSystem.LaneType.RIGHT)
	assert_eq(lane_sound_system.get_current_lane(), LaneSoundSystem.LaneType.RIGHT)
	
	# Test invalid lane
	lane_sound_system.set_current_lane(3)
	assert_eq(lane_sound_system.get_current_lane(), LaneSoundSystem.LaneType.RIGHT)  # Should not change

func test_lane_configuration():
	# Test waveform configuration
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.LEFT, SoundGenerator.WaveType.SQUARE)
	assert_eq(lane_sound_system.get_lane_waveform(LaneSoundSystem.LaneType.LEFT), SoundGenerator.WaveType.SQUARE)
	
	# Test bus configuration
	lane_sound_system.set_lane_bus(LaneSoundSystem.LaneType.CENTER, "Percussion")
	assert_eq(lane_sound_system.get_lane_bus(LaneSoundSystem.LaneType.CENTER), "Percussion")
	
	# Test octave configuration
	lane_sound_system.set_lane_octave(LaneSoundSystem.LaneType.RIGHT, 2)
	assert_eq(lane_sound_system.get_lane_octave(LaneSoundSystem.LaneType.RIGHT), 2)
	
	# Test note configuration
	lane_sound_system.set_lane_note(LaneSoundSystem.LaneType.LEFT, SoundGenerator.Note.F)
	assert_eq(lane_sound_system.get_lane_note(LaneSoundSystem.LaneType.LEFT), SoundGenerator.Note.F)
	
	# Test volume configuration
	lane_sound_system.set_lane_volume(LaneSoundSystem.LaneType.CENTER, 0.8)
	assert_eq(lane_sound_system.get_lane_volume(LaneSoundSystem.LaneType.CENTER), 0.8)

func test_global_configuration():
	# Test global scale
	lane_sound_system.set_global_scale(SoundGenerator.Scale.MINOR)
	assert_eq(lane_sound_system.get_global_scale(), SoundGenerator.Scale.MINOR)
	
	# Test global root note
	lane_sound_system.set_global_root_note(SoundGenerator.Note.D)
	assert_eq(lane_sound_system.get_global_root_note(), SoundGenerator.Note.D)
	
	# Test global volume
	lane_sound_system.set_global_volume(0.7)
	assert_eq(lane_sound_system.get_global_volume(), 0.7)

func test_scale_degree_mapping():
	# Test setting scale degrees for lanes
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.LEFT, 3)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.LEFT), 3)
	
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT, 5)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT), 5)

func test_playback_control():
	# Test single lane playback
	assert_false(lane_sound_system.is_playing())
	
	lane_sound_system.start_playback()
	assert_true(lane_sound_system.is_playing())
	
	lane_sound_system.stop_playback()
	assert_false(lane_sound_system.is_playing())
	
	# Test all lanes playback
	lane_sound_system.start_all_lanes()
	assert_true(lane_sound_system.is_playing())
	
	lane_sound_system.stop_all_lanes()
	assert_false(lane_sound_system.is_playing())

func test_mute_functionality():
	# Test muting individual lanes
	var original_volume = lane_sound_system.get_lane_volume(LaneSoundSystem.LaneType.LEFT)
	
	lane_sound_system.mute_lane(LaneSoundSystem.LaneType.LEFT, true)
	var left_generator = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.LEFT)
	assert_eq(left_generator.get_volume(), 0.0)
	
	lane_sound_system.mute_lane(LaneSoundSystem.LaneType.LEFT, false)
	assert_eq(left_generator.get_volume(), original_volume)

func test_generator_access():
	# Test accessing individual generators
	var left_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.LEFT)
	assert_not_null(left_gen)
	assert_true(left_gen is SoundGenerator)
	
	var all_gens = lane_sound_system.get_all_generators()
	assert_eq(all_gens.size(), 3)
	
	for gen in all_gens:
		assert_true(gen is SoundGenerator)

func test_signal_emission():
	# Test lane change signal
	watch_signals(lane_sound_system)
	
	lane_sound_system.set_current_lane(LaneSoundSystem.LaneType.LEFT)
	assert_signal_emitted(lane_sound_system, "lane_changed")
	
	var signal_params = get_signal_parameters(lane_sound_system, "lane_changed", 0)
	if signal_params != null:
		assert_eq(signal_params[0], LaneSoundSystem.LaneType.CENTER)  # old lane
		assert_eq(signal_params[1], LaneSoundSystem.LaneType.LEFT)    # new lane

func test_lane_sound_isolation():
	# Test that changing one lane doesn't affect others
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.LEFT, SoundGenerator.WaveType.SAW)
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.CENTER, SoundGenerator.WaveType.SINE)
	
	assert_eq(lane_sound_system.get_lane_waveform(LaneSoundSystem.LaneType.LEFT), SoundGenerator.WaveType.SAW)
	assert_eq(lane_sound_system.get_lane_waveform(LaneSoundSystem.LaneType.CENTER), SoundGenerator.WaveType.SINE)
	assert_eq(lane_sound_system.get_lane_waveform(LaneSoundSystem.LaneType.RIGHT), SoundGenerator.WaveType.TRIANGLE)  # Default

func test_bpm_property():
	# Test BPM getter and setter
	var default_bpm = lane_sound_system.get_bpm()
	assert_eq(default_bpm, 120.0)  # Default value
	
	# Test setting valid BPM
	lane_sound_system.set_bpm(140.0)
	assert_eq(lane_sound_system.get_bpm(), 140.0)
	
	# Test edge cases
	lane_sound_system.set_bpm(60.0)  # Slow
	assert_eq(lane_sound_system.get_bpm(), 60.0)
	
	lane_sound_system.set_bpm(240.0)  # Fast
	assert_eq(lane_sound_system.get_bpm(), 240.0)
	
	# Test invalid BPM (should not change)
	var current_bpm = lane_sound_system.get_bpm()
	lane_sound_system.set_bpm(0.0)
	assert_eq(lane_sound_system.get_bpm(), current_bpm)
	
	lane_sound_system.set_bpm(-10.0)
	assert_eq(lane_sound_system.get_bpm(), current_bpm)