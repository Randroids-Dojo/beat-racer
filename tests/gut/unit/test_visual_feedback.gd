extends "res://addons/gut/test.gd"

const RhythmFeedbackManager = preload("res://scripts/components/visual/rhythm_feedback_manager.gd")
const PerfectHitIndicator = preload("res://scripts/components/visual/perfect_hit_indicator.gd")
const MissIndicator = preload("res://scripts/components/visual/miss_indicator.gd")
const BeatIndicator = preload("res://scripts/components/visual/beat_indicator.gd")

var rhythm_feedback_manager
var perfect_hit_indicator
var miss_indicator
var beat_indicator

func before_each():
	# Create fresh instances for each test
	rhythm_feedback_manager = RhythmFeedbackManager.new()
	perfect_hit_indicator = PerfectHitIndicator.new()
	miss_indicator = MissIndicator.new()
	beat_indicator = BeatIndicator.new()
	
	# Add to scene tree
	add_child_autofree(rhythm_feedback_manager)
	add_child_autofree(perfect_hit_indicator)
	add_child_autofree(miss_indicator)
	add_child_autofree(beat_indicator)

func test_rhythm_feedback_manager_initialization():
	assert_not_null(rhythm_feedback_manager)
	assert_eq(rhythm_feedback_manager.get_current_combo(), 0)
	assert_eq(rhythm_feedback_manager.get_best_combo(), 0)
	assert_false(rhythm_feedback_manager.is_perfect_streak())

func test_perfect_hit_detection():
	# Test perfect timing window
	var quality = rhythm_feedback_manager._evaluate_timing(0.04)  # 40ms
	assert_eq(quality, RhythmFeedbackManager.HitQuality.PERFECT)
	
	# Test good timing window
	quality = rhythm_feedback_manager._evaluate_timing(0.1)  # 100ms
	assert_eq(quality, RhythmFeedbackManager.HitQuality.GOOD)
	
	# Test ok timing window
	quality = rhythm_feedback_manager._evaluate_timing(0.2)  # 200ms
	assert_eq(quality, RhythmFeedbackManager.HitQuality.OK)
	
	# Test miss
	quality = rhythm_feedback_manager._evaluate_timing(0.4)  # 400ms
	assert_eq(quality, RhythmFeedbackManager.HitQuality.MISS)

func test_combo_system():
	# Simulate perfect hits
	watch_signals(rhythm_feedback_manager)
	
	# Register perfect hit
	var quality = rhythm_feedback_manager.register_player_input(0)
	rhythm_feedback_manager._on_beat_occurred(1, Time.get_ticks_msec() / 1000.0)
	
	assert_signal_emitted(rhythm_feedback_manager, "combo_updated")
	assert_eq(rhythm_feedback_manager.get_current_combo(), 1)

func test_streak_tracking():
	# Test perfect streak
	# First, register an input close to the beat time
	rhythm_feedback_manager._last_input_time = 0.02  # Very close to beat time
	rhythm_feedback_manager._on_beat_occurred(1, 0.0)  # Beat occurs at time 0
	assert_eq(rhythm_feedback_manager._perfect_streak, 1)
	
	# Register another perfect hit
	rhythm_feedback_manager._last_input_time = 1.03  # Close to beat at 1.0
	rhythm_feedback_manager._on_beat_occurred(2, 1.0)
	assert_eq(rhythm_feedback_manager._perfect_streak, 2)
	
	# Break streak with miss
	rhythm_feedback_manager._last_input_time = 1.8  # Far from beat at 2.0
	rhythm_feedback_manager._on_beat_occurred(3, 2.0)
	assert_eq(rhythm_feedback_manager._perfect_streak, 0)

func test_performance_stats():
	# Register some hits and misses
	rhythm_feedback_manager._on_beat_occurred(1, 0.0)
	rhythm_feedback_manager._on_beat_occurred(2, 1.0)
	rhythm_feedback_manager._on_beat_occurred(3, 2.0)
	
	var stats = rhythm_feedback_manager.get_performance_stats()
	assert_has(stats, "total_beats")
	assert_has(stats, "perfect_beats")
	assert_has(stats, "accuracy")
	assert_has(stats, "current_combo")

