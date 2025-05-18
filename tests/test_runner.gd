# Test Runner - Execute Multiple Tests
extends Node

var test_files = [
	"test_audio_system.gd",
	"test_chorus_properties.gd",
	"test_single_effect.gd",
	"test_effect_property_verification.gd",
	"test_audio_generation.gd",
	"test_audio_system_integration.gd"
]

func _ready():
	print("\n%s\n RUNNING ALL TESTS\n%s" % ["=".repeat(40), "=".repeat(40)])
	
	var failed_tests = []
	
	for test_file in test_files:
		print("\n[TEST] Running %s" % test_file)
		print("=".repeat(40))
		
		# Run test
		var test_script = load("res://tests/%s" % test_file)
		if test_script:
			var test_instance = test_script.new()
			
			# For SceneTree-based tests, we need to handle differently
			if test_instance is SceneTree:
				print("Running SceneTree test...")
				# SceneTree tests will quit on their own
			else:
				# For Node-based tests
				if test_instance is Node:
					add_child(test_instance)
					await get_tree().create_timer(2.0).timeout # Give test time to complete
					test_instance.queue_free()
			else:
				print("Failed to create test instance")
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
	
	get_tree().quit()
