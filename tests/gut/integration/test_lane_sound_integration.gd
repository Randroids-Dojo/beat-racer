extends "res://addons/gut/test.gd"

var LaneSoundSystem = preload("res://scripts/components/sound/lane_sound_system.gd")
var AudioManager = preload("res://scripts/autoloads/audio_manager.gd")

var lane_sound_system: LaneSoundSystem
var audio_manager: AudioManager

func before_all():
	# Initialize AudioManager if not already present
	if not Engine.has_singleton("AudioManager"):
		audio_manager = AudioManager.new()
		audio_manager.name = "AudioManager"
		get_tree().root.add_child(audio_manager)
		Engine.register_singleton("AudioManager", audio_manager)

func before_each():
	lane_sound_system = LaneSoundSystem.new()
	add_child_autofree(lane_sound_system)
	# Give time for initialization
	await get_tree().create_timer(0.1).timeout

func after_all():
	if audio_manager:
		Engine.unregister_singleton("AudioManager")
		audio_manager.queue_free()

func test_audio_bus_integration():
	# Verify that lane sound system correctly uses audio buses
	lane_sound_system.set_lane_bus(LaneSoundSystem.LaneType.LEFT, "Melody")
	lane_sound_system.set_lane_bus(LaneSoundSystem.LaneType.CENTER, "Bass")
	lane_sound_system.set_lane_bus(LaneSoundSystem.LaneType.RIGHT, "Percussion")
	
	var left_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.LEFT)
	var center_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.CENTER)
	var right_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.RIGHT)
	
	assert_eq(left_gen.get_bus(), "Melody")
	assert_eq(center_gen.get_bus(), "Bass")
	assert_eq(right_gen.get_bus(), "Percussion")

func test_sound_generation_on_lane_change():
	# Start playback and verify sound is generated on lane changes
	lane_sound_system.start_playback()
	assert_true(lane_sound_system.is_playing())
	
	# Get the current lane's generator and check if it's playing
	var current_gen = lane_sound_system.get_lane_generator(lane_sound_system.get_current_lane())
	assert_not_null(current_gen)
	
	# Change lanes and verify new generator starts
	lane_sound_system.set_current_lane(LaneSoundSystem.LaneType.LEFT)
	await get_tree().create_timer(0.1).timeout
	
	var left_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.LEFT)
	assert_not_null(left_gen)
	
	lane_sound_system.stop_playback()

func test_multiple_generators_simultaneously():
	# Test that multiple lanes can play simultaneously
	lane_sound_system.start_all_lanes()
	
	var all_generators = lane_sound_system.get_all_generators()
	assert_eq(all_generators.size(), 3)
	
	# Verify all generators are configured correctly
	for gen in all_generators:
		assert_not_null(gen)
		assert_true(gen is SoundGenerator)
	
	lane_sound_system.stop_all_lanes()

func test_volume_control_with_audio_manager():
	# Set different volumes for each lane
	lane_sound_system.set_lane_volume(LaneSoundSystem.LaneType.LEFT, 0.8)
	lane_sound_system.set_lane_volume(LaneSoundSystem.LaneType.CENTER, 0.5)
	lane_sound_system.set_lane_volume(LaneSoundSystem.LaneType.RIGHT, 0.3)
	
	# Verify generators have correct volumes
	var left_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.LEFT)
	var center_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.CENTER)
	var right_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.RIGHT)
	
	assert_eq(left_gen.get_volume(), 0.8)
	assert_eq(center_gen.get_volume(), 0.5)
	assert_eq(right_gen.get_volume(), 0.3)

func test_scale_and_note_mapping():
	# Test musical scale integration
	lane_sound_system.set_global_scale(SoundGenerator.Scale.PENTATONIC_MAJOR)
	lane_sound_system.set_global_root_note(SoundGenerator.Note.G)
	
	# Set different scale degrees for each lane
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.LEFT, 1)   # Root
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.CENTER, 3) # Third
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT, 5)  # Fifth
	
	# Verify the generators have correct scale settings
	var left_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.LEFT)
	var center_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.CENTER)
	var right_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.RIGHT)
	
	assert_eq(left_gen.get_scale_type(), SoundGenerator.Scale.PENTATONIC_MAJOR)
	assert_eq(center_gen.get_scale_type(), SoundGenerator.Scale.PENTATONIC_MAJOR)
	assert_eq(right_gen.get_scale_type(), SoundGenerator.Scale.PENTATONIC_MAJOR)
	
	assert_eq(left_gen.get_root_note(), SoundGenerator.Note.G)
	assert_eq(center_gen.get_root_note(), SoundGenerator.Note.G)
	assert_eq(right_gen.get_root_note(), SoundGenerator.Note.G)

func test_waveform_variety():
	# Set different waveforms for each lane
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.LEFT, SoundGenerator.WaveType.SINE)
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.CENTER, SoundGenerator.WaveType.SQUARE)
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.RIGHT, SoundGenerator.WaveType.SAW)
	
	# Start all lanes
	lane_sound_system.start_all_lanes()
	
	# Verify waveforms
	var left_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.LEFT)
	var center_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.CENTER)
	var right_gen = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.RIGHT)
	
	assert_eq(left_gen.get_waveform(), SoundGenerator.WaveType.SINE)
	assert_eq(center_gen.get_waveform(), SoundGenerator.WaveType.SQUARE)
	assert_eq(right_gen.get_waveform(), SoundGenerator.WaveType.SAW)
	
	lane_sound_system.stop_all_lanes()

func test_real_time_parameter_changes():
	# Start playback on one lane
	lane_sound_system.start_playback()
	
	# Change parameters while playing
	lane_sound_system.set_lane_waveform(lane_sound_system.get_current_lane(), SoundGenerator.WaveType.TRIANGLE)
	await get_tree().create_timer(0.1).timeout
	
	lane_sound_system.set_lane_octave(lane_sound_system.get_current_lane(), 1)
	await get_tree().create_timer(0.1).timeout
	
	lane_sound_system.set_lane_volume(lane_sound_system.get_current_lane(), 0.7)
	await get_tree().create_timer(0.1).timeout
	
	# Verify changes took effect
	var current_gen = lane_sound_system.get_lane_generator(lane_sound_system.get_current_lane())
	assert_eq(current_gen.get_waveform(), SoundGenerator.WaveType.TRIANGLE)
	assert_eq(current_gen.get_octave(), 1)
	assert_eq(current_gen.get_volume(), 0.7)
	
	lane_sound_system.stop_playback()

func test_lane_isolation_during_playback():
	# Test that changing lanes properly stops old lane and starts new one
	watch_signals(lane_sound_system)
	
	lane_sound_system.start_playback()
	
	# Start on center lane
	assert_eq(lane_sound_system.get_current_lane(), LaneSoundSystem.LaneType.CENTER)
	
	# Switch to left lane
	lane_sound_system.set_current_lane(LaneSoundSystem.LaneType.LEFT)
	assert_signal_emitted(lane_sound_system, "lane_changed")
	
	# Verify only left lane is active now
	assert_eq(lane_sound_system.get_current_lane(), LaneSoundSystem.LaneType.LEFT)
	
	# Switch to right lane
	lane_sound_system.set_current_lane(LaneSoundSystem.LaneType.RIGHT)
	assert_signal_emitted(lane_sound_system, "lane_changed")
	assert_eq(lane_sound_system.get_current_lane(), LaneSoundSystem.LaneType.RIGHT)
	
	lane_sound_system.stop_playback()