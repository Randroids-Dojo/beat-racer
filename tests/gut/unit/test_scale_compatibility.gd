## Scale Compatibility Test Suite
## Tests all supported musical scales with the lane sound system
## to ensure proper note generation and scale degree mapping

extends "res://addons/gut/test.gd"

var LaneSoundSystem = preload("res://scripts/components/sound/lane_sound_system.gd")
var SoundGenerator = preload("res://scripts/components/sound/sound_generator.gd")
var lane_sound_system: LaneSoundSystem

func before_each():
	lane_sound_system = LaneSoundSystem.new()
	add_child_autofree(lane_sound_system)

func test_all_scales_supported():
	# Test that all scale types can be set without errors
	var scale_types = [
		SoundGenerator.Scale.MAJOR,
		SoundGenerator.Scale.MINOR,
		SoundGenerator.Scale.PENTATONIC_MAJOR,
		SoundGenerator.Scale.PENTATONIC_MINOR,
		SoundGenerator.Scale.BLUES,
		SoundGenerator.Scale.CHROMATIC
	]
	
	for scale in scale_types:
		lane_sound_system.set_global_scale(scale)
		assert_eq(lane_sound_system.get_global_scale(), scale, "Failed to set scale: " + str(scale))

func test_scale_degree_boundaries():
	# Test scale degree limits for each scale type
	var scale_degrees = {
		SoundGenerator.Scale.MAJOR: 7,
		SoundGenerator.Scale.MINOR: 7,
		SoundGenerator.Scale.PENTATONIC_MAJOR: 5,
		SoundGenerator.Scale.PENTATONIC_MINOR: 5,
		SoundGenerator.Scale.BLUES: 6,
		SoundGenerator.Scale.CHROMATIC: 12
	}
	
	for scale in scale_degrees:
		lane_sound_system.set_global_scale(scale)
		var max_degree = scale_degrees[scale]
		
		# Test valid degrees
		for degree in range(1, max_degree + 1):
			lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.LEFT, degree)
			assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.LEFT), degree)

func test_scale_with_different_root_notes():
	# Test all scales with different root notes
	var root_notes = [
		SoundGenerator.Note.C,
		SoundGenerator.Note.C_SHARP,
		SoundGenerator.Note.D,
		SoundGenerator.Note.D_SHARP,
		SoundGenerator.Note.E,
		SoundGenerator.Note.F,
		SoundGenerator.Note.F_SHARP,
		SoundGenerator.Note.G,
		SoundGenerator.Note.G_SHARP,
		SoundGenerator.Note.A,
		SoundGenerator.Note.A_SHARP,
		SoundGenerator.Note.B
	]
	
	var scale_types = [
		SoundGenerator.Scale.MAJOR,
		SoundGenerator.Scale.MINOR,
		SoundGenerator.Scale.PENTATONIC_MAJOR,
		SoundGenerator.Scale.PENTATONIC_MINOR,
		SoundGenerator.Scale.BLUES,
		SoundGenerator.Scale.CHROMATIC
	]
	
	for scale in scale_types:
		for root_note in root_notes:
			lane_sound_system.set_global_scale(scale)
			lane_sound_system.set_global_root_note(root_note)
			
			assert_eq(lane_sound_system.get_global_scale(), scale)
			assert_eq(lane_sound_system.get_global_root_note(), root_note)
			
			# Verify all lanes received the update
			for lane in LaneSoundSystem.LaneType.values():
				assert_eq(lane_sound_system.get_lane_note(lane), root_note)

func test_octave_range_with_scales():
	# Test octave settings with different scales
	var octave_range = range(-3, 4)  # -3 to 3
	var scale_types = [
		SoundGenerator.Scale.MAJOR,
		SoundGenerator.Scale.MINOR,
		SoundGenerator.Scale.PENTATONIC_MAJOR
	]
	
	for scale in scale_types:
		lane_sound_system.set_global_scale(scale)
		
		for octave in octave_range:
			lane_sound_system.set_lane_octave(LaneSoundSystem.LaneType.CENTER, octave)
			assert_eq(lane_sound_system.get_lane_octave(LaneSoundSystem.LaneType.CENTER), octave)

func test_multi_lane_scale_harmony():
	# Test harmonic relationships between lanes using scale degrees
	lane_sound_system.set_global_scale(SoundGenerator.Scale.MAJOR)
	lane_sound_system.set_global_root_note(SoundGenerator.Note.C)
	
	# Set up a common chord progression (I-III-V)
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.LEFT, 1)   # Root
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.CENTER, 3) # Third
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT, 5)  # Fifth
	
	# Verify degrees are set correctly
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.LEFT), 1)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.CENTER), 3)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT), 5)
	
	# Test with different scales
	lane_sound_system.set_global_scale(SoundGenerator.Scale.MINOR)
	
	# Degrees should remain the same (but produce different notes)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.LEFT), 1)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.CENTER), 3)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT), 5)

