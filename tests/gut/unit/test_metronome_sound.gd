extends "res://addons/gut/test.gd"

# Test basic metronome functionality in PlaybackSync

var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")

var playback_sync

func before_each():
	# Create playback sync - let it initialize naturally
	playback_sync = PlaybackSyncClass.new()
	add_child(playback_sync)
	
	# Wait for initialization
	await wait_frames(2)

func after_each():
	if playback_sync:
		playback_sync.queue_free()

func test_playback_sync_has_metronome_methods():
	assert_not_null(playback_sync)
	assert_true(playback_sync.has_method("set_metronome_enabled"))
	assert_true(playback_sync.has_method("is_metronome_enabled"))
	assert_true(playback_sync.has_method("set_metronome_volume"))
	assert_true(playback_sync.has_method("get_metronome_volume"))

func test_metronome_enable_disable():
	# Test enabling metronome
	playback_sync.set_metronome_enabled(true)
	assert_true(playback_sync.is_metronome_enabled())
	
	# Test disabling metronome
	playback_sync.set_metronome_enabled(false)
	assert_false(playback_sync.is_metronome_enabled())

func test_metronome_volume_control():
	# Test setting metronome volume in dB
	playback_sync.set_metronome_volume(-6.0)
	assert_almost_eq(playback_sync.get_metronome_volume(), -6.0, 0.01)
	
	playback_sync.set_metronome_volume(0.0)
	assert_almost_eq(playback_sync.get_metronome_volume(), 0.0, 0.01)
	
	playback_sync.set_metronome_volume(-12.0)
	assert_almost_eq(playback_sync.get_metronome_volume(), -12.0, 0.01)

func test_metronome_default_state():
	# Test that metronome starts disabled by default
	assert_false(playback_sync.is_metronome_enabled())
	
	# Test default volume is reasonable
	var default_volume = playback_sync.get_metronome_volume()
	assert_true(default_volume <= 0.0 and default_volume >= -40.0, 
		"Default volume should be reasonable (between -40dB and 0dB)")

func test_metronome_signal_exists():
	# Just verify the signal exists
	assert_true(playback_sync.has_signal("metronome_tick"), 
		"PlaybackSync should have metronome_tick signal")