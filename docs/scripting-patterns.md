# Scripting Patterns

## Script Organization

Structure your scripts consistently:

```gdscript
extends Node2D

# Signals
signal health_changed(new_value)

# Constants and enums
const SPEED = 300.0
enum States { IDLE, WALKING, JUMPING }

# Export variables (inspector-configurable)
@export var max_health: int = 100
@export_range(0, 1.0) var damage_reduction: float = 0.1

# Member variables
var _current_health: int
var _state: States = States.IDLE
var _event_queue: Array[Dictionary] = []  # Type-safe arrays

# Lifecycle methods
func _ready():
    _current_health = max_health
    
func _process(delta):
    _update_animation()
    
func _physics_process(delta):
    _handle_movement(delta)
    
# Public methods
func take_damage(amount):
    _current_health -= amount * (1.0 - damage_reduction)
    health_changed.emit(_current_health)

# Private helper methods (prefix with underscore)
func _handle_movement(delta):
    # Implementation
    
func _update_animation():
    # Implementation
```

## GDScript 2.0 Features

### Static Typing

Use type annotations for better code clarity and error prevention:

```gdscript
# Type-safe arrays
var result: Array[String] = []
var events: Array[Dictionary] = []

# Function return types
func get_all_events() -> Array[String]:
    var result: Array[String] = []
    for key in _events.keys():
        result.append(key)
    return result

# Float operations - use fmod() for modulo
var interval: float = 0.5
if fmod(float(beat_number), interval) != 0.0:
    return
```
Use static typing for better performance and error detection:

```gdscript
var health: int = 100
var direction: Vector2 = Vector2.ZERO
var enemies: Array[Enemy] = []
var damage_values: Array[float] = [10.5, 20.0, 15.5]
```

### Lambda Functions
Use lambda functions for cleaner callbacks:

```gdscript
$Button.pressed.connect(func(): _start_game())
enemies.sort_custom(func(a, b): return a.position.x < b.position.x)

# For more complex lambdas
timer.timeout.connect(func():
    print("Timer expired")
    start_next_level()
)
```

### Custom Properties
Implement getters and setters:

```gdscript
var _health: int = 100

var health:
    get:
        return _health
    set(value):
        _health = clampi(value, 0, max_health)
        health_changed.emit(_health)
        if _health == 0:
            died.emit()
```

### Better Error Handling
Use the new assert with custom messages:

```gdscript
func divide(a: float, b: float) -> float:
    assert(b != 0, "Division by zero attempted")
    return a / b
```

## Code Organization Patterns

### Signal Declaration
Group signals at the top with clear documentation:

```gdscript
# Movement signals
signal moved(new_position: Vector2)
signal stopped

# Combat signals  
signal damaged(amount: float, source: Node)
signal died
signal healed(amount: float)
```

### Export Variables
Organize exports by category:

```gdscript
# Movement configuration
@export_group("Movement")
@export var move_speed: float = 300.0
@export var jump_height: float = 400.0

# Combat configuration
@export_group("Combat")
@export var max_health: int = 100
@export var defense: float = 0.1
```

### Private vs Public Methods
Use clear naming conventions:

```gdscript
# Public API
func start_game():
    _initialize_systems()
    _spawn_player()

# Private implementation
func _initialize_systems():
    # Internal logic
```

## Common Patterns

### State Machine Pattern
```gdscript
enum State { IDLE, RUNNING, JUMPING, FALLING }
var current_state: State = State.IDLE

func _physics_process(delta):
    match current_state:
        State.IDLE:
            _process_idle(delta)
        State.RUNNING:
            _process_running(delta)
        State.JUMPING:
            _process_jumping(delta)
```

### Object Pooling
```gdscript
class_name BulletPool
extends Node

var _pool: Array[Bullet] = []
const POOL_SIZE = 50

func _ready():
    for i in POOL_SIZE:
        var bullet = preload("res://scenes/bullet.tscn").instantiate()
        bullet.set_physics_process(false)
        bullet.visible = false
        add_child(bullet)
        _pool.append(bullet)

func get_bullet() -> Bullet:
    for bullet in _pool:
        if not bullet.visible:
            return bullet
    return null
```

### Singleton Pattern
```gdscript
# Autoloaded script
extends Node

var score: int = 0
var high_score: int = 0

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_high_score()

func add_score(points: int):
    score += points
    if score > high_score:
        high_score = score
        save_high_score()

# Testing utilities
func reset_for_testing():
    score = 0
    # Don't reset high_score as it's persistent data
    # Disable any active timers or processes
    set_process(false)
    set_physics_process(false)
```

## Best Practices

1. **Use Type Hints**: Always specify return types and parameter types
2. **Document Complex Logic**: Add comments for non-obvious code
3. **Avoid Magic Numbers**: Use constants or export variables
4. **Keep Functions Small**: Each function should do one thing well
5. **Use Descriptive Names**: Variable and function names should be self-documenting

## Beat Racer Specific Patterns

### Audio Timing Pattern
```gdscript
var beat_interval: float = 0.5  # seconds
var next_beat_time: float = 0.0

func _process(delta):
    if Time.get_ticks_msec() / 1000.0 >= next_beat_time:
        _on_beat()
        next_beat_time += beat_interval
```

### Performance Monitoring
```gdscript
var frame_time_history: Array[float] = []
const HISTORY_SIZE = 60

func _process(delta):
    frame_time_history.append(delta)
    if frame_time_history.size() > HISTORY_SIZE:
        frame_time_history.pop_front()
    
    var avg_frame_time = frame_time_history.reduce(func(acc, val): return acc + val) / frame_time_history.size()
```