func test_scale_transition_during_playback():
	# Test changing scales while playing
	lane_sound_system.start_all_lanes()
	assert_true(lane_sound_system.is_playing())
	
	# Change scale during playback
	var initial_scale = SoundGenerator.Scale.MAJOR
	var new_scale = SoundGenerator.Scale.MINOR
	
	lane_sound_system.set_global_scale(initial_scale)
	assert_eq(lane_sound_system.get_global_scale(), initial_scale)
	
	# Wait a moment
	await get_tree().create_timer(0.1).timeout
	
	# Change scale
	lane_sound_system.set_global_scale(new_scale)
	assert_eq(lane_sound_system.get_global_scale(), new_scale)
	
	# Verify all generators received the update
	for lane in LaneSoundSystem.LaneType.values():
		var generator = lane_sound_system.get_lane_generator(lane)
		assert_eq(generator.get_scale_type(), new_scale)
	
	lane_sound_system.stop_all_lanes()

func test_chromatic_scale_special_case():
	# Chromatic scale should support all 12 semitones
	lane_sound_system.set_global_scale(SoundGenerator.Scale.CHROMATIC)
	
	for degree in range(1, 13):  # 1 to 12
		lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.LEFT, degree)
		assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.LEFT), degree)

func test_blues_scale_special_notes():
	# Blues scale has 6 notes (including the blue note)
	lane_sound_system.set_global_scale(SoundGenerator.Scale.BLUES)
	
	for degree in range(1, 7):  # 1 to 6
		lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.CENTER, degree)
		assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.CENTER), degree)

func test_pentatonic_scale_limitations():
	# Pentatonic scales only have 5 notes
	var pentatonic_scales = [
		SoundGenerator.Scale.PENTATONIC_MAJOR,
		SoundGenerator.Scale.PENTATONIC_MINOR
	]
	
	for scale in pentatonic_scales:
		lane_sound_system.set_global_scale(scale)
		
		# Test valid degrees (1-5)
		for degree in range(1, 6):
			lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT, degree)
			assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT), degree)

func test_scale_with_extreme_octaves():
	# Test scales at extreme octave ranges
	var extreme_octaves = [-3, -2, 0, 2, 3]
	var scale_types = [
		SoundGenerator.Scale.MAJOR,
		SoundGenerator.Scale.MINOR,
		SoundGenerator.Scale.CHROMATIC
	]
	
	for scale in scale_types:
		lane_sound_system.set_global_scale(scale)
		
		for octave in extreme_octaves:
			lane_sound_system.set_lane_octave(LaneSoundSystem.LaneType.LEFT, octave)
			assert_eq(lane_sound_system.get_lane_octave(LaneSoundSystem.LaneType.LEFT), octave)
			
			# Verify generator received the update
			var generator = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.LEFT)
			assert_eq(generator.get_octave(), octave)

func test_scale_integration_with_waveforms():
	# Test different scales with different waveforms
	var waveforms = [
		SoundGenerator.WaveType.SINE,
		SoundGenerator.WaveType.SQUARE,
		SoundGenerator.WaveType.TRIANGLE,
		SoundGenerator.WaveType.SAW
	]
	
	var scales = [
		SoundGenerator.Scale.MAJOR,
		SoundGenerator.Scale.MINOR
	]
	
	for scale in scales:
		for waveform in waveforms:
			lane_sound_system.set_global_scale(scale)
			lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.CENTER, waveform)
			
			var generator = lane_sound_system.get_lane_generator(LaneSoundSystem.LaneType.CENTER)
			assert_eq(generator.get_scale_type(), scale)
			assert_eq(generator.get_waveform(), waveform)

func test_scale_configuration_persistence():
	# Test that scale configurations persist through playback state changes
	var test_scale = SoundGenerator.Scale.PENTATONIC_MAJOR
	var test_root = SoundGenerator.Note.G
	var test_degree = 3
	
	# Set up configuration
	lane_sound_system.set_global_scale(test_scale)
	lane_sound_system.set_global_root_note(test_root)
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.LEFT, test_degree)
	
	# Start and stop playback
	lane_sound_system.start_playback()
	await get_tree().create_timer(0.1).timeout
	lane_sound_system.stop_playback()
	
	# Verify configuration persisted
	assert_eq(lane_sound_system.get_global_scale(), test_scale)
	assert_eq(lane_sound_system.get_global_root_note(), test_root)
	assert_eq(lane_sound_system.get_lane_scale_degree(LaneSoundSystem.LaneType.LEFT), test_degree)