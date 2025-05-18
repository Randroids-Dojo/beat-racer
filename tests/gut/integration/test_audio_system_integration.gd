# test_audio_system_integration.gd
# Integration tests for the complete audio system converted to GUT
extends GutTest

var AudioManager
var audio_manager_instance

func before_all():
	AudioManager = load("res://scripts/autoloads/audio_manager.gd")

func before_each():
	# Create fresh audio manager for each test
	audio_manager_instance = AudioManager.new()
	audio_manager_instance._ready()

func after_each():
	# Clean up
	if audio_manager_instance:
		audio_manager_instance.queue_free()
		audio_manager_instance = null

func test_audio_manager_initialization():
	gut.p("Testing AudioManager initialization")
	
	assert_not_null(audio_manager_instance, "AudioManager should create successfully")
	assert_eq(audio_manager_instance._debug_logging, true, "Debug logging should be enabled")
	
	# Check melody bus gain
	var melody_idx = AudioServer.get_bus_index("Melody")
	assert_gte(melody_idx, 0, "Melody bus should exist")
	
	if melody_idx >= 0:
		var gain = AudioServer.get_bus_volume_db(melody_idx)
		# Gain should be within reasonable range
		assert_between(gain, -80.0, 24.0, "Melody bus gain should be within reasonable range")

func test_bus_creation_and_routing():
	gut.p("Testing audio bus creation and routing")
	
	var expected_buses = ["Master", "Melody", "Bass", "Percussion", "SFX"]
	
	for bus_name in expected_buses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		assert_gte(bus_idx, 0, "%s bus should exist" % bus_name)
		
		if bus_name != "Master" and bus_idx >= 0:
			var send = AudioServer.get_bus_send(bus_idx)
			assert_eq(send, "Master", "%s bus should route to Master" % bus_name)

func test_effect_application():
	gut.p("Testing audio effect application to buses")
	
	# Check melody bus effects
	var melody_idx = AudioServer.get_bus_index("Melody")
	assert_gte(melody_idx, 0, "Melody bus should exist")
	
	if melody_idx >= 0:
		var effect_count = AudioServer.get_bus_effect_count(melody_idx)
		# Melody bus should have 2 effects: Reverb and Delay
		assert_eq(effect_count, 2, "Melody bus should have 2 effects applied")
		
		if effect_count >= 2:
			var effect0 = AudioServer.get_bus_effect(melody_idx, 0)
			var effect1 = AudioServer.get_bus_effect(melody_idx, 1)
			
			assert_true(effect0 is AudioEffectReverb, "First effect should be Reverb")
			assert_true(effect1 is AudioEffectDelay, "Second effect should be Delay")

func test_volume_control():
	gut.p("Testing volume control functionality")
	
	# Test master volume control
	var master_idx = AudioServer.get_bus_index("Master")
	
	# Set volume using linear value
	var linear_value = 0.5
	var db_value = linear_to_db(linear_value)
	AudioServer.set_bus_volume_db(master_idx, db_value)
	
	var actual_db = AudioServer.get_bus_volume_db(master_idx)
	# Allow for small floating point differences
	assert_almost_eq(actual_db, db_value, 0.01, "Volume should be set correctly")

func test_sound_playback_capabilities():
	gut.p("Testing sound playback capabilities")
	
	# Test that we can create audio players
	var test_player = AudioStreamPlayer.new()
	assert_not_null(test_player, "Should be able to create AudioStreamPlayer")
	
	# Test bus assignment
	test_player.bus = "Melody"
	assert_eq(test_player.bus, "Melody", "Should be able to assign bus")
	
	# Create a generator stream for testing
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	test_player.stream = generator
	assert_not_null(test_player.stream, "Should be able to assign stream")
	
	add_child(test_player)
	test_player.play()
	assert_true(test_player.playing, "Player should be playing")
	
	# Clean up
	test_player.stop()
	test_player.queue_free()

func test_multiple_audio_players():
	gut.p("Testing multiple audio player management")
	
	var players = []
	var player_count = 5
	
	# Create multiple players
	for i in range(player_count):
		var player = AudioStreamPlayer.new()
		player.bus = "Test"
		players.append(player)
	
	assert_eq(players.size(), player_count, "Should create all players successfully")
	
	# Clean up
	for player in players:
		player.queue_free()