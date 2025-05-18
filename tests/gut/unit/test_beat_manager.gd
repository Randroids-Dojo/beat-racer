extends "res://addons/gut/test.gd"

var BeatManager = preload("res://scripts/autoloads/beat_manager.gd")
var beat_manager: BeatManager

func before_each():
	beat_manager = BeatManager.new()
	add_child_autofree(beat_manager)
	# Disable debug logging for tests
	beat_manager._debug_logging = false

func test_initialization():
	assert_not_null(beat_manager)
	assert_eq(beat_manager.bpm, BeatManager.DEFAULT_BPM)
	assert_eq(beat_manager.beats_per_measure, BeatManager.DEFAULT_BEATS_PER_MEASURE)
	assert_false(beat_manager.is_playing)
	assert_eq(beat_manager.current_beat, 0)
	assert_eq(beat_manager.current_measure, 0)

func test_bpm_property():
	# Test BPM setter/getter
	beat_manager.bpm = 140.0
	assert_eq(beat_manager.bpm, 140.0)
	
	# Test BPM clamping
	beat_manager.bpm = 30.0  # Below minimum
	assert_eq(beat_manager.bpm, BeatManager.MIN_BPM)
	
	beat_manager.bpm = 300.0  # Above maximum
	assert_eq(beat_manager.bpm, BeatManager.MAX_BPM)
	
	# Test signal emission
	watch_signals(beat_manager)
	var old_bpm = beat_manager.bpm
	beat_manager.bpm = 120.0
	assert_signal_emitted(beat_manager, "bpm_changed")
	var params = get_signal_parameters(beat_manager, "bpm_changed", 0)
	assert_eq(params[0], old_bpm)
	assert_eq(params[1], 120.0)

func test_beats_per_measure():
	# Test setter/getter
	beat_manager.beats_per_measure = 3
	assert_eq(beat_manager.beats_per_measure, 3)
	
	# Test minimum value
	beat_manager.beats_per_measure = 0
	assert_eq(beat_manager.beats_per_measure, 1)
	
	# Test signal emission
	watch_signals(beat_manager)
	beat_manager.beats_per_measure = 4
	assert_signal_emitted(beat_manager, "time_signature_changed")

func test_beat_duration_calculation():
	beat_manager.bpm = 120.0
	assert_almost_eq(beat_manager.beat_duration, 0.5, 0.001)
	assert_almost_eq(beat_manager.half_beat_duration, 0.25, 0.001)
	
	beat_manager.bpm = 60.0
	assert_almost_eq(beat_manager.beat_duration, 1.0, 0.001)
	assert_almost_eq(beat_manager.half_beat_duration, 0.5, 0.001)

func test_start_stop():
	assert_false(beat_manager.is_playing)
	
	beat_manager.start()
	assert_true(beat_manager.is_playing)
	assert_eq(beat_manager.current_beat, 0)
	assert_eq(beat_manager.current_measure, 0)
	
	beat_manager.stop()
	assert_false(beat_manager.is_playing)

func test_reset():
	beat_manager.start()
	beat_manager.current_beat = 3
	beat_manager.current_measure = 2
	beat_manager.total_beats = 10
	
	beat_manager.reset()
	assert_false(beat_manager.is_playing)
	assert_eq(beat_manager.current_beat, 0)
	assert_eq(beat_manager.current_measure, 0)
	assert_eq(beat_manager.total_beats, 0)
	assert_eq(beat_manager.time_since_last_beat, 0.0)

func test_beat_progress():
	beat_manager.start()
	beat_manager.beat_duration = 1.0
	
	# At start of beat
	beat_manager.time_since_last_beat = 0.0
	assert_almost_eq(beat_manager.get_beat_progress(), 0.0, 0.001)
	
	# Halfway through beat
	beat_manager.time_since_last_beat = 0.5
	assert_almost_eq(beat_manager.get_beat_progress(), 0.5, 0.001)
	
	# End of beat
	beat_manager.time_since_last_beat = 1.0
	assert_almost_eq(beat_manager.get_beat_progress(), 1.0, 0.001)

