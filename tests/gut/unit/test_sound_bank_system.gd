extends GutTest

const SoundBankResource = preload("res://scripts/resources/sound_bank_resource.gd")
const SoundBankManager = preload("res://scripts/components/sound/sound_bank_manager.gd")
const SoundGenerator = preload("res://scripts/components/sound/sound_generator.gd")

var sound_bank_manager: SoundBankManager
var test_bank: SoundBankResource

func before_each():
	sound_bank_manager = SoundBankManager.new()
	add_child_autofree(sound_bank_manager)
	await wait_frames(2) # Allow initialization
	
	# Create test bank
	test_bank = SoundBankResource.new()
	test_bank.bank_name = "Test Bank"
	test_bank.description = "Test bank for unit testing"

func after_each():
	if sound_bank_manager:
		sound_bank_manager.queue_free()
	
	# Clean up test files
	_cleanup_test_files()

func _cleanup_test_files():
	var dir = DirAccess.open("user://sound_banks/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.begins_with("Test") and file_name.ends_with(".tres"):
				dir.remove(file_name)
			file_name = dir.get_next()

class TestSoundBankResource:
	extends GutTest
	
	var bank: SoundBankResource
	
	func before_each():
		bank = SoundBankResource.new()
	
	func test_default_bank_creation():
		var electronic_bank = bank.create_default_bank("Electronic")
		
		assert_not_null(electronic_bank, "Should create electronic bank")
		assert_eq(electronic_bank.bank_name, "Electronic", "Should have correct name")
		assert_gt(electronic_bank.sound_configs.size(), 0, "Should have sound configurations")
		
		# Check for expected generators
		var has_melody = false
		var has_bass = false
		for config in electronic_bank.sound_configs:
			if config["bus_name"] == "Melody":
				has_melody = true
			elif config["bus_name"] == "Bass":
				has_bass = true
		
		assert_true(has_melody, "Should have melody generator")
		assert_true(has_bass, "Should have bass generator")
	
	func test_all_default_banks_exist():
		var default_banks = ["Electronic", "Ambient", "Orchestral", "Blues", "Minimal"]
		
		for bank_name in default_banks:
			var created_bank = bank.create_default_bank(bank_name)
			assert_not_null(created_bank, "Should create %s bank" % bank_name)
			assert_eq(created_bank.bank_name, bank_name, "Should have correct name")
			assert_false(created_bank.description.is_empty(), "Should have description")
	
	func test_invalid_default_bank():
		var invalid_bank = bank.create_default_bank("NonExistent")
		assert_null(invalid_bank, "Should return null for invalid bank name")
	
	func test_generator_config_structure():
		var electronic_bank = bank.create_default_bank("Electronic")
		var config = electronic_bank.sound_configs[0]
		
		# Check required fields
		assert_true("generator_id" in config, "Should have generator_id")
		assert_true("bus_name" in config, "Should have bus_name")
		assert_true("waveform" in config, "Should have waveform")
		assert_true("root_note" in config, "Should have root_note")
		assert_true("scale_type" in config, "Should have scale_type")
		assert_true("octave" in config, "Should have octave")
		assert_true("volume" in config, "Should have volume")
		assert_true("detune" in config, "Should have detune")
		assert_true("enabled" in config, "Should have enabled")
	
	func test_bank_duplication():
		var original = bank.create_default_bank("Electronic")
		var copy = original.duplicate_bank()
		
		assert_not_same(original, copy, "Should be different objects")
		assert_eq(copy.bank_name, "Electronic (Copy)", "Should append (Copy) to name")
		assert_eq(copy.sound_configs.size(), original.sound_configs.size(), "Should have same number of configs")
	
	func test_generator_count():
		var electronic_bank = bank.create_default_bank("Electronic")
		var count = electronic_bank.get_generator_count()
		
		assert_gt(count, 0, "Should have generators")
		assert_eq(count, electronic_bank.sound_configs.size(), "Count should match config array size")
	
	func test_get_summary():
		var electronic_bank = bank.create_default_bank("Electronic")
		var summary = electronic_bank.get_summary()
		
		assert_false(summary.is_empty(), "Summary should not be empty")
		assert_true("Electronic" in summary, "Should contain bank name")
		assert_true("Generators:" in summary, "Should contain generator count")

class TestSoundBankManager:
	extends GutTest
	
	var manager: SoundBankManager
	
	func before_each():
		manager = SoundBankManager.new()
		add_child_autofree(manager)
		await wait_frames(2) # Allow initialization
	
	func test_initialization():
		assert_not_null(manager, "Manager should be created")
		
		var generators = manager.get_generators()
		assert_gt(generators.size(), 0, "Should have generators")
		
		# Check that we have generators for different buses
		var buses = {}
		for gen in generators:
			var bus = gen.get_bus()
			buses[bus] = buses.get(bus, 0) + 1
		
		assert_true("Melody" in buses, "Should have Melody generators")
		assert_true("Bass" in buses, "Should have Bass generators")
	
	func test_default_bank_loading():
		var current_bank = manager.get_current_bank_name()
		assert_false(current_bank.is_empty(), "Should have a current bank")
		
		# Should start with Electronic bank
		assert_eq(current_bank, "Electronic", "Should start with Electronic bank")
	
	func test_available_banks():
		var banks = manager.get_available_banks()
		assert_gt(banks.size(), 0, "Should have available banks")
		
		# Check for default banks
		var has_electronic = false
		var has_ambient = false
		for bank in banks:
			if "Electronic" in bank:
				has_electronic = true
			elif "Ambient" in bank:
				has_ambient = true
		
		assert_true(has_electronic, "Should have Electronic bank")
		assert_true(has_ambient, "Should have Ambient bank")
	
	func test_bank_switching():
		var initial_bank = manager.get_current_bank_name()
		
		# Switch to next bank
		manager.switch_to_next_bank()
		await wait_frames(1)
		
		var new_bank = manager.get_current_bank_name()
		assert_ne(new_bank, initial_bank, "Should switch to different bank")
		
		# Switch back to previous
		manager.switch_to_previous_bank()
		await wait_frames(1)
		
		var final_bank = manager.get_current_bank_name()
		assert_eq(final_bank, initial_bank, "Should return to original bank")
	
	func test_bank_loading():
		var success = manager.load_bank("Ambient")
		await wait_frames(1)
		
		assert_true(success, "Should successfully load Ambient bank")
		assert_eq(manager.get_current_bank_name(), "Ambient", "Should have Ambient as current bank")
	
	func test_invalid_bank_loading():
		var success = manager.load_bank("NonExistentBank")
		assert_false(success, "Should fail to load non-existent bank")
	
	func test_bank_saving():
		# Load a specific bank first
		manager.load_bank("Blues")
		await wait_frames(1)
		
		# Save as new bank
		var success = manager.save_bank("TestBlueCopy")
		assert_true(success, "Should successfully save bank")
		
		# Check it appears in available banks
		var banks = manager.get_available_banks()
		var found = false
		for bank in banks:
			if bank == "TestBlueCopy":
				found = true
				break
		assert_true(found, "Saved bank should appear in available banks")
		
		# Load the saved bank
		var load_success = manager.load_bank("TestBlueCopy")
		assert_true(load_success, "Should be able to load saved bank")
	
	func test_bank_deletion():
		# First save a test bank
		manager.save_bank("TestDeleteMe")
		await wait_frames(1)
		
		# Verify it exists
		var banks_before = manager.get_available_banks()
		var exists_before = false
		for bank in banks_before:
			if bank == "TestDeleteMe":
				exists_before = true
				break
		assert_true(exists_before, "Test bank should exist before deletion")
		
		# Delete it
		var success = manager.delete_bank("TestDeleteMe")
		assert_true(success, "Should successfully delete bank")
		
		# Verify it's gone
		var banks_after = manager.get_available_banks()
		var exists_after = false
		for bank in banks_after:
			if bank == "TestDeleteMe":
				exists_after = true
				break
		assert_false(exists_after, "Test bank should not exist after deletion")
	
	func test_cannot_delete_default_banks():
		var success = manager.delete_bank("⭐ Electronic")
		assert_false(success, "Should not be able to delete default banks")
		
		success = manager.delete_bank("Electronic")
		assert_false(success, "Should not be able to delete default banks")
	
	func test_generator_control():
		var generators = manager.get_generators()
		
		# Start all generators
		manager.set_all_generators_playing(true)
		await wait_frames(1)
		
		var playing_count = 0
		for gen in generators:
			if gen._is_playing:
				playing_count += 1
		
		assert_gt(playing_count, 0, "Some generators should be playing")
		
		# Stop all generators
		manager.set_all_generators_playing(false)
		await wait_frames(1)
		
		playing_count = 0
		for gen in generators:
			if gen._is_playing:
				playing_count += 1
		
		assert_eq(playing_count, 0, "No generators should be playing")
	
	func test_bus_generator_control():
		# Start melody generators only
		manager.set_bus_generators_playing("Melody", true)
		await wait_frames(1)
		
		var melody_generators = manager.get_generator_by_bus("Melody")
		var bass_generators = manager.get_generator_by_bus("Bass")
		
		# Check melody generators are playing
		var melody_playing = 0
		for gen in melody_generators:
			if gen._is_playing:
				melody_playing += 1
		
		# Check bass generators are not playing
		var bass_playing = 0
		for gen in bass_generators:
			if gen._is_playing:
				bass_playing += 1
		
		assert_gt(melody_playing, 0, "Melody generators should be playing")
		assert_eq(bass_playing, 0, "Bass generators should not be playing")
	
	func test_bank_info():
		manager.load_bank("Orchestral")
		await wait_frames(1)
		
		var info = manager.get_bank_info()
		assert_false(info.is_empty(), "Should have bank info")
		assert_eq(info["name"], "Orchestral", "Should have correct name")
		assert_true("description" in info, "Should have description")
		assert_true("generator_count" in info, "Should have generator count")

func test_sound_bank_integration():
	# Test basic functionality
	assert_not_null(sound_bank_manager, "Sound bank manager should exist")
	
	var generators = sound_bank_manager.get_generators()
	assert_gt(generators.size(), 0, "Should have generators")
	
	var current_bank = sound_bank_manager.get_current_bank_name()
	assert_false(current_bank.is_empty(), "Should have current bank")

func test_bank_resource_creation():
	var configs = [
		{
			"generator_id": "test_gen",
			"bus_name": "Melody",
			"waveform": 0,
			"root_note": 0,
			"scale_type": 0,
			"octave": 0,
			"volume": 0.5,
			"detune": 0.0,
			"enabled": true
		}
	]
	
	test_bank.sound_configs = configs
	
	assert_eq(test_bank.get_generator_count(), 1, "Should have one generator")
	
	var config = test_bank.get_generator_config(0)
	assert_eq(config["generator_id"], "test_gen", "Should have correct generator ID")
	assert_eq(config["bus_name"], "Melody", "Should have correct bus")

func test_bank_signals():
	var signal_watcher = watch_signals(sound_bank_manager)
	
	sound_bank_manager.load_bank("Ambient")
	await wait_frames(1)
	
	assert_signal_emitted(sound_bank_manager, "bank_changed", "Should emit bank_changed signal")
	assert_signal_emitted(sound_bank_manager, "bank_loaded", "Should emit bank_loaded signal")