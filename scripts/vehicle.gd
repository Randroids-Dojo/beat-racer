extends CharacterBody2D

enum VehicleType { SEDAN, SPORTS_CAR, VAN, MOTORCYCLE, TRUCK }

@export var vehicle_type: VehicleType = VehicleType.SEDAN
@export var vehicle_color: Color = Color.BLUE
@export var show_debug_collision: bool = false

var lane_position: int = 1  # 0=left, 1=center, 2=right
var current_speed: float = 0.0
var idle_animation_time: float = 0.0
var idle_animation_speed: float = 2.0
var idle_animation_amplitude: float = 3.0

signal spawned

func _ready() -> void:
	setup_vehicle_appearance()
	if show_debug_collision:
		modulate_collision_shape(Color(1, 0, 0, 0.5))

func _process(delta: float) -> void:
	# Idle animation - subtle floating/hovering
	idle_animation_time += delta * idle_animation_speed
	var offset_y = sin(idle_animation_time) * idle_animation_amplitude
	if $Sprite2D:
		$Sprite2D.position.y = offset_y

func setup_vehicle_appearance() -> void:
	match vehicle_type:
		VehicleType.SEDAN:
			vehicle_color = Color("#7A4EBC")  # Blue with purple accents
		VehicleType.SPORTS_CAR:
			vehicle_color = Color("#E94560")  # Red
		VehicleType.VAN:
			vehicle_color = Color("#FFD460")  # Orange/yellow
		VehicleType.MOTORCYCLE:
			vehicle_color = Color("#7A4EBC")  # Purple
		VehicleType.TRUCK:
			vehicle_color = Color("#44C767")  # Green
	
	# Apply color to sprite (will be visible when we add actual sprites)
	if $Sprite2D:
		$Sprite2D.modulate = vehicle_color
	
	# Set particle color for spawn effect
	if $CPUParticles2D:
		$CPUParticles2D.color = vehicle_color

func spawn_at_position(spawn_position: Vector2, spawn_rotation: float) -> void:
	position = spawn_position
	rotation = spawn_rotation
	lane_position = 1  # Default to center lane
	
	# Play spawn effect
	if $CPUParticles2D:
		$CPUParticles2D.restart()
		$CPUParticles2D.emitting = true
	
	spawned.emit()

func modulate_collision_shape(color: Color) -> void:
	if $CollisionShape2D:
		$CollisionShape2D.modulate = color
	if $Area2D/CollisionShape2D:
		$Area2D/CollisionShape2D.modulate = color

func get_lane_offset() -> float:
	match lane_position:
		0: return -50.0  # Left lane
		1: return 0.0    # Center lane
		2: return 50.0   # Right lane
		_: return 0.0