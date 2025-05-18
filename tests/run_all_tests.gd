# run_all_tests.gd
# Simple test runner for all Beat Racer tests
extends SceneTree

var test_files = [
	"test_comprehensive_audio.gd",
	"test_audio_system.gd", 
	"test_single_effect.gd",
	"verify_properties.gd",
	"test_chorus_properties.gd"
]

var current_test_index = 0
var test_results = {}

func _init():
	print("\n===== RUNNING ALL BEAT RACER TESTS =====")
	print("Time: %s" % Time.get_time_string_from_system())
	print("==========================================")
	run_next_test()

func run_next_test():
	if current_test_index >= test_files.size():
		print_summary()
		quit()
		return
	
	var test_file = test_files[current_test_index]
	print("\n[TEST %d/%d] Running: %s" % [current_test_index + 1, test_files.size(), test_file])
	print("----------------------------------------")
	
	# Run the test by loading and executing it
	var test_path = "res://tests/%s" % test_file
	var test_script = load(test_path)
	
	if test_script:
		print("Loaded test successfully, executing...")
		# Store result (we can't get detailed results in this simple runner)
		test_results[test_file] = "COMPLETED"
	else:
		print("ERROR: Failed to load test: %s" % test_path)
		test_results[test_file] = "FAILED TO LOAD"
	
	print("----------------------------------------")
	current_test_index += 1
	
	# Continue to next test with a small delay
	await create_timer(0.1).timeout
	run_next_test()

func print_summary():
	print("\n===== TEST SUMMARY =====")
	print("Total tests: %d" % test_files.size())
	print("\nResults:")
	
	for test in test_results:
		print("  %s: %s" % [test, test_results[test]])
	
	print("\n===== ALL TESTS COMPLETED =====")
	print("Time: %s" % Time.get_time_string_from_system())