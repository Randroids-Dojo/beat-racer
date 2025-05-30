# Unit tests for enhanced vehicle physics
extends GutTest

var vehicle = null


func before_each():
	var EnhancedVehicle = preload("res://scripts/components/vehicle/enhanced_vehicle.gd")
	vehicle = EnhancedVehicle.new()
	vehicle.name = "TestEnhancedVehicle"
	add_child(vehicle)
	await wait_frames(1)


func after_each():
	if vehicle:
		vehicle.queue_free()
		vehicle = null


func test_enhanced_vehicle_initialization():
	assert_not_null(vehicle, "Vehicle should be created")
	assert_eq(vehicle.current_state, vehicle.VehicleState.IDLE, "Should start in IDLE state")
	assert_eq(vehicle.current_speed, 0.0, "Should start with zero speed")
	assert_eq(vehicle.slip_angle, 0.0, "Should start with zero slip angle")
	assert_eq(vehicle.is_drifting, false, "Should not be drifting initially")
	assert_eq(vehicle.current_bank_angle, 0.0, "Should have zero bank angle")


func test_acceleration_curve():
	# Test default acceleration curve
	var curve = vehicle.acceleration_curve
	assert_not_null(curve, "Should have acceleration curve")
	
	# Test curve values
	assert_almost_eq(curve.sample(0.0), 1.0, 0.1, "Should have high acceleration at low speed")
	assert_lt(curve.sample(1.0), curve.sample(0.0), "Acceleration should decrease with speed")


func test_deceleration_curve():
	# Test default deceleration curve
	var curve = vehicle.deceleration_curve
	assert_not_null(curve, "Should have deceleration curve")
	
	# Test curve values
	assert_lt(curve.sample(0.0), curve.sample(1.0), "Deceleration should increase with speed")


func test_turn_resistance_curve():
	# Test default turn resistance curve
	var curve = vehicle.turn_resistance_at_speed
	assert_not_null(curve, "Should have turn resistance curve")
	
	# Test curve values
	assert_almost_eq(curve.sample(0.0), 0.0, 0.1, "Should have low resistance at low speed")
	assert_gt(curve.sample(1.0), curve.sample(0.0), "Turn resistance should increase with speed")


func test_state_transitions():
	# Test IDLE to ACCELERATING
	vehicle.throttle_input = 1.0
	vehicle.current_speed = 20.0
	vehicle.acceleration_factor = 0.8
	vehicle.update_vehicle_state()
	assert_eq(vehicle.current_state, vehicle.VehicleState.ACCELERATING)
	
	# Test ACCELERATING to CRUISING
	vehicle.throttle_input = 0.0
	vehicle.update_vehicle_state()
	assert_eq(vehicle.current_state, vehicle.VehicleState.CRUISING)
	
	# Test CRUISING to BRAKING
	vehicle.throttle_input = -0.6
	vehicle.update_vehicle_state()
	assert_eq(vehicle.current_state, vehicle.VehicleState.BRAKING)
	
	# Test transition to IDLE
	vehicle.current_speed = 5.0  # Below idle threshold
	vehicle.update_vehicle_state()
	assert_eq(vehicle.current_state, vehicle.VehicleState.IDLE)


func test_drift_detection():
	# Setup drifting conditions
	vehicle.current_speed = 400.0
	vehicle.slip_angle = 20.0  # Above threshold
	vehicle.is_drifting = true
	vehicle.update_vehicle_state()
	
	assert_eq(vehicle.current_state, vehicle.VehicleState.DRIFTING)


func test_banking_calculation():
	vehicle.enable_banking = true
	vehicle.max_bank_angle = 10.0
	vehicle.steering_input = 1.0
	vehicle.current_speed = vehicle.max_speed  # Full speed
	
	# Simulate physics frame
	vehicle.apply_visual_effects(0.1)
	
	# Bank angle should be approaching max
	assert_gt(abs(vehicle.current_bank_angle), 0.0, "Should have non-zero bank angle")


