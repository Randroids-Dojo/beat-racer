# test_template.gd
# Template for creating new GUT tests
# Copy this file and rename for your specific test
extends GutTest

# Test dependencies (load in before_all)
var YourClass  # Example: preload("res://scripts/your_class.gd")

# Node tracking for cleanup
var _created_nodes = []

func before_all():
	# Load required scripts/resources
	# YourClass = preload("res://scripts/your_class.gd")
	pass

func before_each():
	# Setup before each test
	pass

func after_each():
	# CRITICAL: Clean up all tracked nodes
	for node in _created_nodes:
		if is_instance_valid(node):
			# Stop audio players
			if node.has_method("stop") and node.has_method("playing"):
				if node.playing:
					node.stop()
			# Remove from scene tree
			if node.is_inside_tree():
				node.get_parent().remove_child(node)
			node.queue_free()
	_created_nodes.clear()
	# Wait for cleanup
	await get_tree().process_frame

func test_example():
	gut.p("Testing example feature")
	
	# Create test nodes
	var node = Node.new()
	_created_nodes.append(node)  # ALWAYS track nodes
	
	# Add to scene tree if needed (for _ready() or child nodes)
	# add_child(node)
	
	# Test assertions
	assert_not_null(node, "Node should be created")
	assert_eq(node.get_class(), "Node", "Should be correct type")

# Audio test example
func test_audio_example():
	gut.p("Testing audio feature")
	
	var player = AudioStreamPlayer.new()
	_created_nodes.append(player)
	add_child(player)
	
	# Configure
	player.bus = "SFX"
	player.volume_db = -6.0
	
	# Assertions
	assert_eq(player.bus, "SFX", "Bus should be set")
	assert_eq(player.volume_db, -6.0, "Volume should be set")

# UI test example
func test_ui_example():
	gut.p("Testing UI control")
	
	var slider = HSlider.new()
	_created_nodes.append(slider)
	
	# Critical configuration
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01  # IMPORTANT for smooth operation
	slider.value = 0.5
	
	# Assertions
	assert_eq(slider.step, 0.01, "Step must be 0.01 for smooth control")
	assert_eq(slider.value, 0.5, "Value should be set")