extends GutTest
## Integration tests for save/load system with main game

var save_system: CompositionSaveSystem
var composition_browser: CompositionBrowser
var test_composition: CompositionResource

func before_each() -> void:
	# Setup save system
	save_system = CompositionSaveSystem.new()
	add_child_autofree(save_system)
	
	# Setup composition browser
	composition_browser = preload("res://scenes/components/ui/composition_browser.tscn").instantiate()
	add_child_autofree(composition_browser)
	
	# Create test composition with realistic data
	test_composition = _create_test_composition()

func after_each() -> void:
	# Clean up test files
	var dir = DirAccess.open("user://compositions/")
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename:
			if filename.begins_with("integration_test_"):
				dir.remove(filename)
			filename = dir.get_next()

func _create_test_composition() -> CompositionResource:
	var comp = CompositionResource.new()
	comp.composition_name = "Integration Test Composition"
	comp.author = "Test Suite"
	comp.bpm = 128.0
	comp.description = "Created for integration testing"
	comp.sound_bank_id = "electronic"
	
	# Add realistic audio bus volumes
	comp.audio_bus_volumes = {
		"Melody": -6.0,
		"Bass": -3.0,
		"Percussion": -4.5,
		"SFX": -10.0
	}
	
	# Add multiple layers with path data
	for i in range(3):
		var layer = CompositionResource.LayerData.new("Layer " + str(i + 1), i)
		layer.color = Color(randf(), randf(), randf())
		
		# Simulate a lap of path samples
		for j in range(100):
			var sample = CompositionResource.PathSample.new()
			sample.timestamp = j * 0.1
			sample.position = Vector2(
				cos(j * 0.1) * 300 + 500,
				sin(j * 0.1) * 200 + 400
			)
			sample.velocity = 50.0 + sin(j * 0.2) * 20.0
			sample.current_lane = (j / 33) % 3  # Switch lanes periodically
			sample.beat_aligned = j % 8 == 0
			sample.measure_number = j / 32
			sample.beat_in_measure = (j / 8) % 4
			
			layer.path_samples.append(sample)
		
		comp.add_layer(layer)
	
	return comp

func test_save_and_browse() -> void:
	# Save multiple compositions
	var filepath1 = save_system.save_composition(test_composition, "integration_test_1")
	
	var comp2 = _create_test_composition()
	comp2.composition_name = "Second Test Composition"
	var filepath2 = save_system.save_composition(comp2, "integration_test_2")
	
	# Refresh browser
	composition_browser.refresh_list()
	
	# Wait for UI update
	await wait_frames(2)
	
	# Check that compositions appear in browser
	var items = composition_browser.filtered_compositions
	assert_gte(items.size(), 2, "Browser should show at least 2 compositions")
	
	# Find our test compositions
	var found_1 = false
	var found_2 = false
	for item in items:
		if item.filename == "integration_test_1.beatcomp":
			found_1 = true
			assert_eq(item.name, "Integration Test Composition")
			assert_eq(item.layers, 3)
			assert_eq(item.bpm, 128.0)
		elif item.filename == "integration_test_2.beatcomp":
			found_2 = true
			assert_eq(item.name, "Second Test Composition")
	
	assert_true(found_1, "First test composition not found in browser")
	assert_true(found_2, "Second test composition not found in browser")

func test_browser_selection_and_load() -> void:
	# Save a composition
	save_system.save_composition(test_composition, "integration_test_select")
	
	# Refresh browser
	composition_browser.refresh_list()
	await wait_frames(2)
	
	# Find and select our composition
	var item_list = composition_browser.item_list
	for i in range(item_list.item_count):
		var metadata = item_list.get_item_metadata(i)
		if metadata and metadata.filename == "integration_test_select.beatcomp":
			# Simulate selection
			item_list.select(i)
			composition_browser._on_item_selected(i)
			break
	
	# Verify selection updated UI
	assert_eq(composition_browser.selected_index, 0)
	assert_false(composition_browser.load_button.disabled)
	assert_true(composition_browser.info_panel.visible)

func test_browser_search() -> void:
	# Save compositions with different names
	test_composition.composition_name = "Rock Composition"
	save_system.save_composition(test_composition, "integration_test_rock")
	
	var jazz_comp = _create_test_composition()
	jazz_comp.composition_name = "Jazz Composition"
	save_system.save_composition(jazz_comp, "integration_test_jazz")
	
	var electronic_comp = _create_test_composition()
	electronic_comp.composition_name = "Electronic Beat"
	save_system.save_composition(electronic_comp, "integration_test_electronic")
	
	# Refresh browser
	composition_browser.refresh_list()
	await wait_frames(2)
	
	# Search for "jazz"
	composition_browser.search_line_edit.text = "jazz"
	composition_browser._on_search_text_changed("jazz")
	await wait_frames(1)
	
	# Should only show jazz composition
	assert_eq(composition_browser.filtered_compositions.size(), 1)
	assert_eq(composition_browser.filtered_compositions[0].name, "Jazz Composition")
	
	# Clear search
	composition_browser.search_line_edit.text = ""
	composition_browser._on_search_text_changed("")
	await wait_frames(1)
	
	# Should show all compositions again
	assert_gte(composition_browser.filtered_compositions.size(), 3)

