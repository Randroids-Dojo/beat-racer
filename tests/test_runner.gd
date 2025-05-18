# test_runner.gd
# Main test runner for Beat Racer test suite
extends Node

var test_files: Array[String] = []
var failed_tests: Array[String] = []

func _ready():
	print("Starting Beat Racer Test Suite...")
	
	# Discover test files
	_discover_tests("res://tests")
	
	# Run tests
	for test_file in test_files:
		print("\n%s" % "-".repeat(40))
		print("Running: %s" % test_file)
		print("%s" % "-".repeat(40))
		
		# Handle special test file cases
		if test_file == "test_runner.gd":
			continue
			
		# Run test
		var test_script = load("res://tests/%s" % test_file)
		if test_script:
			var test_instance = test_script.new()
			
			# For SceneTree-based tests, we need to handle differently
			if test_instance is SceneTree:
				print("Running SceneTree test...")
				# SceneTree tests will quit on their own
			elif test_instance is Node:
				# For Node-based tests
				add_child(test_instance)
				await get_tree().create_timer(2.0).timeout # Give test time to complete
				test_instance.queue_free()
			else:
				print("Failed to create test instance - unknown type")
				failed_tests.append(test_file)
		else:
			print("Failed to load test: %s" % test_file)
			failed_tests.append(test_file)
	
	print("\n%s\n TEST SUMMARY\n%s" % ["=".repeat(40), "=".repeat(40)])
	print("Total tests: %d" % test_files.size())
	print("Failed tests: %d" % failed_tests.size())
	
	if failed_tests.size() > 0:
		print("\nFailed tests:")
		for test in failed_tests:
			print("  - %s" % test)
		get_tree().quit(1)
	else:
		print("\nAll tests passed!")
		get_tree().quit(0)

func _discover_tests(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var full_path = path + "/" + file_name
			
			if dir.current_is_dir() and file_name != ".":
				_discover_tests(full_path)
			elif file_name.ends_with("test.gd") or file_name.begins_with("test_"):
				test_files.append(full_path.replace("res://tests/", ""))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()