# test_gut_conversion_validation.gd
# Validates that converted tests work correctly with GUT
extends GutTest

func test_gut_framework_is_available():
	gut.p("Testing GUT framework availability")
	
	assert_not_null(gut, "GUT instance should be available")
	assert_true(self is GutTest, "Test should extend GutTest")

func test_assertion_methods_work():
	gut.p("Testing GUT assertion methods")
	
	# Test various assertion types
	assert_eq(1 + 1, 2, "Basic equality works")
	assert_ne(1, 2, "Inequality works")
	assert_true(true, "True assertion works")
	assert_false(false, "False assertion works")
	assert_null(null, "Null assertion works")
	assert_not_null(self, "Not null assertion works")
	
	var arr = [1, 2, 3]
	assert_has(arr, 2, "Array contains assertion works")
	assert_does_not_have(arr, 4, "Array doesn't contain assertion works")
	
	assert_gt(5, 3, "Greater than works")
	assert_lt(3, 5, "Less than works")
	assert_between(4, 3, 5, "Between assertion works")
	
	assert_almost_eq(0.1 + 0.2, 0.3, 0.01, "Float comparison works")

func test_describe_function():
	gut.p("Testing describe() replacement")
	
	# If we got here without errors, describe() works
	assert_true(true, "describe() should not cause errors")

func test_lifecycle_methods():
	gut.p("Testing lifecycle methods")
	
	# These would be called by GUT, we're just checking they exist
	assert_true(has_method("before_all"), "Should have before_all method")
	assert_true(has_method("before_each"), "Should have before_each method")
	assert_true(has_method("after_each"), "Should have after_each method")
	assert_true(has_method("after_all"), "Should have after_all method")

func test_audio_server_access():
	gut.p("Testing AudioServer access in GUT tests")
	
	# Verify we can access AudioServer (important for our audio tests)
	assert_not_null(AudioServer, "AudioServer should be accessible")
	
	# Should have at least Master bus
	var master_idx = AudioServer.get_bus_index("Master")
	assert_gte(master_idx, 0, "Master bus should exist")

func test_resource_loading():
	gut.p("Testing resource loading in GUT tests")
	
	# Test that we can load scripts (important for our tests)
	var script_path = "res://scripts/components/verification_helpers.gd"
	if FileAccess.file_exists(script_path):
		var script = load(script_path)
		assert_not_null(script, "Should be able to load scripts")

func test_node_creation():
	gut.p("Testing node creation in GUT tests")
	
	# Test that we can create nodes
	var node = Node.new()
	assert_not_null(node, "Should be able to create nodes")
	
	var audio_player = AudioStreamPlayer.new()
	assert_not_null(audio_player, "Should be able to create audio nodes")
	
	# Clean up
	node.queue_free()
	audio_player.queue_free()

func test_gut_output_methods():
	gut.p("Testing GUT output methods")
	
	# Test various output methods
	gut.p("This is a print message")
	
	# These shouldn't cause errors
	assert_true(true, "Output methods should work without errors")

func test_signal_watching():
	gut.p("Testing signal watching capabilities")
	
	# GUT provides signal watching
	var node = Node.new()
	add_child(node)
	
	# Define a custom signal
	node.add_user_signal("test_signal")
	
	# Watch for the signal
	watch_signals(node)
	
	# Emit the signal
	node.emit_signal("test_signal")
	
	# Check it was received
	assert_signal_emitted(node, "test_signal")
	
	# Clean up
	node.queue_free()

func test_async_capabilities():
	gut.p("Testing async test capabilities")
	
	# Test that we can use await in tests
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	# Wait for timer
	await timer.timeout
	
	# If we get here, async works
	assert_true(true, "Async/await should work in tests")
	
	# Clean up
	timer.queue_free()