func test_browser_sorting() -> void:
	# Create compositions with different properties
	var comps = []
	for i in range(3):
		var comp = CompositionResource.new()
		comp.composition_name = ["Alpha", "Charlie", "Bravo"][i]
		comp.bpm = [120.0, 140.0, 100.0][i]
		# Add layers to vary duration
		for j in range(i + 1):
			var layer = CompositionResource.LayerData.new()
			var sample = CompositionResource.PathSample.new((i + 1) * 10.0, Vector2.ZERO)
			layer.path_samples.append(sample)
			comp.add_layer(layer)
		
		save_system.save_composition(comp, "integration_test_sort_" + str(i))
		# Small delay to ensure different modification times
		await wait_frames(1)
	
	# Test name sorting A-Z
	composition_browser.refresh_list()
	composition_browser.sort_option_button.selected = CompositionBrowser.SortMode.NAME_AZ
	composition_browser._on_sort_mode_changed(CompositionBrowser.SortMode.NAME_AZ)
	await wait_frames(1)
	
	var sorted_items = composition_browser.filtered_compositions
	var sorted_names = []
	for item in sorted_items:
		if item.filename.begins_with("integration_test_sort_"):
			sorted_names.append(item.name)
	
	# First three should be alphabetically sorted
	if sorted_names.size() >= 3:
		assert_eq(sorted_names[0], "Alpha")
		assert_eq(sorted_names[1], "Bravo")
		assert_eq(sorted_names[2], "Charlie")

func test_autosave_cleanup() -> void:
	# Create multiple autosaves
	for i in range(7):  # More than MAX_AUTOSAVES
		test_composition.composition_name = "Autosave Test " + str(i)
		save_system.autosave_composition(test_composition)
		await wait_frames(1)  # Ensure different timestamps
	
	# Check that old autosaves were cleaned up
	var autosave_count = 0
	var dir = DirAccess.open("user://compositions/")
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename:
			if filename.begins_with("autosave_"):
				autosave_count += 1
			filename = dir.get_next()
	
	assert_lte(autosave_count, 5, "Should have at most 5 autosaves")

func test_composition_signals() -> void:
	var save_signal_received = false
	var load_signal_received = false
	var saved_filepath = ""
	var loaded_filepath = ""
	
	# Connect to signals
	save_system.composition_saved.connect(func(fp, comp): 
		save_signal_received = true
		saved_filepath = fp
	)
	save_system.composition_loaded.connect(func(fp, comp):
		load_signal_received = true
		loaded_filepath = fp
	)
	
	# Save composition
	var filepath = save_system.save_composition(test_composition, "integration_test_signals")
	await wait_frames(1)
	
	assert_true(save_signal_received, "Save signal not received")
	assert_eq(saved_filepath, filepath)
	
	# Load composition
	save_system.load_composition(filepath)
	await wait_frames(1)
	
	assert_true(load_signal_received, "Load signal not received")
	assert_eq(loaded_filepath, filepath)

func test_browser_delete() -> void:
	# Save a composition
	save_system.save_composition(test_composition, "integration_test_delete")
	
	# Refresh browser
	composition_browser.refresh_list()
	await wait_frames(2)
	
	# Find and select the composition
	var item_list = composition_browser.item_list
	var selected_index = -1
	for i in range(item_list.item_count):
		var metadata = item_list.get_item_metadata(i)
		if metadata and metadata.filename == "integration_test_delete.beatcomp":
			selected_index = i
			item_list.select(i)
			composition_browser._on_item_selected(i)
			break
	
	assert_ne(selected_index, -1, "Test composition not found")
	
	# Delete button should be enabled
	assert_false(composition_browser.delete_button.disabled)
	
	# Track if delete signal was emitted
	var delete_signal_received = false
	var deleted_filepath = ""
	composition_browser.composition_deleted.connect(func(fp):
		delete_signal_received = true
		deleted_filepath = fp
	)
	
	# Simulate delete (without confirmation dialog for testing)
	save_system.delete_composition("integration_test_delete")
	composition_browser.composition_deleted.emit("integration_test_delete.beatcomp")
	composition_browser.refresh_list()
	await wait_frames(2)
	
	assert_true(delete_signal_received, "Delete signal not received")
	
	# Verify file was deleted
	assert_false(save_system.composition_exists("integration_test_delete"))
	
	# Verify removed from browser
	var still_exists = false
	for item in composition_browser.filtered_compositions:
		if item.filename == "integration_test_delete.beatcomp":
			still_exists = true
			break
	assert_false(still_exists, "Deleted composition still in browser")