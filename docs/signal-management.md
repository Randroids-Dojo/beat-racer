# Signal Management

## Signal Best Practices

### 1. Clear Signal Names

Use verb-noun or past-tense naming:
- `health_changed`
- `bullet_fired`
- `enemy_spawned`
- `level_completed`

Include relevant parameters:
- `damage_taken(amount, source)`
- `item_collected(item_type, quantity)`
- `score_updated(new_score, delta)`

### 2. Document Signals

Add comments describing when signals are emitted:

```gdscript
class_name Player
extends CharacterBody2D

# Emitted when the player takes damage from any source
signal damaged(amount: float, source: Node)

# Emitted when the player's health reaches zero
signal died

# Emitted when the player collects a power-up
signal power_up_collected(type: String)

# Emitted each frame while the player is moving
signal moved(velocity: Vector2)
```

### 3. Global Event Bus

For game-wide events, use a singleton event bus:

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
signal player_died
signal player_respawned

# Level-related signals
signal level_completed(level_number, completion_time)
signal checkpoint_reached(checkpoint_id)
signal boss_defeated(boss_name)

# UI-related signals
signal menu_opened(menu_name)
signal menu_closed(menu_name)
signal settings_changed(setting_name, value)
```

### 4. Connection Best Practices

Connect using functions for complex handlers:

```gdscript
# Good (for complex handlers)
func _ready():
    Events.player_health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(new_health, max_health):
    update_health_bar(new_health, max_health)
    check_low_health_effects(new_health)
    update_ui_color(new_health / max_health)

# Good (for simple handlers)
func _ready():
    Events.checkpoint_reached.connect(func(id): print("Checkpoint %s reached" % id))
```

## Signal Patterns

### One-Shot Connections

For signals that should only be handled once:

```gdscript
func wait_for_player_death():
    Events.player_died.connect(_on_player_died, CONNECT_ONE_SHOT)

func _on_player_died():
    show_game_over_screen()
    # Connection is automatically removed after first emission
```

### Deferred Connections

For operations that should happen after the current frame:

```gdscript
func _ready():
    Events.level_completed.connect(_on_level_completed, CONNECT_DEFERRED)

func _on_level_completed(level_number, completion_time):
    # This runs after the current frame completes
    get_tree().change_scene_to_file("res://scenes/levels/level_%d.tscn" % (level_number + 1))
```

### Signal Chaining

Chain signals through multiple objects:

```gdscript
# In Enemy class
signal defeated

func take_damage(amount):
    health -= amount
    if health <= 0:
        defeated.emit()

# In EnemySpawner class
func spawn_enemy():
    var enemy = enemy_scene.instantiate()
    enemy.defeated.connect(_on_enemy_defeated)
    add_child(enemy)

func _on_enemy_defeated():
    enemies_defeated += 1
    Events.enemy_defeated.emit()  # Propagate to global event bus
```

## Beat Racer Specific Signals

### Rhythm Game Signals

```gdscript
# In rhythm manager
signal beat_hit(accuracy: float, combo: int)
signal beat_missed
signal combo_achieved(combo_level: int)
signal perfect_streak(count: int)

# For dynamic music
signal intensity_changed(new_intensity: float)
signal track_section_changed(section_name: String)
```

### Track Progression Signals

```gdscript
# Track manager signals
signal obstacle_approaching(obstacle_type: String, time_to_hit: float)
signal track_segment_entered(segment_id: int)
signal speed_boost_activated(multiplier: float, duration: float)
```

## Performance Considerations

### Signal Disconnection

Always disconnect signals when objects are destroyed:

```gdscript
func _exit_tree():
    if Events.player_health_changed.is_connected(_on_player_health_changed):
        Events.player_health_changed.disconnect(_on_player_health_changed)
```

### Avoid Signal Spam

Throttle frequently emitted signals:

```gdscript
var _last_position_signal_time: float = 0.0
const POSITION_SIGNAL_INTERVAL: float = 0.1  # Emit at most 10 times per second

func _physics_process(delta):
    if Time.get_ticks_msec() / 1000.0 - _last_position_signal_time > POSITION_SIGNAL_INTERVAL:
        position_changed.emit(global_position)
        _last_position_signal_time = Time.get_ticks_msec() / 1000.0
```

## Best Practices

1. **Use Type Hints**: Specify parameter types in signal declarations
2. **Avoid Circular Dependencies**: Don't create signal loops
3. **Document Signal Flow**: Create diagrams for complex signal chains
4. **Test Signal Connections**: Verify signals connect and disconnect properly
5. **Use Meaningful Names**: Signal names should clearly indicate their purpose
6. **Group Related Signals**: Organize signals by system or feature

## Testing Signals

```gdscript
# In test files
func test_signal_emission():
    var player = Player.new()
    var signal_received = false
    
    player.health_changed.connect(func(health): signal_received = true)
    player.take_damage(10)
    
    assert(signal_received, "Signal should have been emitted")
```

## Common Patterns

### Observer Pattern

```gdscript
class_name Subject
extends Node

var _observers: Array = []

func attach(observer: Object):
    _observers.append(observer)

func detach(observer: Object):
    _observers.erase(observer)

func notify(event: String, data: Dictionary):
    for observer in _observers:
        if observer.has_method("on_event"):
            observer.on_event(event, data)
```

### Event Aggregator

```gdscript
# Collect multiple signals into one
extends Node

signal all_enemies_defeated

var total_enemies: int = 0
var defeated_enemies: int = 0

func _ready():
    Events.enemy_defeated.connect(_on_enemy_defeated)

func set_enemy_count(count: int):
    total_enemies = count
    defeated_enemies = 0

func _on_enemy_defeated():
    defeated_enemies += 1
    if defeated_enemies >= total_enemies:
        all_enemies_defeated.emit()
```