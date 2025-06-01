extends GutTest
## Unit tests for the composition save/load system

var save_system: CompositionSaveSystem
var test_composition: CompositionResource
var temp_test_file: String = "user://compositions/test_composition.beatcomp"

func before_each() -> void:
	save_system = CompositionSaveSystem.new()
	add_child_autofree(save_system)
	
	# Create test composition
	test_composition = CompositionResource.new()
	test_composition.composition_name = "Test Composition"
	test_composition.author = "Test Author"
	test_composition.bpm = 120.0
	test_composition.description = "Test description"
	
	# Add a test layer
	var layer = CompositionResource.LayerData.new("Test Layer", 0)
	var sample = CompositionResource.PathSample.new(1.0, Vector2(100, 200))
	sample.velocity = 50.0
	sample.current_lane = 1
	layer.path_samples.append(sample)
	test_composition.add_layer(layer)

func after_each() -> void:
	# Clean up test files
	if FileAccess.file_exists(temp_test_file):
		DirAccess.open("user://").remove(temp_test_file)
	
	# Clean up any other test files
	var dir = DirAccess.open("user://compositions/")
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename:
			if filename.begins_with("test_"):
				dir.remove(filename)
			filename = dir.get_next()

func test_save_directory_creation() -> void:
	# Directory should be created automatically
	assert_true(DirAccess.dir_exists_absolute("user://compositions/"))

func test_save_composition() -> void:
	# Save the composition
	var filepath = save_system.save_composition(test_composition, "test_save")
	
	# Check file was created
	assert_not_null(filepath)
	assert_true(FileAccess.file_exists(filepath))
	assert_string_contains(filepath, "test_save.beatcomp")

func test_load_composition() -> void:
	# Save first
	var filepath = save_system.save_composition(test_composition, "test_load")
	
	# Load the composition
	var loaded_comp = save_system.load_composition(filepath)
	
	# Verify loaded data
	assert_not_null(loaded_comp)
	assert_eq(loaded_comp.composition_name, "Test Composition")
	assert_eq(loaded_comp.author, "Test Author")
	assert_eq(loaded_comp.bpm, 120.0)
	assert_eq(loaded_comp.layers.size(), 1)
	assert_eq(loaded_comp.layers[0].layer_name, "Test Layer")
	assert_eq(loaded_comp.layers[0].path_samples.size(), 1)

func test_composition_exists() -> void:
	# Save a composition
	save_system.save_composition(test_composition, "test_exists")
	
	# Check existence
	assert_true(save_system.composition_exists("test_exists"))
	assert_false(save_system.composition_exists("non_existent"))

func test_delete_composition() -> void:
	# Save a composition
	var filepath = save_system.save_composition(test_composition, "test_delete")
	
	# Delete it
	var success = save_system.delete_composition("test_delete")
	
	assert_true(success)
	assert_false(FileAccess.file_exists(filepath))

func test_list_saved_compositions() -> void:
	# Save multiple compositions
	save_system.save_composition(test_composition, "test_list_1")
	
	var comp2 = test_composition.duplicate()
	comp2.composition_name = "Test 2"
	save_system.save_composition(comp2, "test_list_2")
	
	# List compositions
	var compositions = save_system.list_saved_compositions()
	
	# Should have at least our 2 test compositions
	assert_gte(compositions.size(), 2)
	
	# Check that our compositions are in the list
	var found_1 = false
	var found_2 = false
	for comp in compositions:
		if comp.filename == "test_list_1.beatcomp":
			found_1 = true
		elif comp.filename == "test_list_2.beatcomp":
			found_2 = true
	
	assert_true(found_1, "test_list_1 not found")
	assert_true(found_2, "test_list_2 not found")

func test_autosave() -> void:
	# Create autosave
	var filepath = save_system.autosave_composition(test_composition)
	
	assert_not_null(filepath)
	assert_true(FileAccess.file_exists(filepath))
	assert_string_contains(filepath, "autosave_")

func test_generate_unique_filename() -> void:
	# Save with same name multiple times
	var file1 = save_system.save_composition(test_composition, "test_unique")
	
	var comp2 = test_composition.duplicate()
	var file2 = save_system.save_composition(comp2, "test_unique")
	
	# Should generate different filenames
	assert_ne(file1, file2)
	assert_string_contains(file2, "test_unique_1")

func test_save_error_handling() -> void:
	# Try to save to invalid path
	var invalid_comp = CompositionResource.new()
	invalid_comp.composition_name = "//<>:*?|invalid"
	
	# Should still save with sanitized filename
	var filepath = save_system.save_composition(invalid_comp)
	assert_not_null(filepath)
	assert_false(filepath.contains("<>:*?|"))

func test_load_error_handling() -> void:
	# Try to load non-existent file
	var loaded = save_system.load_composition("non_existent_file.beatcomp")
	assert_null(loaded)

func test_composition_metadata() -> void:
	# Check that dates are set
	assert_false(test_composition.creation_date.is_empty())
	assert_false(test_composition.modification_date.is_empty())
	
	# Save and reload
	var filepath = save_system.save_composition(test_composition, "test_metadata")
	var loaded = save_system.load_composition(filepath)
	
	# Dates should be preserved
	assert_eq(loaded.creation_date, test_composition.creation_date)

func test_layer_operations() -> void:
	# Test adding layers
	var initial_duration = test_composition.duration
	
	var layer2 = CompositionResource.LayerData.new("Layer 2", 1)
	var sample = CompositionResource.PathSample.new(5.0, Vector2(300, 400))
	layer2.path_samples.append(sample)
	test_composition.add_layer(layer2)
	
	assert_eq(test_composition.get_layer_count(), 2)
	assert_gt(test_composition.duration, initial_duration)
	
	# Test removing layers
	test_composition.remove_layer(0)
	assert_eq(test_composition.get_layer_count(), 1)
	
	# Test clearing layers
	test_composition.clear_layers()
	assert_eq(test_composition.get_layer_count(), 0)
	assert_eq(test_composition.duration, 0.0)

func test_formatted_duration() -> void:
	# Clear layers first
	test_composition.clear_layers()
	
	# Add sample at 125 seconds (2:05)
	var layer = CompositionResource.LayerData.new("Test", 0)
	var sample = CompositionResource.PathSample.new(125.0, Vector2.ZERO)
	layer.path_samples.append(sample)
	test_composition.add_layer(layer)
	
	assert_eq(test_composition.get_formatted_duration(), "02:05")

func test_file_size_estimate() -> void:
	var size = test_composition.get_file_size_estimate()
	assert_gt(size, 0)
	
	# Add more samples
	var layer = test_composition.layers[0]
	for i in range(10):
		var sample = CompositionResource.PathSample.new(i, Vector2(i, i))
		layer.path_samples.append(sample)
	
	var new_size = test_composition.get_file_size_estimate()
	assert_gt(new_size, size)