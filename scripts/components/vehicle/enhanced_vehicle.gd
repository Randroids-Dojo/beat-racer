# Enhanced vehicle with improved feel and physics
extends Vehicle
class_name EnhancedVehicle

@export_group("Enhanced Physics")
@export var acceleration_curve: Curve = null
@export var deceleration_curve: Curve = null
@export var turn_resistance_at_speed: Curve = null
@export var momentum_preservation: float = 0.92
@export var slip_angle_threshold: float = 15.0  # degrees
@export var max_slip_angle: float = 45.0  # degrees

@export_group("Visual Banking")
@export var enable_banking: bool = true
@export var max_bank_angle: float = 10.0  # degrees
@export var bank_speed: float = 5.0
@export var bank_recovery_speed: float = 3.0

@export_group("Screen Effects")
@export var enable_screen_shake: bool = true
@export var acceleration_shake_amount: float = 2.0
@export var collision_shake_amount: float = 5.0
@export var speed_shake_threshold: float = 0.7  # % of max speed

@export_group("Particles")
@export var enable_tire_smoke: bool = true
@export var tire_smoke_threshold: float = 0.3  # slip amount
@export var enable_speed_particles: bool = true
@export var speed_particle_threshold: float = 0.5  # % of max speed

@export_group("State Machine")
@export var idle_to_moving_threshold: float = 10.0
@export var drifting_threshold: float = 0.5  # slip amount

# Internal state
var actual_velocity := Vector2.ZERO
var angular_velocity := 0.0
var wheel_base := 20.0  # Distance between front and rear axles
var current_bank_angle := 0.0
var slip_angle := 0.0
var lateral_velocity := Vector2.ZERO
var is_drifting := false
var acceleration_factor := 0.0
var speed_percentage := 0.0
var previous_velocity := Vector2.ZERO

# State machine
enum VehicleState { IDLE, ACCELERATING, CRUISING, BRAKING, DRIFTING, AIRBORNE }
var current_state: VehicleState = VehicleState.IDLE
var previous_state: VehicleState = VehicleState.IDLE

# Particles
var tire_smoke_particles: Array[CPUParticles2D] = []
var speed_particles: CPUParticles2D = null
var trail_effect: SoundReactiveTrail = null

# Camera reference for screen shake
var camera: Camera2D = null

signal state_changed(old_state: VehicleState, new_state: VehicleState)
signal drift_started()
signal drift_ended()
signal impact_occurred(force: float)


func _ready() -> void:
	super._ready()
	
	# Create default curves if not provided
	if not acceleration_curve:
		acceleration_curve = _create_default_acceleration_curve()
	if not deceleration_curve:
		deceleration_curve = _create_default_deceleration_curve()
	if not turn_resistance_at_speed:
		turn_resistance_at_speed = _create_default_turn_resistance_curve()
	
	# Setup particles
	_setup_particle_effects()
	
	# Find camera
	camera = get_viewport().get_camera_2d()
	
	# Add trail effect if it doesn't exist
	if not has_node("SoundReactiveTrail"):
		trail_effect = SoundReactiveTrail.new()
		trail_effect.name = "SoundReactiveTrail"
		add_child(trail_effect)
	else:
		trail_effect = $SoundReactiveTrail


func _physics_process(delta: float) -> void:
	# Store previous velocity for acceleration calculation
	previous_velocity = velocity
	
	# Process enhanced physics
	process_input()
	apply_enhanced_physics(delta)
	update_vehicle_state()
	apply_visual_effects(delta)
	
	# Move the vehicle
	move_and_slide()
	
	# Handle collisions
	handle_collisions()
	
	emit_status_signals()


