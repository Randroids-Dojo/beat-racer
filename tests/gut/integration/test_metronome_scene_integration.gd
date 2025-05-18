extends "res://addons/gut/test.gd"

# Test to ensure metronome functionality works in all scenes that need it
# This will catch issues where PlaybackSync is missing from scenes

var test_scenes = [
	"res://scenes/test/simple_sound_playback_test.tscn",
	"res://scenes/test/metronome_test.tscn",
	"res://scenes/test/beat_sync_demo.tscn"
]

func before_each():
	# Get BeatManager singleton
	var beat_manager = get_tree().root.get_node("/root/BeatManager")
	if beat_manager:
		if beat_manager.has_method("reset_for_testing"):
			beat_manager.reset_for_testing()
		else:
			beat_manager.reset()
			beat_manager.bpm = 120

func after_each():
	# Clean up any test scenes
	for child in get_tree().root.get_children():
		if child.name.begins_with("SimpleSoundPlaybackTest") or child.name.begins_with("MetronomeTest") or child.name.begins_with("BeatSyncDemo"):
			child.queue_free()
	
	await get_tree().process_frame

func test_playback_sync_exists_in_test_scenes():
	for scene_path in test_scenes:
		print("Testing scene: %s" % scene_path)
		
		# Skip if scene doesn't exist
		if not FileAccess.file_exists(scene_path):
			print("  Scene not found, skipping")
			continue
			
		# Load the scene
		var scene_resource = load(scene_path)
		assert_not_null(scene_resource, "Failed to load scene: %s" % scene_path)
		
		var scene_instance = scene_resource.instantiate()
		add_child(scene_instance)
		
		# Give scene time to initialize
		await get_tree().create_timer(0.1).timeout
		
		# Check for PlaybackSync
		var found_playback_sync = false
		for node in _get_all_children(scene_instance):
			if node.has_method("set_metronome_enabled") and node.has_method("is_metronome_enabled"):
				found_playback_sync = true
				print("  Found PlaybackSync: %s" % node.get_path())
				break
		
		# Clean up
		scene_instance.queue_free()
		await get_tree().process_frame
		
		assert_true(found_playback_sync, "Scene %s should have PlaybackSync for metronome functionality" % scene_path)

func test_metronome_functionality_in_scenes():
	for scene_path in test_scenes:
		print("Testing metronome in: %s" % scene_path)
		
		if not FileAccess.file_exists(scene_path):
			continue
			
		var scene_resource = load(scene_path)
		var scene_instance = scene_resource.instantiate()
		add_child(scene_instance)
		
		# Give scene time to initialize
		await get_tree().create_timer(0.2).timeout
		
		# Get BeatManager
		var beat_manager = get_tree().root.get_node("/root/BeatManager")
		assert_not_null(beat_manager, "BeatManager should exist")
		
		# Test metronome can be enabled
		beat_manager.enable_metronome()
		await get_tree().create_timer(0.1).timeout
		
		assert_true(beat_manager.is_metronome_enabled(), "Metronome should be enabled in %s" % scene_path)
		
		# Start beat tracking
		beat_manager.start()
		
		# Let it run for a couple beats
		await get_tree().create_timer(1.0).timeout
		
		# Check that beats occurred
		assert_gt(beat_manager.current_beat, 0, "Beats should have occurred in %s" % scene_path)
		
		# Stop and clean up
		beat_manager.stop()
		beat_manager.disable_metronome()
		scene_instance.queue_free()
		
		await get_tree().process_frame

func test_scene_metronome_controls():
	# Test specific UI controls for metronome in scenes that have them
	var scene_path = "res://scenes/test/simple_sound_playback_test.tscn"
	
	if not FileAccess.file_exists(scene_path):
		return
		
	var scene_resource = load(scene_path)
	var scene_instance = scene_resource.instantiate()
	add_child(scene_instance)
	
	await get_tree().create_timer(0.2).timeout
	
	# Look for metronome checkbox
	var metronome_checkbox = _find_node_by_type(scene_instance, "CheckBox")
	assert_not_null(metronome_checkbox, "Should have metronome checkbox")
	
	if metronome_checkbox:
		# Simulate toggling the checkbox
		metronome_checkbox.button_pressed = true
		metronome_checkbox.toggled.emit(true)
		
		await get_tree().create_timer(0.1).timeout
		
		var beat_manager = get_tree().root.get_node("/root/BeatManager")
		assert_true(beat_manager.is_metronome_enabled(), "Metronome should be enabled via checkbox")
		
		# Toggle off
		metronome_checkbox.button_pressed = false
		metronome_checkbox.toggled.emit(false)
		
		await get_tree().create_timer(0.1).timeout
		
		assert_false(beat_manager.is_metronome_enabled(), "Metronome should be disabled via checkbox")
	
	scene_instance.queue_free()
	await get_tree().process_frame

func test_all_metronome_components_present():
	# Test that all necessary components for metronome are present
	var required_components = {
		"BeatManager": "/root/BeatManager",
		"AudioManager": "/root/AudioManager"
	}
	
	for component_name in required_components:
		var path = required_components[component_name]
		var node = get_node_or_null(path)
		assert_not_null(node, "%s should exist at %s" % [component_name, path])
		
		if component_name == "BeatManager":
			assert_true(node.has_method("enable_metronome"), "BeatManager should have enable_metronome method")
			assert_true(node.has_method("disable_metronome"), "BeatManager should have disable_metronome method")
			assert_true(node.has_method("is_metronome_enabled"), "BeatManager should have is_metronome_enabled method")
			assert_true(node.has_method("set_metronome_volume"), "BeatManager should have set_metronome_volume method")

func test_metronome_audio_generation():
	# Test that metronome audio is actually generated
	var MetronomeClass = preload("res://scripts/components/sound/metronome_simple.gd")
	var metronome = MetronomeClass.new()
	add_child(metronome)
	
	await get_tree().process_frame
	
	# Test that tick/tock methods exist
	assert_true(metronome.has_method("play_tick"), "Metronome should have play_tick method")
	assert_true(metronome.has_method("play_tock"), "Metronome should have play_tock method")
	assert_true(metronome.has_method("play_metronome_beat"), "Metronome should have play_metronome_beat method")
	
	# Test that samples are generated
	assert_not_null(metronome._tick_sample, "Tick sample should be generated")
	assert_not_null(metronome._tock_sample, "Tock sample should be generated")
	
	# Test playing without errors
	metronome.play_tick()
	await get_tree().create_timer(0.1).timeout
	
	metronome.play_tock()
	await get_tree().create_timer(0.1).timeout
	
	metronome.play_metronome_beat(true)  # Downbeat
	await get_tree().create_timer(0.1).timeout
	
	metronome.play_metronome_beat(false)  # Regular beat
	await get_tree().create_timer(0.1).timeout
	
	metronome.queue_free()
	await get_tree().process_frame

# Helper functions
func _get_all_children(node: Node) -> Array:
	var children = []
	children.append(node)
	for child in node.get_children():
		children.append_array(_get_all_children(child))
	return children

func _find_node_by_type(root: Node, type_name: String) -> Node:
	for node in _get_all_children(root):
		if node.get_class() == type_name:
			return node
	return null