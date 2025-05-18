# Godot 4 Best Practices for 2D Desktop Games

## Important: Critical Audio Implementation Notes
- AudioEffectDelay does NOT have a 'mix' property - use 'dry' instead (verified in test_comprehensive_audio.gd)
- Sliders MUST have step = 0.01 for smooth operation (binary behavior otherwise)
- Always run test_comprehensive_audio.gd before implementing audio effects
- See [Audio Effect Guidelines](#audio-effect-guidelines) and [Build and Testing](#build-and-testing) sections

## Table of Contents
1. [Project Structure](#project-structure)
2. [Node Organization](#node-organization)
3. [Scene Composition](#scene-composition)
4. [Scripting Patterns](#scripting-patterns)
5. [Input Handling](#input-handling)
6. [Performance Optimization](#performance-optimization)
7. [Audio Implementation](#audio-implementation)
8. [Signal Management](#signal-management)
9. [Resource Management](#resource-management)
10. [State Management](#state-management)
11. [UI Design](#ui-design)
12. [Debugging Techniques](#debugging-techniques)

---

## Project Structure

### Directory Organization
Organize your project with a clear folder structure to maintain cleanliness as it scales:

```
/project.godot
/addons/                 # Third-party plugins
/assets/
    /audio/
        /music/
        /sfx/
    /fonts/
    /sprites/
        /characters/
        /environment/
        /ui/
    /shaders/
/scenes/
    /levels/
    /ui/
    /characters/
    /common/             # Reusable scene components
/scripts/
    /autoloads/
    /resources/          # Custom resource scripts
    /components/         # Reusable behavior scripts
/resources/              # Non-script resources
    /themes/
    /presets/
```

### Naming Conventions
- Use `snake_case` for folders, files, node names, and variables
- Use `PascalCase` for classes and custom resources
- Prefix autoloaded singletons with an underscore (e.g., `_GameState`)
- Use descriptive names that indicate purpose

### Import Settings
- Configure project-wide import presets for textures
- For 2D games, disable mipmaps unless needed for distant objects
- Set appropriate compression settings based on asset type
- Use texture atlases for related sprites to reduce draw calls

---

## Node Organization

### Node Hierarchy Best Practices

1. **Use the right node for the job**:
   - `Node2D` for any object that needs transformation (position, rotation, scale)
   - `Control` nodes for UI elements
   - `Area2D` for collision detection without physics
   - `StaticBody2D` for immovable objects
   - `CharacterBody2D` for player-controlled entities
   - `RigidBody2D` for physics-driven objects

2. **Keep hierarchies flat where possible**:
   - Deeply nested nodes impact performance
   - Group related nodes under organizational parent nodes

3. **Name nodes clearly**:
   - Use names that describe function, not appearance
   - Include node type for clarity (e.g., `player_sprite` instead of just `sprite`)

### Node Communication

Follow the "Call Down, Signal Up" principle:
- Parent nodes access children directly via method calls
- Child nodes communicate with parents via signals
- Sibling nodes should generally not communicate directly

Example:
```gdscript
# In the parent node
func _ready():
    $PlayerCharacter.hit.connect(_on_player_hit)

func _on_player_hit(damage_amount):
    update_ui()
    check_game_over_condition()

# In the child node (PlayerCharacter)
signal hit(damage_amount)

func take_damage(amount):
    health -= amount
    hit.emit(amount)
```

---

## Scene Composition

### Scene Instancing

Follow a component-based approach:
- Create small, reusable scenes for common elements
- Instance these scenes within larger scenes
- Use script inheritance sparingly; prefer composition

Example folder of reusable components:
```
/scenes/common/
    health_component.tscn
    hitbox_component.tscn
    hurtbox_component.tscn
    pickup_detector.tscn
```

### Scene Tree Structure

For a typical 2D game entity:
```
CharacterBody2D (root)
|-- CollisionShape2D
|-- AnimatedSprite2D
|-- AudioStreamPlayer2D
|-- Weapons (Node2D)
|   |-- PrimaryWeapon
|   |-- SecondaryWeapon
|-- HitboxComponent (Area2D instance)
|-- HealthComponent (Node instance)
```

For a typical 2D level:
```
Level (Node2D)
|-- Background
|   |-- ParallaxBackground
|   |-- TileMap (background layer)
|-- Gameplay
|   |-- TileMap (main collision layer)
|   |-- Entities
|   |   |-- Player
|   |   |-- Enemies
|   |-- Collectibles
|   |-- Triggers
|-- Foreground
|   |-- TileMap (foreground details)
|-- Camera2D
|-- UI
|   |-- GameplayHUD
```

---

## Scripting Patterns

### Script Organization

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

### GDScript 2.0 Features

Take advantage of Godot 4's improved GDScript:

1. **Static typing** for better performance and error detection:
```gdscript
var health: int = 100
var direction: Vector2 = Vector2.ZERO
var enemies: Array[Enemy] = []
```

2. **Lambda functions** for cleaner callbacks:
```gdscript
$Button.pressed.connect(func(): _start_game())
enemies.sort_custom(func(a, b): return a.position.x < b.position.x)
```

3. **Custom properties** with getters/setters:
```gdscript
var _health: int = 100

var health:
    get:
        return _health
    set(value):
        _health = clampi(value, 0, max_health)
        health_changed.emit(_health)
```

4. **Typed arrays** for better performance:
```gdscript
var damage_values: Array[float] = [10.5, 20.0, 15.5]
var spawn_points: Array[Vector2] = []
```

---

## Input Handling

### Input Architecture

Create a dedicated input handling system:
1. Define input mappings in Project Settings > Input Map
2. Create an autoloaded InputHandler singleton for game-wide access

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

### Input Buffering
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

---

## Performance Optimization

### General Performance Tips

1. **Use Visibility Notifiers**:
   - Disable processing for off-screen entities
   ```gdscript
   func _ready():
       $VisibleOnScreenNotifier2D.screen_exited.connect(func(): set_process(false))
       $VisibleOnScreenNotifier2D.screen_entered.connect(func(): set_process(true))
   ```

2. **Object Pooling**:
   - Reuse objects instead of frequent instantiation/deletion
   ```gdscript
   # Basic object pool
   var _bullet_pool: Array[Node] = []
   var _pool_size: int = 20
   
   func _ready():
       for i in range(_pool_size):
           var bullet = preload("res://scenes/bullet.tscn").instantiate()
           bullet.visible = false
           add_child(bullet)
           _bullet_pool.append(bullet)
   
   func get_bullet() -> Node:
       for bullet in _bullet_pool:
           if not bullet.visible:
               bullet.visible = true
               return bullet
       return null  # Pool exhausted
   ```

3. **Optimize Physics**:
   - Use larger physics timesteps when possible
   - Disable collision objects when not needed
   - Set appropriate collision layers and masks

4. **Optimize Drawing**:
   - Group sprites in texture atlases
   - Use GPU Particles2D instead of CPUParticles2D
   - For static elements, consider using a single static image rather than many sprites

---

## Audio Implementation

### Audio Architecture

Create a flexible audio system using buses:

1. Configure audio buses in the AudioServer:
```gdscript
# In an autoloaded audio manager
func _ready():
    # Get default bus indices
    var master_idx = AudioServer.get_bus_index("Master")
    
    # Create music bus
    AudioServer.add_bus()
    var music_idx = AudioServer.get_bus_count() - 1
    AudioServer.set_bus_name(music_idx, "Music")
    AudioServer.set_bus_send(music_idx, "Master")
    
    # Add reverb to music
    var reverb = AudioEffectReverb.new()
    reverb.wet = 0.2
    AudioServer.add_bus_effect(music_idx, reverb)
    
    # Create SFX bus with compression
    AudioServer.add_bus()
    var sfx_idx = AudioServer.get_bus_count() - 1
    AudioServer.set_bus_name(sfx_idx, "SFX")
    AudioServer.set_bus_send(sfx_idx, "Master")
    
    var compressor = AudioEffectCompressor.new()
    AudioServer.add_bus_effect(sfx_idx, compressor)
```

2. Create audio pools for efficient sound playback:
```gdscript
var _sfx_players: Array[AudioStreamPlayer] = []
const _pool_size: int = 10

func _ready():
    # Setup pools
    for i in range(_pool_size):
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        player.finished.connect(func(): _return_to_pool(player))
        _sfx_players.append(player)

func play_sound(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0):
    var player = _get_available_player()
    if player:
        player.stream = stream
        player.volume_db = volume_db
        player.pitch_scale = pitch_scale
        player.play()

func _get_available_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            return player
    return null  # All players are busy
```

### Procedural Audio

For dynamic sound generation (useful for Beat Racer):

```gdscript
extends Node

var _stream_player: AudioStreamPlayer
var _stream_playback: AudioStreamGeneratorPlayback
var _generator: AudioStreamGenerator

# Sound parameters
var frequency: float = 440.0  # Hz
var volume: float = 0.5
var sample_hz: float = 44100.0

func _ready():
    # Create generator stream
    _generator = AudioStreamGenerator.new()
    _generator.mix_rate = sample_hz
    _generator.buffer_length = 0.1  # 100ms buffer
    
    # Setup player
    _stream_player = AudioStreamPlayer.new()
    _stream_player.stream = _generator
    add_child(_stream_player)
    _stream_player.play()
    
    # Get playback interface
    _stream_playback = _stream_player.get_stream_playback()

func _process(_delta):
    _fill_buffer()

func _fill_buffer():
    var frames_available = _stream_playback.get_frames_available()
    if frames_available > 0:
        var phase = 0.0
        for i in range(frames_available):
            var frame_value = sin(phase * TAU) * volume
            _stream_playback.push_frame(Vector2(frame_value, frame_value))  # Stereo: left, right
            
            # Advance phase for next sample
            phase = fmod(phase + (frequency / sample_hz), 1.0)

func set_note(note_frequency: float):
    frequency = note_frequency
```

---

## Signal Management

### Signal Best Practices

1. **Clear Signal Names**:
   - Use verb-noun or past-tense naming: `health_changed`, `bullet_fired`
   - Include relevant parameters: `damage_taken(amount, source)`

2. **Document Signals**:
   - Add comments describing when signals are emitted
   - Document parameter meanings

3. **Global Event Bus**:
   - For game-wide events, use a singleton event bus:

```gdscript
# scripts/autoloads/events.gd
extends Node

# Game flow signals
signal game_started
signal game_paused(is_paused)
signal game_over(final_score)

# Player-related signals
signal player_health_changed(new_health, max_health)
signal player_collected_item(item_type, amount)

# Level-related signals
signal level_completed(level_number, completion_time)
signal checkpoint_reached(checkpoint_id)
```

4. **Connect using functions instead of inline lambdas** for complex handlers:
```gdscript
# Good (for complex handlers)
func _ready():
    Events.player_health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(new_health, max_health):
    # Complex handling logic
    
# Good (for simple handlers)
func _ready():
    Events.checkpoint_reached.connect(func(id): print("Checkpoint %s reached" % id))
```

---

## Resource Management

### Resource-Based Design

Use Godot's resource system for data-driven design:

1. **Create custom resources**:
```gdscript
# scripts/resources/weapon_data.gd
class_name WeaponData
extends Resource

@export var name: String = "Pistol"
@export var damage: float = 10.0
@export var fire_rate: float = 0.5
@export var projectile_scene: PackedScene
@export var icon: Texture2D
@export var sfx_fire: AudioStream
```

2. **Create resource instances**:
   - Save as `.tres` files
   - Reference in scripts with `preload`
   - Swap resources to change behavior

3. **Use resources for configuration**:
```gdscript
# In a weapon script
@export var weapon_data: WeaponData

func _ready():
    $Sprite2D.texture = weapon_data.icon
    
func fire():
    var projectile = weapon_data.projectile_scene.instantiate()
    projectile.damage = weapon_data.damage
    # ... setup and add projectile to scene
    
    AudioManager.play_sfx(weapon_data.sfx_fire)
    await get_tree().create_timer(weapon_data.fire_rate).timeout
    can_fire = true
```

### Resource Preloading

Preload resources for better performance:
```gdscript
# Preload resources at script level for static resources
const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const EXPLOSION_EFFECT = preload("res://scenes/effects/explosion.tscn")
const HIT_SOUND = preload("res://assets/audio/sfx/hit.wav")

# For variable resources, load in _ready
var _enemy_scenes: Dictionary = {}

func _ready():
    _enemy_scenes = {
        "goblin": preload("res://scenes/enemies/goblin.tscn"),
        "skeleton": preload("res://scenes/enemies/skeleton.tscn"),
        "boss": preload("res://scenes/enemies/boss.tscn")
    }
```

---

## State Management

### State Machine Pattern

Implement a basic state machine:

```gdscript
# Base State class (scripts/components/state.gd)
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

```gdscript
# State Machine (scripts/components/state_machine.gd)
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
        return
        
    if current_state:
        current_state.exit()
        
    current_state = _states[new_state_name]
    current_state.enter()
```

Example implementation:
```gdscript
# Player state implementation
extends State

func enter() -> void:
    owner.animation_player.play("idle")
    
func physics_update(delta: float) -> void:
    # Check for movement input
    if Input.get_vector("left", "right", "up", "down").length() > 0:
        transitioned.emit("Run")
    
    # Check for jump input
    if Input.is_action_just_pressed("jump") and owner.is_on_floor():
        transitioned.emit("Jump")
```

---

## UI Design

### UI Architecture

Organize UI elements:

```
UI (CanvasLayer)
|-- SafeArea (Control - anchored to full screen)
|   |-- GameplayHUD
|   |   |-- TopBar
|   |   |   |-- HealthBar
|   |   |   |-- ScoreDisplay
|   |   |-- BottomBar
|   |   |   |-- AbilityIcons
|   |-- PauseMenu
|   |-- GameOverScreen
|   |-- LevelCompleteScreen
```

### UI Best Practices

1. **Use theme resources** for consistent styling:
   - Create a `.tres` theme with fonts, colors, styles
   - Apply at the top level of UI hierarchy
   - Override for specific elements

2. **Support multiple resolutions**:
   - Use anchors and margins instead of fixed positions
   - Test on different aspect ratios
   - Use the `SafeArea` pattern for mobile support

3. **Separate UI logic** from game logic:
   - Connect to game events via signals
   - Avoid direct references to game objects from UI

### Slider Configuration Best Practices

When creating sliders for volume or other continuous controls:

1. **Always set the step property**:
   ```gdscript
   # In code
   slider.step = 0.01  # Allows fine-grained control
   ```
   Or in the scene file:
   ```
   [node name="HSlider" type="HSlider"]
   max_value = 1.0
   step = 0.01
   value = 1.0
   ```

2. **Configure sliders programmatically as a failsafe**:
   ```gdscript
   func _ready():
       for slider in [master_slider, melody_slider, bass_slider]:
           slider.min_value = 0.0
           slider.max_value = 1.0
           slider.step = 0.01
   ```

3. **Use appropriate value mapping**:
   - For audio: Use `linear_to_db()` and `db_to_linear()` conversions
   - Store linear values (0-1) in UI, convert to dB for audio
   - Default linear 0.5 = -6dB is a good standard

Example UI script:
```gdscript
extends Control

func _ready():
    # Connect to relevant events
    Events.player_health_changed.connect(_update_health_bar)
    Events.player_collected_item.connect(_update_inventory)
    Events.game_paused.connect(_toggle_pause_menu)
    
    # Setup initial UI state
    _update_health_bar(PlayerStats.current_health, PlayerStats.max_health)

func _update_health_bar(current_health, max_health):
    $TopBar/HealthBar.max_value = max_health
    $TopBar/HealthBar.value = current_health
    
    # Update color based on health percentage
    var health_percent = float(current_health) / max_health
    if health_percent < 0.3:
        $TopBar/HealthBar.modulate = Color.RED
    else:
        $TopBar/HealthBar.modulate = Color.GREEN

func _toggle_pause_menu(is_paused):
    $PauseMenu.visible = is_paused
    
    # Disable gameplay HUD when paused
    $GameplayHUD.visible = !is_paused
```

---

## Audio Effect Guidelines

### Verification Before Implementation

When implementing audio systems in Godot 4, ALWAYS verify effect properties before using them:

1. **Use Context7 for Documentation**:
   - First call `mcp__context7-mcp__resolve-library-id` with `libraryName: "godot"` to get the library ID
   - Then call `mcp__context7-mcp__get-library-docs` with the library ID and specific class name
   - Example for AudioEffectDelay: look up its properties in the docs before using them

2. **Property Verification**:
   - Use the `verification_helpers.gd` script to check if properties exist
   - Test with `property_exists(effect, "property_name")` before setting properties
   - List available properties with `list_properties(effect)` if unsure

3. **Use Audio Debugging Tools**:
   - Initialize with `audio_debugger = preload("res://scripts/components/audio_debugger.gd").new()`
   - Test effects with `audio_debugger.test_effect("effect_type")`

4. **Context7 Usage Example**:
   ```
   # Get the Godot library ID
   mcp__context7-mcp__resolve-library-id:
     libraryName: "godot"
   
   # Get documentation for specific class
   mcp__context7-mcp__get-library-docs:
     context7CompatibleLibraryID: <returned_id>
     topic: "AudioEffectDelay"
   ```

5. **Important Notes (Verified in test_comprehensive_audio.gd)**:
   - AudioEffectDelay does NOT have a 'mix' property - use 'dry' instead ✓
   - Different audio effects have different property names for similar concepts
   - Always verify property names using Context7 before implementation
   - Test in small pieces before implementing full systems

### Common Implementation Mistakes

1. **UI Control Issues**:
   - **Problem**: Sliders only showing 0 or 1 values
   - **Cause**: Missing `step` property in scene file
   - **Solution**: Always set `step = 0.01` for continuous controls
   - **Prevention**: Configure sliders programmatically as failsafe

2. **Audio Stream Generation**:
   - **Problem**: Test sounds not playing
   - **Cause**: Incorrect async handling or missing null checks
   - **Solution**: Generate all audio frames immediately, check stream playback
   - **Prevention**: Add error checking and status logging

3. **Missing Feedback**:
   - **Problem**: Issues hard to diagnose from logs
   - **Cause**: Insufficient logging at critical points
   - **Solution**: Log all user actions and system responses
   - **Prevention**: Implement comprehensive logging system from start

---

## Build and Testing

### GUT Testing Framework

The Beat Racer project uses the Godot Unit Test (GUT) framework for comprehensive testing:

1. **Run Complete Test Suite**:
   ```bash
   ./run_gut_tests.sh
   # or with JUnit XML report:
   ./run_gut_tests.sh --report
   ```

2. **Test Result Management**:
   - Test results (*.xml files) are automatically ignored by git
   - Clean up test results: `rm test_results*.xml`
   - Test results directory (`/test_results/`) is also ignored
   - No test result files should be committed to the repository

3. **Test Organization**:
   ```
   tests/gut/
   ├── unit/                 # Unit tests for individual components
   │   ├── test_audio_effect_properties.gd
   │   ├── test_audio_generation.gd
   │   └── test_ui_configuration.gd
   ├── integration/          # Integration tests for system interactions
   │   └── test_audio_system_integration.gd
   └── verification/         # Verification tests for framework and assumptions
       └── test_gut_conversion_validation.gd
   ```

4. **Key Test Areas**:
   - **Audio Effect Properties**: Verifies AudioEffectDelay uses 'dry' not 'mix' ✓
   - **Audio Bus Management**: Tests bus creation, routing, and effects
   - **Sound Generation**: Tests procedural audio generation
   - **UI Configuration**: Verifies slider step=0.01 for smooth control
   - **System Integration**: Tests component interactions

5. **Running Specific Tests**:
   ```bash
   # Test specific category
   godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut/unit/
   
   # Test specific file
   godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/gut/unit/test_audio_effect_properties.gd
   ```

6. **CI/CD Integration**:
   - Headless execution support
   - JUnit XML report generation
   - Exit codes for success/failure
   - Configurable through `.gutconfig.json`

### Testing Best Practices

1. **Always Test UI Controls**:
   - Verify sliders have step = 0.01 (CRITICAL - verified in test_ui_configuration.gd)
   - Check initial values match expected defaults
   - Test edge cases (min/max values)
   - Ensure visual feedback matches internal state

2. **Test Audio Generation**:
   - Verify all test sounds play correctly
   - Check audio streams initialize properly
   - Test rapid button clicks for stability
   - Monitor logs for generation confirmation

3. **Effect Property Testing**:
   - Always verify properties exist before using them
   - Remember: AudioEffectDelay uses 'dry' not 'mix' ✓
   - Check property names with verification helpers
   - Use GUT assertions for clear test results

4. **GUT Test Conventions**:
   - Extend GutTest for all test classes
   - Use descriptive test method names (test_*)
   - One assertion per test when possible
   - Use describe() for test context
   - Clean up resources in after_each()

5. **Common Pitfalls to Avoid**:
   - Missing `step` property on sliders (causes binary behavior)
   - Using wrong property names (e.g., 'mix' on AudioEffectDelay)
   - Incorrect async handling in audio generation
   - Missing null checks for stream playback
   - Assuming default values without explicit setting

---

## Debugging Techniques

### Built-in Debug Tools

1. **Print statements with context**:
```gdscript
print("[Player] Health changed: ", old_health, " -> ", new_health)
```

2. **Use the Godot Debugger Panel**:
   - Print call stack when errors occur
   - Monitor variables in real-time
   - Set breakpoints for stepping through code

3. **Visual debugging**:
```gdscript
func _draw():
    if OS.is_debug_build():
        # Draw hitbox outline
        draw_rect(Rect2($CollisionShape2D.position - $CollisionShape2D.shape.extents, 
                 $CollisionShape2D.shape.extents * 2),
                 Color.RED, false, 2.0)
        
        # Draw movement vector
        draw_line(Vector2.ZERO, _velocity.normalized() * 50, Color.GREEN, 2.0)
```

### Comprehensive Logging System

Implement a logging system that makes debugging easier:

1. **Structured Log Messages**:
```gdscript
func _log(message: String) -> void:
    if _debug_logging:
        var timestamp = Time.get_time_string_from_system()
        print("[%s] %s: %s" % [timestamp, get_class(), message])
```

2. **Log Different Operations**:
```gdscript
# Log initialization
_log("=== AudioManager Starting Initialization ===")
_log("Godot version: " + Engine.get_version_info().string)

# Log operations with parameters
_log("Playing test tone on bus '%s': frequency=%fHz, duration=%fs" % 
    [bus_name, frequency, duration])

# Log errors clearly
_log("ERROR: Failed to get stream playback")

# Log completion
_log("Operation complete - %d items processed" % count)
```

3. **Log Analysis Tips**:
   - Look for missing expected operations (e.g., "Playing test tone" after button press)
   - Check for sequence errors (initialization happening out of order)
   - Watch for error messages or unexpected values
   - Compare initial values with expected defaults
   - Track user interactions to reproduction steps

### Common Audio Stream Issues

When implementing audio streaming:

1. **Always check stream playback availability**:
```gdscript
var playback = player.get_stream_playback()
if playback == null:
    print("ERROR: Failed to get stream playback")
    player.queue_free()
    return
```

2. **Generate audio data immediately**:
```gdscript
# Don't spread generation across frames with await
for i in range(frames_to_generate):
    var value = generate_sample(i)
    playback.push_frame(Vector2(value, value))

# Then await the finished signal
await player.finished
player.queue_free()
```

3. **Add status logs for debugging**:
```gdscript
_log("Generating percussion sound...")
_log("Percussion sound generated, %d frames" % frames_to_generate)
_log("Percussion player cleaned up")
```

### Custom Debug Systems

Create a debug overlay system:
```gdscript
# scripts/autoloads/debug_overlay.gd
extends CanvasLayer

var stats = {}
var enabled = OS.is_debug_build()

func _ready():
    if not enabled:
        queue_free()
        return
        
    var debug_panel = Panel.new()
    debug_panel.anchor_right = 0.2
    debug_panel.anchor_bottom = 1.0
    
    var label = Label.new()
    label.name = "StatsLabel"
    label.anchor_right = 1.0
    label.anchor_bottom = 1.0
    label.text = "Debug Stats:"
    
    debug_panel.add_child(label)
    add_child(debug_panel)

func _process(_delta):
    if not enabled:
        return
        
    # Update FPS
    stats["FPS"] = Engine.get_frames_per_second()
    
    # Update dynamic stats
    if get_node_or_null("/root/Level/Player"):
        var player = get_node("/root/Level/Player")
        stats["Player Position"] = player.global_position
        stats["Player Health"] = player.health
    
    # Format and display stats
    var stats_text = "Debug Stats:\n"
    for key in stats.keys():
        stats_text += key + ": " + str(stats[key]) + "\n"
    
    $Panel/StatsLabel.text = stats_text
```

---

## Conclusion

These best practices will help you create a well-structured, maintainable, and performant 2D game in Godot 4. Remember that these are guidelines rather than strict rules - adapt them to suit your specific project needs.

For any aspect that needs further exploration, consider consulting the [official Godot documentation](https://docs.godotengine.org/en/stable/) or the excellent community resources like [GDQuest](https://www.gdquest.com/) and [KidsCanCode](https://kidscancode.org/godot_recipes/).

Happy game development!