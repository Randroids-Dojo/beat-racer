# Resource Management

## Resource-Based Design

Use Godot's resource system for data-driven design:

### Create Custom Resources

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
@export var sfx_reload: AudioStream
```

### Create Resource Instances

1. Save as `.tres` files
2. Reference in scripts with `preload`
3. Swap resources to change behavior

### Use Resources for Configuration

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

## Resource Preloading

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

## Beat Racer Resource Examples

### Track Configuration

```gdscript
# scripts/resources/track_data.gd
class_name TrackData
extends Resource

@export var track_name: String = "Highway Rush"
@export var music_file: AudioStream
@export var bpm: float = 120.0
@export var difficulty: float = 1.0
@export var track_segments: Array[PackedScene] = []
@export var obstacle_patterns: Array[Resource] = []
```

### Obstacle Patterns

```gdscript
# scripts/resources/obstacle_pattern.gd
class_name ObstaclePattern
extends Resource

@export var pattern_name: String
@export var obstacles: Array[Vector2] = []  # Position and timing
@export var min_speed: float = 100.0
@export var max_speed: float = 300.0
```

### Power-up Configuration

```gdscript
# scripts/resources/power_up_data.gd
class_name PowerUpData
extends Resource

@export var power_up_name: String
@export var duration: float = 5.0
@export var icon: Texture2D
@export var pickup_sound: AudioStream
@export var activate_sound: AudioStream
@export var particle_effect: PackedScene
```

## Resource Loading Strategies

### Lazy Loading

```gdscript
class_name ResourceLoader
extends Node

var _loaded_resources: Dictionary = {}

func get_resource(path: String) -> Resource:
    if not _loaded_resources.has(path):
        _loaded_resources[path] = load(path)
    return _loaded_resources[path]

func preload_resources(paths: Array[String]):
    for path in paths:
        _loaded_resources[path] = load(path)
```

### Background Loading

```gdscript
extends Node

signal resource_loaded(path: String, resource: Resource)

var _loading_thread: Thread
var _load_queue: Array[String] = []
var _loaded_resources: Dictionary = {}

func _ready():
    _loading_thread = Thread.new()
    _loading_thread.start(_loading_process)

func queue_load(path: String):
    _load_queue.append(path)

func _loading_process():
    while true:
        if _load_queue.size() > 0:
            var path = _load_queue.pop_front()
            var resource = load(path)
            _loaded_resources[path] = resource
            call_deferred("_emit_loaded", path, resource)
        else:
            OS.delay_msec(100)

func _emit_loaded(path: String, resource: Resource):
    resource_loaded.emit(path, resource)
```

## Resource Pooling

### Scene Instance Pool

```gdscript
class_name ScenePool
extends Node

var _pool: Array[Node] = []
var _scene: PackedScene
var _pool_size: int

func _init(scene_path: String, size: int = 10):
    _scene = load(scene_path)
    _pool_size = size

func _ready():
    for i in _pool_size:
        var instance = _scene.instantiate()
        instance.set_process(false)
        instance.visible = false
        add_child(instance)
        _pool.append(instance)

func get_instance() -> Node:
    for instance in _pool:
        if not instance.visible:
            instance.visible = true
            instance.set_process(true)
            return instance
    
    # Expand pool if needed
    var new_instance = _scene.instantiate()
    add_child(new_instance)
    _pool.append(new_instance)
    return new_instance

func return_instance(instance: Node):
    instance.visible = false
    instance.set_process(false)
    if instance.has_method("reset"):
        instance.reset()
```

## Resource Management Best Practices

### Memory Management

```gdscript
class_name ResourceManager
extends Node

var _resource_cache: Dictionary = {}
var _cache_size_limit: int = 100

func load_resource(path: String) -> Resource:
    if _resource_cache.has(path):
        return _resource_cache[path]
    
    var resource = load(path)
    _add_to_cache(path, resource)
    return resource

func _add_to_cache(path: String, resource: Resource):
    if _resource_cache.size() >= _cache_size_limit:
        _clear_oldest_resource()
    
    _resource_cache[path] = resource

func _clear_oldest_resource():
    # Simple FIFO implementation
    var keys = _resource_cache.keys()
    if keys.size() > 0:
        _resource_cache.erase(keys[0])

func clear_cache():
    _resource_cache.clear()
```

### Resource Validation

```gdscript
static func validate_resource(resource: Resource, expected_type: String) -> bool:
    if resource == null:
        push_error("Resource is null")
        return false
    
    if resource.get_class() != expected_type:
        push_error("Resource type mismatch. Expected: %s, Got: %s" % [expected_type, resource.get_class()])
        return false
    
    return true
```

## Resource Organization

### Directory Structure
```
/resources/
    /audio/
        /music_tracks/
        /sound_effects/
    /data/
        /tracks/
        /obstacles/
        /power_ups/
    /visual/
        /materials/
        /shaders/
        /themes/
```

### Naming Conventions
- Use descriptive names: `track_highway_rush.tres`
- Include type in name: `powerup_speed_boost.tres`
- Version resources: `enemy_config_v2.tres`

## Performance Tips

1. **Preload Common Resources**: Load frequently used resources at startup
2. **Use Resource Pools**: Reuse instances instead of creating new ones
3. **Profile Memory Usage**: Monitor resource consumption
4. **Unload Unused Resources**: Clear caches periodically
5. **Optimize Resource Sizes**: Compress textures and audio appropriately

## Testing Resources

```gdscript
func test_resource_loading():
    var track_data = load("res://resources/data/tracks/track_1.tres") as TrackData
    assert(track_data != null, "Track data should load")
    assert(track_data.track_name != "", "Track should have name")
    assert(track_data.music_file != null, "Track should have music")
```