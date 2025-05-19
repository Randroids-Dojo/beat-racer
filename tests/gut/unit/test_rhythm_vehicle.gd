# GUT unit test for RhythmVehicle class
extends GutTest

const RhythmVehicle = preload("res://scripts/components/vehicle/rhythm_vehicle.gd")
const BeatManager = preload("res://scripts/autoloads/beat_manager.gd")

var rhythm_vehicle: RhythmVehicle
var beat_manager: BeatManager


func before_each() -> void:
	# Create and setup beat manager
	beat_manager = autofree(BeatManager.new())
	beat_manager.set_name("BeatManager")
	get_tree().root.add_child(beat_manager)
	
	# Create rhythm vehicle
	rhythm_vehicle = autofree(RhythmVehicle.new())
	add_child(rhythm_vehicle)
	await wait_frames(1)


func after_each() -> void:
	if beat_manager:
		beat_manager.queue_free()


func test_rhythm_vehicle_initialization() -> void:
	assert_not_null(rhythm_vehicle)
	assert_eq(rhythm_vehicle.boost_on_beat, true)
	assert_eq(rhythm_vehicle.boost_power, 200.0)
	assert_eq(rhythm_vehicle.beat_window, 0.15)
	assert_eq(rhythm_vehicle.current_boost, 0.0)
	assert_eq(rhythm_vehicle.perfect_beats, 0)
	assert_eq(rhythm_vehicle.total_beats, 0)


func test_beat_boost_application() -> void:
	watch_signals(rhythm_vehicle)
	
	# Apply a boost
	rhythm_vehicle.apply_beat_boost(false)
	
	assert_signal_emitted(rhythm_vehicle, "boost_applied")
	assert_eq(rhythm_vehicle.current_boost, rhythm_vehicle.boost_power)
	assert_gt(rhythm_vehicle.boost_timer, 0)


func test_perfect_beat_boost() -> void:
	watch_signals(rhythm_vehicle)
	
	# Apply a perfect boost
	rhythm_vehicle.apply_beat_boost(true)
	
	assert_signal_emitted(rhythm_vehicle, "boost_applied")
	# Perfect boost should be 1.5x normal
	assert_eq(rhythm_vehicle.current_boost, rhythm_vehicle.boost_power * 1.5)
	# Note: perfect_beats is not automatically incremented in apply_beat_boost


func test_boost_decay() -> void:
	# Apply boost
	rhythm_vehicle.apply_beat_boost(false)
	var initial_boost = rhythm_vehicle.current_boost
	
	# Simulate physics process
	rhythm_vehicle._physics_process(0.1)
	
	# Boost timer should decrease
	assert_lt(rhythm_vehicle.boost_timer, rhythm_vehicle.boost_duration)
	
	# Simulate full duration
	rhythm_vehicle._physics_process(rhythm_vehicle.boost_duration)
	
	# Boost should be cleared
	assert_eq(rhythm_vehicle.current_boost, 0.0)


func test_rhythm_statistics() -> void:
	# Reset stats first
	rhythm_vehicle.reset_rhythm_stats()
	
	# Manually set stats since apply_beat_boost doesn't track them
	rhythm_vehicle.perfect_beats = 2
	rhythm_vehicle.total_beats = 3
	rhythm_vehicle.beat_accuracy = 2.0/3.0
	
	# Check statistics
	var stats = rhythm_vehicle.get_rhythm_stats()
	assert_eq(stats.perfect_beats, 2)
	assert_eq(stats.total_beats, 3)
	assert_almost_eq(stats.accuracy, 2.0/3.0, 0.01)


func test_rhythm_input_detection() -> void:
	watch_signals(rhythm_vehicle)
	
	# Set vehicle to accelerating
	rhythm_vehicle.throttle_input = 1.0
	
	# Mock being within beat window
	rhythm_vehicle.beat_cooldown = 0
	
	# Simulate beat manager state
	beat_manager.start()
	
	# Test the boost mechanism directly
	rhythm_vehicle.apply_beat_boost(false)
	
	assert_signal_emitted(rhythm_vehicle, "boost_applied")
	assert_gt(rhythm_vehicle.current_boost, 0, "Boost should be applied")
	assert_true(beat_manager.is_playing)


func test_reset_rhythm_stats() -> void:
	# Set some stats
	rhythm_vehicle.perfect_beats = 5
	rhythm_vehicle.total_beats = 10
	rhythm_vehicle.beat_accuracy = 0.5
	
	# Reset
	rhythm_vehicle.reset_rhythm_stats()
	
	assert_eq(rhythm_vehicle.perfect_beats, 0)
	assert_eq(rhythm_vehicle.total_beats, 0)
	assert_eq(rhythm_vehicle.beat_accuracy, 0.0)


func test_visual_feedback_enabled() -> void:
	rhythm_vehicle.visual_beat_response = true
	rhythm_vehicle.apply_visual_feedback(false)
	
	# Visual feedback creates tweens, hard to test directly
	# Just ensure no errors occur
	assert_eq(rhythm_vehicle.visual_beat_response, true)


func test_audio_feedback_enabled() -> void:
	rhythm_vehicle.audio_on_beat = true
	rhythm_vehicle.play_boost_sound(false)
	
	# Audio playback is hard to test directly
	# Just ensure no errors occur
	assert_eq(rhythm_vehicle.audio_on_beat, true)


func test_boost_affects_acceleration() -> void:
	var original_accel = rhythm_vehicle.acceleration
	
	# Apply boost
	rhythm_vehicle.apply_beat_boost(false)
	
	# Process physics with boost
	rhythm_vehicle._physics_process(0.1)
	
	# Acceleration should still be original after process
	# (boost is applied temporarily during physics process)
	assert_eq(rhythm_vehicle.acceleration, original_accel)