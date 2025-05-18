# test_template.gd
# Template for creating new GUT tests
# Copy this file and rename for your specific test
extends GutTest

# Test dependencies
var YourClass  # Will be loaded in before_all

# Node tracking for cleanup
var _created_nodes = []

# Called once before all tests in this script
func before_all():
	# Load any required scripts/resources
	# YourClass = load("res://path/to/your/class.gd")
	pass

# Called before each test
func before_each():
	# Setup that needs to happen before each test
	pass

# Called after each test - CRITICAL for cleanup
func after_each():
	# Clean up all tracked nodes
	for node in _created_nodes:
		if is_instance_valid(node):
			# Special handling for audio nodes
			if node.has_method("stop") and node.has_method("playing"):
				if node.playing:
					node.stop()
			# Remove from scene tree if attached
			if node.is_inside_tree():
				node.get_parent().remove_child(node)
			node.queue_free()
	_created_nodes.clear()
	
	# Wait for nodes to be freed
	await get_tree().process_frame

# Called once after all tests complete
func after_all():
	# Any final cleanup
	pass

# Example test structure
func test_example_feature():
	gut.p("Testing example feature")
	
	# Create any nodes needed for testing
	var test_node = Node.new()
	_created_nodes.append(test_node)  # ALWAYS track created nodes
	
	# If node has _ready() or creates children, add to scene tree
	# add_child(test_node)
	
	# Perform test assertions
	assert_not_null(test_node, "Node should be created")
	
	# Add more test logic here
	
	# No manual cleanup needed - after_each() handles it

# Example audio test
func test_audio_feature():
	gut.p("Testing audio feature")
	
	var player = AudioStreamPlayer.new()
	_created_nodes.append(player)
	add_child(player)
	
	# Configure player
	player.bus = "SFX"
	
	# Test logic
	assert_eq(player.bus, "SFX", "Bus should be set correctly")
	
	# Stop if playing (handled by after_each, but good practice)
	if player.playing:
		player.stop()

# Example UI test
func test_ui_control():
	gut.p("Testing UI control")
	
	var slider = HSlider.new()
	_created_nodes.append(slider)
	
	# Configure slider
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01  # Important for smooth operation
	slider.value = 0.5
	
	# Test assertions
	assert_eq(slider.step, 0.01, "Step should be configured for smooth control")
	assert_eq(slider.value, 0.5, "Value should be set correctly")

# Add more test methods as needed...