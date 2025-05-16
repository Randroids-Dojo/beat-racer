extends Node

# Test script for Story 002: Vehicle Spawning System

func run_all_tests(main_scene: Node2D):
	print("Running Vehicle Spawning Tests...")
	
	var vehicle_manager = main_scene.get_node("VehicleManager")
	var track = main_scene.get_node("Track")
	
	# Enable debug mode for visual testing
	vehicle_manager.debug_mode = true
	
	# Test 1: Spawn Position Test
	print("\nTest 1: Spawn Position Test")
	vehicle_manager.remove_all_vehicles()
	var vehicle = vehicle_manager.spawn_vehicle(0)  # Spawn sedan
	var expected_pos = track.get_spawn_position()
	print("Expected position: ", expected_pos)
	print("Actual position: ", vehicle.position)
	print("Test 1 Result: ", "PASS" if vehicle.position == expected_pos else "FAIL")
	
	# Test 2: Direction Test
	print("\nTest 2: Direction Test")
	var expected_rot = track.get_spawn_rotation()
	print("Expected rotation: ", expected_rot)
	print("Actual rotation: ", vehicle.rotation)
	print("Test 2 Result: ", "PASS" if abs(vehicle.rotation - expected_rot) < 0.01 else "FAIL")
	
	# Test 3: Lane Position Test
	print("\nTest 3: Lane Position Test")
	print("Vehicle lane position: ", vehicle.lane_position)
	print("Test 3 Result: ", "PASS" if vehicle.lane_position == 1 else "FAIL")
	
	# Test 4: Collision Bounds Test
	print("\nTest 4: Collision Bounds Test")
	var collision_shape = vehicle.get_node("CollisionShape2D")
	var area_collision = vehicle.get_node("Area2D/CollisionShape2D")
	print("CollisionShape exists: ", collision_shape != null)
	print("Area2D CollisionShape exists: ", area_collision != null)
	print("Debug visualization enabled: ", vehicle.show_debug_collision)
	print("Test 4 Result: ", "PASS" if collision_shape != null and area_collision != null else "FAIL")
	
	# Test 5: Multi-Vehicle Test
	print("\nTest 5: Multi-Vehicle Test")
	var vehicle_types = ["Sedan", "Sports Car", "Van", "Motorcycle", "Truck"]
	var all_spawned = true
	
	for i in range(5):
		await main_scene.get_tree().create_timer(0.5).timeout
		vehicle_manager.remove_all_vehicles()
		var test_vehicle = vehicle_manager.spawn_vehicle(i)
		print("Spawned ", vehicle_types[i], ": ", test_vehicle != null)
		if test_vehicle == null:
			all_spawned = false
		else:
			print("  - Color: ", test_vehicle.vehicle_color)
			print("  - Type: ", test_vehicle.vehicle_type)
	
	print("Test 5 Result: ", "PASS" if all_spawned else "FAIL")
	
	print("\n=== All Tests Complete ===")

static func create_test_button(main_scene: Node2D):
	var button = Button.new()
	button.text = "Run Vehicle Spawn Tests"
	button.position = Vector2(10, 10)
	button.size = Vector2(200, 40)
	
	var test_runner = new()
	button.pressed.connect(func(): test_runner.run_all_tests(main_scene))
	
	main_scene.add_child(button)
	return button