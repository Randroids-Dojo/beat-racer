# State Management

## State Machine Pattern

Implement a flexible state machine system:

### Base State Class

```gdscript
# scripts/components/state.gd
class_name State
extends Node

signal transitioned(new_state_name)

# Virtual methods to override
func enter() -> void:
    pass
    
func exit() -> void:
    pass
    
func update(delta: float) -> void:
    pass
    
func physics_update(delta: float) -> void:
    pass
    
func handle_input(event: InputEvent) -> void:
    pass
```

### State Machine Implementation

```gdscript
# scripts/components/state_machine.gd
class_name StateMachine
extends Node

@export var initial_state: NodePath

var _states: Dictionary = {}
var current_state: State

func _ready() -> void:
    # Wait for owner to be ready
    await owner.ready
    
    # Register states
    for child in get_children():
        if child is State:
            _states[child.name] = child
            child.transitioned.connect(_on_state_transition)
    
    # Set initial state
    if initial_state:
        current_state = get_node(initial_state)
        current_state.enter()

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)
        
func _input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func _on_state_transition(new_state_name: String) -> void:
    if not _states.has(new_state_name):
        push_error("State does not exist: " + new_state_name)
        return
        
    if current_state:
        current_state.exit()
        
    current_state = _states[new_state_name]
    current_state.enter()
```

## Example Player States

### Idle State

```gdscript
# states/player_idle_state.gd
extends State

func enter() -> void:
    owner.animation_player.play("idle")
    owner.velocity = Vector2.ZERO
    
func physics_update(delta: float) -> void:
    # Apply gravity
    owner.velocity.y += owner.gravity * delta
    
    # Check for movement input
    if Input.get_vector("left", "right", "up", "down").length() > 0:
        transitioned.emit("Run")
    
    # Check for jump input
    if Input.is_action_just_pressed("jump") and owner.is_on_floor():
        transitioned.emit("Jump")
    
    owner.move_and_slide()
```

### Run State

```gdscript
# states/player_run_state.gd
extends State

func enter() -> void:
    owner.animation_player.play("run")

func physics_update(delta: float) -> void:
    var direction = Input.get_vector("left", "right", "up", "down")
    
    if direction.length() == 0:
        transitioned.emit("Idle")
        return
    
    # Apply movement
    owner.velocity.x = direction.x * owner.move_speed
    owner.velocity.y += owner.gravity * delta
    
    # Check for jump
    if Input.is_action_just_pressed("jump") and owner.is_on_floor():
        transitioned.emit("Jump")
    
    owner.move_and_slide()
```

### Jump State

```gdscript
# states/player_jump_state.gd
extends State

func enter() -> void:
    owner.animation_player.play("jump")
    owner.velocity.y = -owner.jump_strength

func physics_update(delta: float) -> void:
    # Apply gravity
    owner.velocity.y += owner.gravity * delta
    
    # Horizontal movement
    var direction = Input.get_axis("left", "right")
    owner.velocity.x = direction * owner.move_speed
    
    # Check if landed
    if owner.is_on_floor():
        if Input.get_vector("left", "right", "up", "down").length() > 0:
            transitioned.emit("Run")
        else:
            transitioned.emit("Idle")
    
    owner.move_and_slide()
```

## Beat Racer State Examples

### Game State Manager

```gdscript
# scripts/autoloads/game_state_manager.gd
extends Node

enum GameState {
    MENU,
    PLAYING,
    PAUSED,
    GAME_OVER
}

var current_state: GameState = GameState.MENU
var previous_state: GameState

signal state_changed(new_state: GameState, old_state: GameState)

func change_state(new_state: GameState) -> void:
    if new_state == current_state:
        return
        
    previous_state = current_state
    current_state = new_state
    state_changed.emit(current_state, previous_state)
    
    match current_state:
        GameState.MENU:
            _enter_menu_state()
        GameState.PLAYING:
            _enter_playing_state()
        GameState.PAUSED:
            _enter_paused_state()
        GameState.GAME_OVER:
            _enter_game_over_state()

func _enter_menu_state():
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    MusicManager.play_menu_music()

func _enter_playing_state():
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
    MusicManager.play_game_music()

func _enter_paused_state():
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _enter_game_over_state():
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    MusicManager.play_game_over_music()
```

### Vehicle States

```gdscript
# Vehicle state machine setup
extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine

enum VehicleState {
    NORMAL,
    BOOSTING,
    AIRBORNE,
    CRASHED
}

func _ready():
    # State machine will handle all state logic
    pass
```

## Advanced State Patterns

### Hierarchical State Machine

```gdscript
# Base state with sub-states
class_name HierarchicalState
extends State

var _substates: Dictionary = {}
var current_substate: State

func _ready():
    for child in get_children():
        if child is State:
            _substates[child.name] = child
            child.transitioned.connect(_on_substate_transition)

func enter():
    if current_substate:
        current_substate.enter()

func exit():
    if current_substate:
        current_substate.exit()

func update(delta):
    if current_substate:
        current_substate.update(delta)

func _on_substate_transition(new_state_name: String):
    # Handle substate transitions
    if _substates.has(new_state_name):
        if current_substate:
            current_substate.exit()
        current_substate = _substates[new_state_name]
        current_substate.enter()
    else:
        # Transition to external state
        transitioned.emit(new_state_name)
```

### State History

```gdscript
# State machine with history
extends StateMachine

var state_history: Array[String] = []
var max_history: int = 10

func _on_state_transition(new_state_name: String):
    # Store state history
    state_history.append(current_state.name)
    if state_history.size() > max_history:
        state_history.pop_front()
    
    # Continue with normal transition
    super._on_state_transition(new_state_name)

func go_to_previous_state():
    if state_history.size() > 0:
        var previous = state_history.pop_back()
        _on_state_transition(previous)
```

### Parallel States

```gdscript
# Handle multiple active states
class_name ParallelStateMachine
extends Node

var active_states: Array[State] = []

func activate_state(state_name: String):
    if _states.has(state_name):
        var state = _states[state_name]
        if not state in active_states:
            active_states.append(state)
            state.enter()

func deactivate_state(state_name: String):
    if _states.has(state_name):
        var state = _states[state_name]
        if state in active_states:
            active_states.erase(state)
            state.exit()

func _process(delta):
    for state in active_states:
        state.update(delta)
```

## State Persistence

### Save/Load State

```gdscript
func save_state() -> Dictionary:
    return {
        "current_state": current_state.name,
        "state_data": current_state.save_data() if current_state.has_method("save_data") else {}
    }

func load_state(data: Dictionary):
    if data.has("current_state"):
        _on_state_transition(data.current_state)
        
    if data.has("state_data") and current_state.has_method("load_data"):
        current_state.load_data(data.state_data)
```

## Best Practices

1. **Keep States Simple**: Each state should handle one behavior
2. **Use Clear Names**: State names should describe the behavior
3. **Avoid State Logic in Main Class**: Delegate to state classes
4. **Handle Transitions Carefully**: Validate state changes
5. **Document State Flows**: Create diagrams for complex state machines
6. **Test State Transitions**: Verify all transitions work correctly

## Debugging States

```gdscript
# Debug overlay for state visualization
extends CanvasLayer

@onready var state_label: Label = $StateLabel
var state_machine: StateMachine

func _ready():
    state_machine = get_tree().get_first_node_in_group("player").get_node("StateMachine")

func _process(_delta):
    if state_machine and state_machine.current_state:
        state_label.text = "State: " + state_machine.current_state.name
```