func apply_enhanced_physics(delta: float) -> void:
	"""Apply realistic vehicle physics with momentum"""
	speed_percentage = get_speed_percentage()
	
	# Calculate acceleration with curve
	var target_acceleration = 0.0
	if throttle_input > 0:
		acceleration_factor = acceleration_curve.sample(speed_percentage)
		target_acceleration = acceleration * acceleration_factor * throttle_input
	elif throttle_input < 0:
		acceleration_factor = deceleration_curve.sample(speed_percentage)
		target_acceleration = -deceleration * acceleration_factor * abs(throttle_input)
	
	# Apply acceleration
	current_speed += target_acceleration * delta
	
	# Apply friction when not accelerating
	if abs(throttle_input) < 0.1:
		var friction_force = friction * delta
		if abs(current_speed) > friction_force:
			current_speed -= friction_force * sign(current_speed)
		else:
			current_speed = 0.0
	
	# Clamp speed
	current_speed = clamp(current_speed, -max_speed * 0.5, max_speed)
	
	# Calculate steering with speed-based resistance
	if abs(current_speed) > idle_to_moving_threshold:
		var turn_resistance = turn_resistance_at_speed.sample(speed_percentage)
		var effective_turn_speed = turn_speed * (1.0 - turn_resistance * 0.7)
		angular_velocity = steering_input * effective_turn_speed * sign(current_speed)
		
		# Apply steering
		rotation += angular_velocity * delta
	else:
		angular_velocity = 0.0
	
	# Calculate forward and lateral velocities
	var forward_direction = transform.x
	var lateral_direction = transform.y
	
	# Target velocity based on current speed and direction
	var target_velocity = forward_direction * current_speed
	
	# Calculate slip angle (angle between velocity and forward direction)
	if velocity.length() > 10.0:
		var velocity_angle = velocity.angle()
		var forward_angle = forward_direction.angle()
		slip_angle = rad_to_deg(angle_difference(velocity_angle, forward_angle))
		slip_angle = clamp(slip_angle, -max_slip_angle, max_slip_angle)
	else:
		slip_angle = 0.0
	
	# Apply momentum preservation with slip
	var slip_factor = abs(slip_angle) / max_slip_angle
	var effective_drift_factor = lerp(drift_factor, momentum_preservation, slip_factor)
	
	# Blend between current velocity and target velocity
	actual_velocity = actual_velocity.lerp(target_velocity, 1.0 - effective_drift_factor)
	
	# Add lateral slip for drifting feel
	if abs(slip_angle) > slip_angle_threshold:
		is_drifting = true
		var lateral_slip = lateral_direction * slip_angle * 0.5
		actual_velocity += lateral_slip
	else:
		is_drifting = false
	
	# Apply final velocity
	velocity = actual_velocity


func update_vehicle_state() -> void:
	"""Update the vehicle state machine"""
	var new_state = current_state
	
	# Determine new state
	if abs(current_speed) < idle_to_moving_threshold:
		new_state = VehicleState.IDLE
	elif abs(throttle_input) > 0.5 and acceleration_factor > 0.5:
		new_state = VehicleState.ACCELERATING
	elif abs(throttle_input) < 0.1:
		new_state = VehicleState.CRUISING
	elif throttle_input < -0.5:
		new_state = VehicleState.BRAKING
	
	# Override with drifting if applicable
	if is_drifting and abs(current_speed) > idle_to_moving_threshold:
		new_state = VehicleState.DRIFTING
	
	# Handle state transitions
	if new_state != current_state:
		previous_state = current_state
		current_state = new_state
		emit_signal("state_changed", previous_state, current_state)
		
		# Emit specific signals
		if current_state == VehicleState.DRIFTING:
			emit_signal("drift_started")
		elif previous_state == VehicleState.DRIFTING:
			emit_signal("drift_ended")


func apply_visual_effects(delta: float) -> void:
	"""Apply visual enhancements like banking and particle effects"""
	# Vehicle banking on turns
	if enable_banking:
		var target_bank = -steering_input * speed_percentage * max_bank_angle
		if is_drifting:
			target_bank *= 1.5  # Extra banking when drifting
		
		var bank_interpolation = bank_speed if abs(target_bank) > abs(current_bank_angle) else bank_recovery_speed
		current_bank_angle = lerp(current_bank_angle, target_bank, bank_interpolation * delta)
		
		# Apply visual rotation (this is just for show, doesn't affect physics)
		# You might want to apply this to a visual child node instead
		skew = deg_to_rad(current_bank_angle)
	
	# Update particle effects
	update_particle_effects()
	
	# Screen shake
	if enable_screen_shake and camera:
		apply_screen_shake()
	
	# Update trail effect
	if trail_effect:
		trail_effect.set_sound_intensity(speed_percentage)
		if has_node("LaneDetectionComponent"):
			var lane_detection = $LaneDetectionComponent
			trail_effect.set_current_lane(lane_detection.current_lane)


func update_particle_effects() -> void:
	"""Update particle systems based on vehicle state"""
	# Tire smoke
	if enable_tire_smoke:
		for particles in tire_smoke_particles:
			if is_drifting or abs(slip_angle) > slip_angle_threshold * max_slip_angle:
				particles.emitting = true
				particles.amount = int(abs(slip_angle))
			else:
				particles.emitting = false
	
	# Speed particles
	if enable_speed_particles and speed_particles:
		speed_particles.emitting = speed_percentage > speed_particle_threshold
		if speed_particles.emitting:
			speed_particles.amount = int(20 * speed_percentage)


func apply_screen_shake() -> void:
	"""Apply camera shake based on vehicle state"""
	var shake_amount = 0.0
	
	# Acceleration shake
	if current_state == VehicleState.ACCELERATING:
		shake_amount = acceleration_shake_amount * acceleration_factor
	
	# Speed shake at high speeds
	if speed_percentage > speed_shake_threshold:
		shake_amount = max(shake_amount, (speed_percentage - speed_shake_threshold) * 5.0)
	
	# Apply shake to camera
	if shake_amount > 0.0 and camera:
		# Call parent's add_trauma if available
		var parent = camera.get_parent()
		if parent and parent.has_method("add_trauma"):
			parent.add_trauma(shake_amount * 0.1)


