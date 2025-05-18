#!/usr/bin/env godot --script
# convert_to_gut.gd - Helper to convert legacy tests to GUT format

extends SceneTree

var file_path: String = ""
var dry_run: bool = false

func _init():
	var args = OS.get_cmdline_args()
	
	# Parse arguments
	for i in range(args.size()):
		if args[i] == "--file" and i + 1 < args.size():
			file_path = args[i + 1]
		elif args[i] == "--dry-run":
			dry_run = true
		elif args[i] == "--help":
			print_help()
			quit()
	
	if file_path == "":
		print("Error: No file specified")
		print_help()
		quit()
		return
	
	convert_file(file_path)
	quit()

func print_help():
	print("Convert legacy tests to GUT format")
	print("Usage: godot --headless --script convert_to_gut.gd -- --file <path>")
	print("Options:")
	print("  --file <path>  Path to test file to convert")
	print("  --dry-run      Show changes without writing")
	print("  --help         Show this help")

func convert_file(path: String):
	if not FileAccess.file_exists(path):
		print("Error: File not found: " + path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	print("Converting: " + path)
	
	# Apply conversions
	var converted = content
	
	# 1. Change base class
	converted = converted.replace("extends SceneTree", "extends GutTest")
	
	# 2. Convert _init to before_all
	converted = converted.replace("func _init():", "func before_all():")
	
	# 3. Add test_ prefix to test functions
	var test_functions = [
		"test_audio_effect_properties",
		"test_audio_bus_setup", 
		"test_volume_controls",
		"test_effect_verification",
		"test_ui_configuration",
		"test_reverb_properties",
		"test_delay_properties",
		"test_chorus_properties",
		"test_compressor_properties",
		"test_eq_properties",
		"test_distortion_properties",
		"test_audio_manager_initialization",
		"test_bus_creation_and_routing",
		"test_effect_application",
		"test_volume_control",
		"test_sound_playback"
	]
	
	for func_name in test_functions:
		# Only add prefix if not already present
		if converted.find("func " + func_name) != -1:
			if converted.find("func test_" + func_name) == -1:
				converted = converted.replace("func " + func_name, "func test_" + func_name)
	
	# 4. Convert print statements to gut.p()
	converted = converted.replace('print("', 'gut.p("')
	
	# 5. Convert assertions
	converted = convert_assertions(converted)
	
	# 6. Remove manual result tracking
	converted = remove_result_tracking(converted)
	
	# 7. Add describe() calls where appropriate
	converted = add_describe_calls(converted)
	
	# 8. Remove quit() calls
	converted = converted.replace("quit()", "# quit() removed for GUT")
	
	# Show or save results
	if dry_run:
		print("\n--- Converted content ---")
		print(converted)
		print("--- End converted content ---")
	else:
		var output_path = path.replace(".gd", "_gut.gd")
		var output_file = FileAccess.open(output_path, FileAccess.WRITE)
		output_file.store_string(converted)
		output_file.close()
		print("Saved to: " + output_path)

func convert_assertions(content: String) -> String:
	var result = content
	
	# Convert simple equality checks
	result = result.replace('if value == expected:', 'assert_eq(value, expected)')
	result = result.replace('if value != expected:', 'assert_ne(value, expected)')
	
	# Convert null checks
	result = result.replace('if value == null:', 'assert_null(value)')
	result = result.replace('if value != null:', 'assert_not_null(value)')
	
	# Convert boolean checks
	result = result.replace('if condition:', 'assert_true(condition)')
	result = result.replace('if not condition:', 'assert_false(condition)')
	
	# Convert property existence checks
	var prop_check_pattern = 'if .* in props:'
	# This is simplified - in reality we'd need regex
	result = result.replace('" in props:', '", props, "Should have property")')
	result = result.replace('if "', 'assert_has("')
	
	return result

func remove_result_tracking(content: String) -> String:
	var result = content
	
	# Remove test result dictionary operations
	var patterns_to_remove = [
		'test_results[test_name] = {"passed": 0, "failed": 0, "details": []}',
		'test_results[test_name]["passed"] += 1',
		'test_results[test_name]["failed"] += 1',
		'test_results[test_name]["details"].append('
	]
	
	for pattern in patterns_to_remove:
		result = result.replace(pattern, "# " + pattern + " # Removed for GUT")
	
	return result

func add_describe_calls(content: String) -> String:
	var result = content
	
	# Add describe() at the start of test functions
	var lines = result.split("\n")
	var new_lines = []
	
	for i in range(lines.size()):
		var line = lines[i]
		new_lines.append(line)
		
		# If this is a test function declaration
		if line.strip_edges().begins_with("func test_") and line.ends_with("):"):
			# Extract function name
			var func_name = line.strip_edges().replace("func ", "").replace("():", "")
			var description = func_name.replace("test_", "").replace("_", " ").capitalize()
			new_lines.append('\tdescribe("' + description + '")')
	
	return "\n".join(new_lines)