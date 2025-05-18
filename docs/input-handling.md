# Input Handling

## Input Architecture

Create a dedicated input handling system for better organization and flexibility.

### Step 1: Define Input Map
Configure actions in Project Settings > Input Map:
- `move_left`
- `move_right`
- `move_up`
- `move_down`
- `jump`
- `attack`
- `pause`

### Step 2: Create Input Handler Singleton

```gdscript
# scripts/autoloads/input_handler.gd
extends Node

signal move_input(direction)
signal jump_pressed
signal attack_pressed
signal attack_released

func _process(_delta):
    var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    move_input.emit(direction)
    
    if Input.is_action_just_pressed("jump"):
        jump_pressed.emit()
    
    if Input.is_action_just_pressed("attack"):
        attack_pressed.emit()
    
    if Input.is_action_just_released("attack"):
        attack_released.emit()
```

## Input Buffering

For responsive controls, implement input buffering:

```gdscript
# Allow jump input to be queued for a short time
const JUMP_BUFFER_TIME: float = 0.15
var jump_buffer_timer: float = 0.0

func _physics_process(delta):
    if jump_buffer_timer > 0:
        jump_buffer_timer -= delta
        if is_on_floor():
            _perform_jump()
            jump_buffer_timer = 0.0
    
    # Rest of movement code...

func _input(event):
    if event.is_action_pressed("jump"):
        if is_on_floor():
            _perform_jump()
        else:
            jump_buffer_timer = JUMP_BUFFER_TIME
```

## Coyote Time

Allow jumps shortly after leaving a platform:

```gdscript
const COYOTE_TIME: float = 0.1
var coyote_timer: float = 0.0
var was_on_floor: bool = false

func _physics_process(delta):
    if is_on_floor():
        coyote_timer = COYOTE_TIME
    else:
        coyote_timer -= delta
    
    # Allow jump if we recently left the ground
    if Input.is_action_just_pressed("jump"):
        if is_on_floor() or coyote_timer > 0:
            velocity.y = -jump_strength
            coyote_timer = 0.0
```

## Input Remapping

Allow players to customize controls:

```gdscript
# Save custom inputs
func save_input_mapping():
    var save_dict = {}
    for action in InputMap.get_actions():
        if action.begins_with("ui_"): # Skip UI actions
            continue
        var events = InputMap.action_get_events(action)
        save_dict[action] = []
        for event in events:
            save_dict[action].append(event.to_dictionary())
    
    var file = FileAccess.open("user://input_mapping.save", FileAccess.WRITE)
    file.store_var(save_dict)
    file.close()

# Load custom inputs
func load_input_mapping():
    if not FileAccess.file_exists("user://input_mapping.save"):
        return
    
    var file = FileAccess.open("user://input_mapping.save", FileAccess.READ)
    var save_dict = file.get_var()
    file.close()
    
    for action in save_dict:
        InputMap.action_erase_events(action)
        for event_dict in save_dict[action]:
            var event = InputEvent.new()
            event.from_dictionary(event_dict)
            InputMap.action_add_event(action, event)
```

## Multi-Input Support

Handle keyboard, gamepad, and touch inputs:

```gdscript
func _input(event):
    # Keyboard/Mouse
    if event is InputEventKey or event is InputEventMouseButton:
        _handle_keyboard_input(event)
    
    # Gamepad
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        _handle_gamepad_input(event)
    
    # Touch
    elif event is InputEventScreenTouch or event is InputEventScreenDrag:
        _handle_touch_input(event)
```

## Beat Racer Specific Input

### Rhythm Input Detection

```gdscript
const BEAT_WINDOW: float = 0.1  # ±100ms tolerance
var next_beat_time: float = 0.0
var beat_interval: float = 0.5

func _input(event):
    if event.is_action_pressed("rhythm_input"):
        var current_time = Time.get_ticks_msec() / 1000.0
        var time_to_beat = abs(current_time - next_beat_time)
        
        if time_to_beat < BEAT_WINDOW:
            _on_perfect_hit()
        elif time_to_beat < BEAT_WINDOW * 2:
            _on_good_hit()
        else:
            _on_miss()
```

### Gesture Recognition

For touch controls:

```gdscript
var touch_start_position: Vector2
var touch_start_time: float

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_start_position = event.position
            touch_start_time = Time.get_ticks_msec() / 1000.0
        else:
            _process_gesture(event.position)

func _process_gesture(end_position: Vector2):
    var swipe_vector = end_position - touch_start_position
    var swipe_time = Time.get_ticks_msec() / 1000.0 - touch_start_time
    
    if swipe_vector.length() < 50:  # Tap
        _on_tap()
    elif swipe_time < 0.5:  # Quick swipe
        if abs(swipe_vector.x) > abs(swipe_vector.y):
            if swipe_vector.x > 0:
                _on_swipe_right()
            else:
                _on_swipe_left()
        else:
            if swipe_vector.y > 0:
                _on_swipe_down()
            else:
                _on_swipe_up()
```

## Best Practices

1. **Separate Input from Logic**: Input handling should only detect inputs, not implement game logic
2. **Use Signals**: Emit signals for inputs so multiple systems can respond
3. **Support Multiple Devices**: Design with keyboard, gamepad, and touch in mind
4. **Provide Visual Feedback**: Show players when their inputs are registered
5. **Allow Customization**: Let players remap controls to their preference
6. **Test Input Latency**: Ensure inputs feel responsive across all devices