func handle_collisions() -> void:
	"""Handle collision effects"""
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var impact_force = collision.get_normal().dot(-velocity.normalized()) * velocity.length()
		
		if impact_force > 100.0:
			emit_signal("impact_occurred", impact_force)
			
			# Screen shake on collision
			if enable_screen_shake and camera:
				var parent = camera.get_parent()
				if parent and parent.has_method("add_trauma"):
					parent.add_trauma(collision_shake_amount * (impact_force / max_speed))
			
			# Reduce speed on impact
			current_speed *= 0.5
			actual_velocity *= 0.5


func _setup_particle_effects() -> void:
	"""Setup particle systems"""
	# Create tire smoke particles (4 wheels)
	var wheel_positions = [
		Vector2(-wheel_base/2, -vehicle_width/2),
		Vector2(-wheel_base/2, vehicle_width/2),
		Vector2(wheel_base/2, -vehicle_width/2),
		Vector2(wheel_base/2, vehicle_width/2)
	]
	
	for pos in wheel_positions:
		var particles = CPUParticles2D.new()
		particles.position = pos
		particles.emitting = false
		particles.amount = 10
		particles.lifetime = 0.5
		particles.speed_scale = 1.5
		particles.texture = preload("res://icon.svg") if FileAccess.file_exists("res://icon.svg") else null
		particles.scale_amount_min = 0.1
		particles.scale_amount_max = 0.3
		particles.color = Color(0.8, 0.8, 0.8, 0.5)
		particles.initial_velocity_min = 50.0
		particles.initial_velocity_max = 100.0
		particles.angular_velocity_min = -180.0
		particles.angular_velocity_max = 180.0
		particles.gravity = Vector2.ZERO
		particles.damping_min = 2.0
		particles.damping_max = 5.0
		add_child(particles)
		tire_smoke_particles.append(particles)
	
	# Create speed particles
	speed_particles = CPUParticles2D.new()
	speed_particles.position = Vector2(-vehicle_length/2, 0)
	speed_particles.emitting = false
	speed_particles.amount = 20
	speed_particles.lifetime = 0.3
	speed_particles.speed_scale = 2.0
	speed_particles.texture = preload("res://icon.svg") if FileAccess.file_exists("res://icon.svg") else null
	speed_particles.scale_amount_min = 0.05
	speed_particles.scale_amount_max = 0.1
	speed_particles.color = Color(0.5, 0.8, 1.0, 0.3)
	speed_particles.initial_velocity_min = 100.0
	speed_particles.initial_velocity_max = 200.0
	speed_particles.direction = Vector2(-1, 0)
	speed_particles.spread = 30.0
	speed_particles.gravity = Vector2.ZERO
	speed_particles.damping_min = 5.0
	speed_particles.damping_max = 10.0
	add_child(speed_particles)


func _create_default_acceleration_curve() -> Curve:
	"""Create default acceleration curve (fast start, tapering off)"""
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.5, 0.7))
	curve.add_point(Vector2(1.0, 0.3))
	return curve


func _create_default_deceleration_curve() -> Curve:
	"""Create default deceleration curve (stronger at high speeds)"""
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.5))
	curve.add_point(Vector2(0.5, 0.8))
	curve.add_point(Vector2(1.0, 1.0))
	return curve


func _create_default_turn_resistance_curve() -> Curve:
	"""Create default turn resistance curve (harder to turn at high speeds)"""
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.5, 0.3))
	curve.add_point(Vector2(1.0, 0.8))
	return curve


func get_state_name() -> String:
	"""Get the current state as a string"""
	match current_state:
		VehicleState.IDLE: return "Idle"
		VehicleState.ACCELERATING: return "Accelerating"
		VehicleState.CRUISING: return "Cruising"
		VehicleState.BRAKING: return "Braking"
		VehicleState.DRIFTING: return "Drifting"
		VehicleState.AIRBORNE: return "Airborne"
		_: return "Unknown"


func get_vehicle_stats() -> Dictionary:
	"""Get current vehicle statistics"""
	return {
		"state": get_state_name(),
		"speed": abs(current_speed),
		"speed_percentage": speed_percentage,
		"slip_angle": slip_angle,
		"is_drifting": is_drifting,
		"bank_angle": current_bank_angle,
		"acceleration_factor": acceleration_factor
	}


func angle_difference(a: float, b: float) -> float:
	"""Calculate the shortest angle difference between two angles"""
	var diff = a - b
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff
