# UI Design

## UI Architecture

Organize UI elements with clear hierarchy:

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

## UI Best Practices

### 1. Use Theme Resources

Create consistent styling across your UI:

```gdscript
# Create a theme resource (.tres)
var theme = Theme.new()

# Set default font
var font = load("res://assets/fonts/main_font.ttf")
theme.set_default_font(font)

# Set colors
theme.set_color("font_color", "Label", Color.WHITE)
theme.set_color("font_color_hover", "Button", Color.YELLOW)

# Set styles
var button_style = StyleBoxFlat.new()
button_style.bg_color = Color(0.2, 0.2, 0.3)
button_style.corner_radius_top_left = 8
button_style.corner_radius_top_right = 8
button_style.corner_radius_bottom_left = 8
button_style.corner_radius_bottom_right = 8
theme.set_stylebox("normal", "Button", button_style)
```

### 2. Support Multiple Resolutions

Use anchors and margins effectively:

```gdscript
extends Control

func _ready():
    # Anchor to full screen
    anchor_left = 0
    anchor_top = 0
    anchor_right = 1
    anchor_bottom = 1
    
    # Set margins if needed
    margin_left = 20
    margin_top = 20
    margin_right = -20
    margin_bottom = -20
```

SafeArea pattern for mobile support:

```gdscript
extends Control

func _ready():
    # Get safe area insets
    var safe_area = OS.get_window_safe_area()
    
    # Adjust margins
    margin_left = safe_area.position.x
    margin_top = safe_area.position.y
    margin_right = -safe_area.position.x
    margin_bottom = -safe_area.position.y
```

### 3. Separate UI Logic

Connect to game events via signals:

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

## Slider Configuration (CRITICAL!)

When creating sliders for volume or other continuous controls:

### 1. Always Set Step Property

```gdscript
# In code
slider.step = 0.01  # Allows fine-grained control

# In scene file:
[node name="HSlider" type="HSlider"]
max_value = 1.0
step = 0.01
value = 1.0
```

### 2. Configure Sliders Programmatically as Failsafe

```gdscript
func _ready():
    for slider in [master_slider, melody_slider, bass_slider]:
        slider.min_value = 0.0
        slider.max_value = 1.0
        slider.step = 0.01  # CRITICAL - prevents binary behavior
```

### 3. Use Appropriate Value Mapping

For audio controls:

```gdscript
# Convert linear slider value to dB
func _on_volume_slider_changed(value: float):
    var db_value = linear_to_db(value)
    AudioServer.set_bus_volume_db(bus_index, db_value)

# Store linear values in settings
func save_volume_settings():
    settings.master_volume = master_slider.value  # Linear 0-1
    settings.save()
```

## Beat Racer UI Components

### Score Display

```gdscript
extends Label

var displayed_score: int = 0
var target_score: int = 0
var score_change_speed: float = 100.0

func _ready():
    Events.score_changed.connect(_on_score_changed)

func _process(delta):
    if displayed_score != target_score:
        var diff = target_score - displayed_score
        var change = sign(diff) * min(abs(diff), score_change_speed * delta)
        displayed_score += int(change)
        text = str(displayed_score)

func _on_score_changed(new_score: int):
    target_score = new_score
```

### Combo Meter

```gdscript
extends Control

@onready var combo_label: Label = $ComboLabel
@onready var combo_bar: ProgressBar = $ComboBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_combo: int = 0

func _ready():
    Events.combo_changed.connect(_on_combo_changed)
    Events.combo_lost.connect(_on_combo_lost)

func _on_combo_changed(combo: int):
    current_combo = combo
    combo_label.text = "x%d" % combo
    combo_bar.value = combo
    
    # Play animation for milestones
    if combo % 10 == 0 and combo > 0:
        animation_player.play("milestone")

func _on_combo_lost():
    current_combo = 0
    combo_label.text = ""
    combo_bar.value = 0
    animation_player.play("combo_lost")
```

## Responsive UI Patterns

### Adaptive Layout