func test_multiplier_calculation():
	# Test different combo levels
	rhythm_feedback_manager._current_combo = 0
	assert_eq(rhythm_feedback_manager.get_multiplier(), 1.0)
	
	rhythm_feedback_manager._current_combo = 5
	assert_eq(rhythm_feedback_manager.get_multiplier(), 1.5)
	
	rhythm_feedback_manager._current_combo = 10
	assert_eq(rhythm_feedback_manager.get_multiplier(), 2.0)
	
	rhythm_feedback_manager._current_combo = 25
	assert_eq(rhythm_feedback_manager.get_multiplier(), 3.0)
	
	rhythm_feedback_manager._current_combo = 50
	assert_eq(rhythm_feedback_manager.get_multiplier(), 4.0)

func test_perfect_hit_indicator_trigger():
	# Test triggering perfect hit effect
	var test_position = Vector2(100, 100)
	perfect_hit_indicator.trigger_perfect_hit(RhythmFeedbackManager.HitQuality.PERFECT, test_position)
	
	assert_true(perfect_hit_indicator.visible)
	assert_eq(perfect_hit_indicator.global_position, test_position)

func test_miss_indicator_trigger():
	# Test triggering miss effect
	var test_position = Vector2(200, 200)
	miss_indicator.trigger_miss(test_position)
	
	assert_true(miss_indicator.visible)
	assert_eq(miss_indicator.global_position, test_position)

func test_beat_indicator_streak_effects():
	# Enable streak effects
	beat_indicator.enable_streak_effects = true
	
	# Test normal pulse
	beat_indicator.trigger_pulse()
	assert_true(beat_indicator.is_pulsing())
	
	# Test streak pulse
	beat_indicator.trigger_streak_pulse(5)
	assert_eq(beat_indicator._streak_count, 5)
	assert_true(beat_indicator.is_pulsing())

func test_color_variations():
	# Test quality colors
	var perfect_color = rhythm_feedback_manager.get_timing_color(RhythmFeedbackManager.HitQuality.PERFECT)
	var good_color = rhythm_feedback_manager.get_timing_color(RhythmFeedbackManager.HitQuality.GOOD)
	var miss_color = rhythm_feedback_manager.get_timing_color(RhythmFeedbackManager.HitQuality.MISS)
	
	assert_ne(perfect_color, good_color)
	assert_ne(good_color, miss_color)
	assert_ne(perfect_color, miss_color)

func test_reset_functionality():
	# Set up some state
	rhythm_feedback_manager._current_combo = 10
	rhythm_feedback_manager._best_combo = 15
	rhythm_feedback_manager._perfect_beats = 5
	
	# Reset
	rhythm_feedback_manager.reset_stats()
	
	# Verify reset
	assert_eq(rhythm_feedback_manager.get_current_combo(), 0)
	assert_eq(rhythm_feedback_manager.get_best_combo(), 0)
	assert_eq(rhythm_feedback_manager._perfect_beats, 0)

func test_visual_indicator_pooling():
	# Test particle pooling in perfect hit indicator
	assert_true(perfect_hit_indicator._particle_pool.size() > 0)
	
	# Trigger effect to use particles
	perfect_hit_indicator.trigger_perfect_hit(RhythmFeedbackManager.HitQuality.PERFECT, Vector2.ZERO)
	
	# Particles should still be in pool
	assert_true(perfect_hit_indicator._particle_pool.size() > 0)

func test_beat_indicator_enhanced_methods():
	# Test enhanced feedback methods
	beat_indicator._on_perfect_hit(0.02, 0)
	assert_true(beat_indicator._is_perfect_pulse)
	assert_eq(beat_indicator._current_color, beat_indicator.perfect_color)
	
	# Test combo update
	beat_indicator._on_combo_updated(10)
	assert_eq(beat_indicator._streak_count, 10)
	
	# Test streak broken
	beat_indicator._on_streak_broken()
	assert_eq(beat_indicator._streak_count, 0)
	assert_eq(beat_indicator._multiplier, 1.0)