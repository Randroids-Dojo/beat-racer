# Node Organization

## Node Hierarchy Best Practices

### Use the Right Node for the Job

- `Node2D` for any object that needs transformation (position, rotation, scale)
- `Control` nodes for UI elements
- `Area2D` for collision detection without physics
- `StaticBody2D` for immovable objects
- `CharacterBody2D` for player-controlled entities
- `RigidBody2D` for physics-driven objects

### Keep Hierarchies Flat Where Possible

- Deeply nested nodes impact performance
- Group related nodes under organizational parent nodes
- Prefer composition over deep inheritance

### Name Nodes Clearly

- Use names that describe function, not appearance
- Include node type for clarity (e.g., `player_sprite` instead of just `sprite`)
- Be consistent with naming patterns across the project

## Node Communication

Follow the "Call Down, Signal Up" principle:
- Parent nodes access children directly via method calls
- Child nodes communicate with parents via signals
- Sibling nodes should generally not communicate directly

### Example

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

## Common Node Patterns

### For Game Entities
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

### For UI Elements
```
Control (root)
|-- MarginContainer
|   |-- VBoxContainer
|   |   |-- Label
|   |   |-- ProgressBar
|   |   |-- HBoxContainer
|   |   |   |-- Button
|   |   |   |-- Button
```

## Performance Considerations

1. Minimize node count where possible
2. Use visibility notifiers to disable off-screen processing
3. Group static nodes under a single parent
4. Consider using pooling for frequently created/destroyed nodes

## Best Practices

1. Document complex node structures
2. Use descriptive names that indicate purpose
3. Keep related functionality together
4. Avoid circular dependencies
5. Use scene instances for reusable components