```gdscript
extends Control

func _ready():
    get_viewport().size_changed.connect(_on_viewport_size_changed)
    _adapt_to_screen_size()

func _on_viewport_size_changed():
    _adapt_to_screen_size()

func _adapt_to_screen_size():
    var viewport_size = get_viewport().size
    
    if viewport_size.x < 1280:  # Small screens
        $TopBar.custom_minimum_size.y = 60
        $BottomBar.visible = false
    else:  # Large screens
        $TopBar.custom_minimum_size.y = 80
        $BottomBar.visible = true
```

### Touch-Friendly UI

```gdscript
extends Control

const MIN_TOUCH_SIZE = 44  # Minimum touch target size in pixels

func _ready():
    _ensure_touch_targets()

func _ensure_touch_targets():
    for button in get_tree().get_nodes_in_group("ui_buttons"):
        button.custom_minimum_size = Vector2(MIN_TOUCH_SIZE, MIN_TOUCH_SIZE)
        
        # Add touch margin
        var margin = 10
        button.margin_left -= margin
        button.margin_top -= margin
        button.margin_right += margin
        button.margin_bottom += margin
```

## Menu System

### Menu Navigation

```gdscript
extends Control

var menu_stack: Array[Control] = []

func push_menu(menu: Control):
    if menu_stack.size() > 0:
        menu_stack.back().visible = false
    
    menu_stack.append(menu)
    menu.visible = true

func pop_menu():
    if menu_stack.size() > 0:
        var current_menu = menu_stack.pop_back()
        current_menu.visible = false
        
        if menu_stack.size() > 0:
            menu_stack.back().visible = true

func _input(event):
    if event.is_action_pressed("ui_cancel"):
        if menu_stack.size() > 1:  # Don't close the main menu
            pop_menu()
```

### Settings Menu

```gdscript
extends Control

@onready var master_slider: HSlider = $VolumeSettings/MasterSlider
@onready var sfx_slider: HSlider = $VolumeSettings/SFXSlider
@onready var music_slider: HSlider = $VolumeSettings/MusicSlider

func _ready():
    # Load saved settings
    var settings = GameSettings.load_settings()
    
    # Configure sliders (CRITICAL!)
    for slider in [master_slider, sfx_slider, music_slider]:
        slider.min_value = 0.0
        slider.max_value = 1.0
        slider.step = 0.01  # Prevents binary behavior
    
    # Set initial values
    master_slider.value = settings.master_volume
    sfx_slider.value = settings.sfx_volume
    music_slider.value = settings.music_volume
    
    # Connect signals
    master_slider.value_changed.connect(_on_master_volume_changed)
    sfx_slider.value_changed.connect(_on_sfx_volume_changed)
    music_slider.value_changed.connect(_on_music_volume_changed)

func _on_master_volume_changed(value: float):
    AudioManager.set_bus_volume("Master", value)
    GameSettings.settings.master_volume = value
    GameSettings.save_settings()
```

## UI Animation

### Tween-based Animations

```gdscript
func show_popup(popup: Control):
    popup.scale = Vector2(0.8, 0.8)
    popup.modulate.a = 0.0
    popup.visible = true
    
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(popup, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
    tween.tween_property(popup, "modulate:a", 1.0, 0.2)

func hide_popup(popup: Control):
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(popup, "scale", Vector2(0.8, 0.8), 0.2)
    tween.tween_property(popup, "modulate:a", 0.0, 0.2)
    tween.tween_callback(func(): popup.visible = false)
```

## Best Practices

1. **Test with Different Resolutions**: Ensure UI works on various screen sizes
2. **Use Consistent Styling**: Apply themes for unified appearance
3. **Provide Visual Feedback**: Animate UI responses to user actions
4. **Keep UI Responsive**: Don't block UI with heavy operations
5. **Support Keyboard Navigation**: Allow menu navigation without mouse
6. **Optimize Draw Calls**: Group UI elements to reduce rendering overhead
7. **Always Set Slider Steps**: Prevent binary behavior in continuous controls