func test_particle_system_creation():
	# Check tire smoke particles
	assert_eq(vehicle.tire_smoke_particles.size(), 4, "Should have 4 tire smoke emitters")
	
	for particles in vehicle.tire_smoke_particles:
		assert_not_null(particles, "Tire smoke particle should exist")
		assert_false(particles.emitting, "Should not emit initially")
	
	# Check speed particles
	assert_not_null(vehicle.speed_particles, "Speed particles should exist")
	assert_false(vehicle.speed_particles.emitting, "Should not emit initially")


func test_trail_effect_integration():
	assert_not_null(vehicle.trail_effect, "Should have trail effect")
	assert_eq(vehicle.trail_effect.name, "SoundReactiveTrail")


func test_momentum_physics():
	# Set initial velocity
	vehicle.actual_velocity = Vector2(100, 0)
	vehicle.velocity = vehicle.actual_velocity
	vehicle.current_speed = 100.0
	vehicle.momentum_preservation = 0.9
	
	# Change direction slightly
	vehicle.rotation = deg_to_rad(10)
	
	# Apply physics
	vehicle.apply_enhanced_physics(0.1)
	
	# Velocity should blend with momentum
	var angle_diff = vehicle.velocity.angle_to(Vector2(100, 0))
	assert_lt(abs(angle_diff), deg_to_rad(10), "Should preserve some momentum")


func test_slip_angle_calculation():
	# Setup movement at an angle
	vehicle.velocity = Vector2(100, 50)
	vehicle.rotation = 0  # Facing right
	vehicle.current_speed = vehicle.velocity.length()
	
	vehicle.apply_enhanced_physics(0.1)
	
	assert_gt(abs(vehicle.slip_angle), 0.0, "Should have non-zero slip angle")
	assert_lte(abs(vehicle.slip_angle), vehicle.max_slip_angle, "Slip angle should be clamped")


func test_collision_handling():
	# Simulate collision signal
	var watch = watch_signals(vehicle)
	vehicle.handle_collisions()  # No collision
	assert_signal_not_emitted(vehicle, "impact_occurred")
	
	# Would need to mock collision in actual physics engine
	# This is more of an integration test


func test_vehicle_stats():
	# Setup some state
	vehicle.current_state = vehicle.VehicleState.ACCELERATING
	vehicle.current_speed = 300.0
	vehicle.slip_angle = 25.0
	vehicle.is_drifting = true
	vehicle.current_bank_angle = 5.0
	vehicle.acceleration_factor = 0.7
	
	var stats = vehicle.get_vehicle_stats()
	
	assert_eq(stats.state, "Accelerating")
	assert_eq(stats.speed, 300.0)
	assert_gt(stats.speed_percentage, 0.0)
	assert_eq(stats.slip_angle, 25.0)
	assert_eq(stats.is_drifting, true)
	assert_eq(stats.bank_angle, 5.0)
	assert_eq(stats.acceleration_factor, 0.7)


func test_state_change_signals():
	var watch = watch_signals(vehicle)
	
	# Trigger state change
	vehicle.current_state = vehicle.VehicleState.IDLE
	vehicle.throttle_input = 1.0
	vehicle.current_speed = 20.0
	vehicle.acceleration_factor = 0.8
	vehicle.update_vehicle_state()
	
	assert_signal_emitted_with_parameters(
		vehicle, 
		"state_changed", 
		[vehicle.VehicleState.IDLE, vehicle.VehicleState.ACCELERATING]
	)


func test_drift_signals():
	var watch = watch_signals(vehicle)
	
	# Start drift
	vehicle.current_speed = 400.0
	vehicle.slip_angle = 20.0
	vehicle.is_drifting = true
	vehicle.current_state = vehicle.VehicleState.CRUISING
	vehicle.update_vehicle_state()
	
	assert_signal_emitted(vehicle, "drift_started")
	
	# End drift
	vehicle.is_drifting = false
	vehicle.slip_angle = 5.0
	vehicle.update_vehicle_state()
	
	assert_signal_emitted(vehicle, "drift_ended")


func test_angle_difference_helper():
	# Test angle wrapping
	assert_almost_eq(vehicle.angle_difference(0, PI), -PI, 0.01)
	assert_almost_eq(vehicle.angle_difference(PI, 0), PI, 0.01)
	assert_almost_eq(vehicle.angle_difference(3 * PI, PI), 0, 0.01)
	assert_almost_eq(vehicle.angle_difference(-PI/2, PI/2), -PI, 0.01)