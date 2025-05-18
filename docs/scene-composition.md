# Scene Composition

## Scene Instancing

Follow a component-based approach:
- Create small, reusable scenes for common elements
- Instance these scenes within larger scenes
- Use script inheritance sparingly; prefer composition

### Example Folder of Reusable Components
```
/scenes/common/
    health_component.tscn
    hitbox_component.tscn
    hurtbox_component.tscn
    pickup_detector.tscn
```

## Scene Tree Structure

### For a Typical 2D Game Entity
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

### For a Typical 2D Level
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

## Component-Based Design

### Health Component Example
```gdscript
# scenes/common/health_component.gd
extends Node
class_name HealthComponent

signal health_changed(current, maximum)
signal died

@export var max_health: float = 100.0
var current_health: float

func _ready():
    current_health = max_health

func take_damage(amount: float):
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    
    if current_health <= 0:
        died.emit()

func heal(amount: float):
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
```

## Scene Instancing Best Practices

1. **Prefer Composition Over Inheritance**
   - Use scene instances instead of complex inheritance chains
   - Component scenes should be single-purpose

2. **Standardize Component Interfaces**
   - Use consistent signal names across similar components
   - Document expected node structure

3. **Use Resource Files for Configuration**
   - Store component settings in `.tres` files
   - Allow runtime swapping of configurations

## Example: Player Character Scene

```
Player.tscn structure:
CharacterBody2D "Player"
|-- CollisionShape2D
|-- AnimatedSprite2D
|-- HealthComponent (instance of health_component.tscn)
|-- HitboxComponent (instance of hitbox_component.tscn)
|-- StateManager
|   |-- IdleState
|   |-- RunState
|   |-- JumpState
|-- AudioStreamPlayer2D "FootstepPlayer"
|-- AudioStreamPlayer2D "JumpSoundPlayer"
```

## Scene Organization Tips

1. Group related nodes under empty Node2D parents
2. Use clear naming conventions
3. Keep scenes focused on a single responsibility
4. Document complex scene structures
5. Use @tool scripts for editor-time helpers

## Beat Racer Specific Considerations

For a rhythm-based game like Beat Racer:
- Keep audio components at consistent hierarchy levels
- Use separate scenes for visual feedback elements
- Instance beat markers dynamically from a pool
- Organize tracks and obstacles in clear parent nodes