func test_time_to_next_beat():
	beat_manager.start()
	beat_manager.beat_duration = 1.0
	
	beat_manager.time_since_last_beat = 0.2
	assert_almost_eq(beat_manager.get_time_to_next_beat(), 0.8, 0.001)
	
	beat_manager.time_since_last_beat = 0.9
	assert_almost_eq(beat_manager.get_time_to_next_beat(), 0.1, 0.001)

func test_is_on_beat():
	beat_manager.start()
	beat_manager.beat_duration = 1.0
	
	# At start of beat
	beat_manager.time_since_last_beat = 0.05
	assert_true(beat_manager.is_on_beat(0.1))
	assert_false(beat_manager.is_on_beat(0.01))
	
	# Near end of beat
	beat_manager.time_since_last_beat = 0.95
	assert_true(beat_manager.is_on_beat(0.1))
	assert_false(beat_manager.is_on_beat(0.01))
	
	# Middle of beat
	beat_manager.time_since_last_beat = 0.5
	assert_false(beat_manager.is_on_beat(0.1))

func test_audio_offset():
	beat_manager.set_audio_offset(50.0)  # 50ms
	assert_almost_eq(beat_manager.get_audio_offset(), 50.0, 0.001)
	
	beat_manager.set_audio_offset(-20.0)  # -20ms
	assert_almost_eq(beat_manager.get_audio_offset(), -20.0, 0.001)

func test_beat_intensity():
	watch_signals(beat_manager)
	
	beat_manager.set_beat_intensity(0.8)
	assert_almost_eq(beat_manager.get_beat_intensity(), 0.8, 0.001)
	assert_signal_emitted(beat_manager, "beat_intensity_changed")
	
	# Test clamping
	beat_manager.set_beat_intensity(1.5)
	assert_eq(beat_manager.get_beat_intensity(), 1.0)
	
	beat_manager.set_beat_intensity(-0.5)
	assert_eq(beat_manager.get_beat_intensity(), 0.0)

func test_utility_methods():
	beat_manager.beat_duration = 0.5
	
	# Beats to seconds
	assert_almost_eq(beat_manager.beats_to_seconds(4.0), 2.0, 0.001)
	assert_almost_eq(beat_manager.beats_to_seconds(1.5), 0.75, 0.001)
	
	# Seconds to beats
	assert_almost_eq(beat_manager.seconds_to_beats(2.0), 4.0, 0.001)
	assert_almost_eq(beat_manager.seconds_to_beats(0.75), 1.5, 0.001)

func test_beat_signals():
	watch_signals(beat_manager)
	beat_manager.start()
	
	# Simulate beat
	beat_manager._process_beat()
	
	assert_signal_emitted(beat_manager, "beat_occurred")
	var params = get_signal_parameters(beat_manager, "beat_occurred", 0)
	assert_eq(params[0], 1)  # Beat number
	assert_true(params[1] is float)  # Beat time

func test_measure_signals():
	watch_signals(beat_manager)
	beat_manager.start()
	beat_manager.beats_per_measure = 4
	
	# Process 4 beats to complete a measure
	for i in range(4):
		beat_manager._process_beat()
	
	assert_signal_emitted(beat_manager, "measure_completed")
	var params = get_signal_parameters(beat_manager, "measure_completed", 0)
	assert_eq(params[0], 1)  # Measure number
	assert_true(params[1] is float)  # Measure time

func test_half_beat_processing():
	watch_signals(beat_manager)
	beat_manager.start()
	beat_manager.half_beat_duration = 0.25
	
	# Simulate half beat
	beat_manager.time_since_last_half_beat = 0.25
	beat_manager._process_half_beat()
	
	assert_signal_emitted(beat_manager, "half_beat_occurred")
	assert_eq(beat_manager.current_half_beat, 1)

func test_beat_accuracy():
	beat_manager.total_beats = 100
	beat_manager._missed_beats = 5
	
	assert_almost_eq(beat_manager.get_beat_accuracy(), 95.0, 0.001)
	
	# Test with no beats
	beat_manager.total_beats = 0
	assert_eq(beat_manager.get_beat_accuracy(), 100.0)