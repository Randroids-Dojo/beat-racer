extends Panel

signal volume_changed(bus_name: String, volume_db: float)
signal mute_changed(bus_name: String, muted: bool)
signal solo_changed(bus_name: String, soloed: bool)
signal effect_toggled(bus_name: String, effect_idx: int, enabled: bool)
signal effect_parameter_changed(bus_name: String, effect_idx: int, parameter_name: String, value: float)

# Bus configuration
const BUS_CONFIGS = {
	"Master": {
		"label": "Master",
		"color": Color.WHITE,
		"default_volume": 0.0,
		"has_effects": false
	},
	"Melody": {
		"label": "Melody",
		"color": Color.CYAN,
		"default_volume": -6.0,
		"has_effects": true,
		"effects": ["Reverb", "Delay"]
	},
	"Bass": {
		"label": "Bass",
		"color": Color.ORANGE,
		"default_volume": -6.0,
		"has_effects": true,
		"effects": ["Compressor", "Chorus"]
	},
	"Percussion": {
		"label": "Percussion",
		"color": Color.GREEN,
		"default_volume": -6.0,
		"has_effects": true,
		"effects": ["Compressor", "EQ"]
	},
	"SFX": {
		"label": "SFX",
		"color": Color.YELLOW,
		"default_volume": -6.0,
		"has_effects": true,
		"effects": ["Compressor"]
	}
}

# UI components storage
var _bus_controls: Dictionary = {}
var _effect_controls: Dictionary = {}
var _current_effect_panel: Control = null

const AudioEffectControl = preload("res://scripts/components/ui/audio_effect_control.gd")
const AudioPresetManager = preload("res://scripts/components/ui/audio_preset_manager.gd")

func _ready():
	_setup_ui()
	_update_from_audio_manager()

func _setup_ui():
	# Set panel properties
	custom_minimum_size = Vector2(1000, 600)
	
	# Create main container
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)
	
	# Add title
	var title = Label.new()
	title.text = "Audio Mixer"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_constant_override("outline_size", 2)
	main_vbox.add_child(title)
	
	# Add separator
	var separator = HSeparator.new()
	main_vbox.add_child(separator)
	
	# Create split container for buses and effects
	var split_container = HSplitContainer.new()
	split_container.name = "SplitContainer"
	split_container.split_offset = 600
	main_vbox.add_child(split_container)
	
	# Create bus controls container
	var bus_container = HBoxContainer.new()
	bus_container.name = "BusContainer"
	bus_container.add_theme_constant_override("separation", 20)
	split_container.add_child(bus_container)
	
	# Create right panel with tabs
	var right_panel = TabContainer.new()
	right_panel.name = "RightPanel"
	right_panel.custom_minimum_size = Vector2(350, 0)
	split_container.add_child(right_panel)
	
	# Effect parameters tab
	var effect_panel = Panel.new()
	effect_panel.name = "Effects"
	right_panel.add_child(effect_panel)
	
	var effect_vbox = VBoxContainer.new()
	effect_vbox.name = "EffectVBox"
	effect_panel.add_child(effect_vbox)
	
	var effect_placeholder = Label.new()
	effect_placeholder.name = "EffectPlaceholder"
	effect_placeholder.text = "Select an effect to edit"
	effect_placeholder.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	effect_vbox.add_child(effect_placeholder)
	
	# Presets tab
	var preset_panel = Panel.new()
	preset_panel.name = "Presets"
	right_panel.add_child(preset_panel)
	
	var preset_manager = AudioPresetManager.new()
	preset_manager.name = "PresetManager"
	preset_manager.preset_loaded.connect(_on_preset_loaded)
	preset_manager.preset_saved.connect(_on_preset_saved)
	preset_panel.add_child(preset_manager)
	
	# Create controls for each bus
	for bus_name in BUS_CONFIGS:
		var bus_config = BUS_CONFIGS[bus_name]
		var bus_control = _create_bus_control(bus_name, bus_config)
		bus_container.add_child(bus_control)
		_bus_controls[bus_name] = bus_control

func _create_bus_control(bus_name: String, config: Dictionary) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.name = bus_name + "Control"
	container.custom_minimum_size = Vector2(120, 300)
	container.add_theme_constant_override("separation", 5)
	
	# Bus label with color
	var label = Label.new()
	label.text = config.label
	label.add_theme_color_override("font_color", config.color)
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	# Volume display
	var volume_label = Label.new()
	volume_label.name = "VolumeLabel"
	volume_label.text = "0.0 dB"
	volume_label.add_theme_font_size_override("font_size", 12)
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(volume_label)
	
	# Volume slider
	var volume_slider = VSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.min_value = -60.0
	volume_slider.max_value = 6.0
	volume_slider.value = config.default_volume
	volume_slider.step = 0.01  # CRITICAL for smooth control
	volume_slider.custom_minimum_size = Vector2(40, 150)
	volume_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volume_slider.value_changed.connect(_on_volume_changed.bind(bus_name))
	container.add_child(volume_slider)
	
	# Mute/Solo buttons container
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 5)
	button_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.add_child(button_container)
	
	# Mute button
	var mute_button = Button.new()
	mute_button.name = "MuteButton"
	mute_button.text = "M"
	mute_button.toggle_mode = true
	mute_button.custom_minimum_size = Vector2(30, 30)
	mute_button.tooltip_text = "Mute"
	mute_button.toggled.connect(_on_mute_toggled.bind(bus_name))
	button_container.add_child(mute_button)
	
	# Solo button
	var solo_button = Button.new()
	solo_button.name = "SoloButton"
	solo_button.text = "S"
	solo_button.toggle_mode = true
	solo_button.custom_minimum_size = Vector2(30, 30)
	solo_button.tooltip_text = "Solo"
	solo_button.toggled.connect(_on_solo_toggled.bind(bus_name))
	button_container.add_child(solo_button)
	
	# Add effect controls if bus has effects
	if config.has("effects") and config.effects.size() > 0:
		var separator = HSeparator.new()
		container.add_child(separator)
		
		var effects_label = Label.new()
		effects_label.text = "Effects"
		effects_label.add_theme_font_size_override("font_size", 12)
		effects_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(effects_label)
		
		var effects_container = VBoxContainer.new()
		effects_container.name = "EffectsContainer"
		container.add_child(effects_container)
		
		for i in range(config.effects.size()):
			var effect_name = config.effects[i]
			
			var effect_row = HBoxContainer.new()
			effects_container.add_child(effect_row)
			
			# Toggle button
			var effect_button = CheckButton.new()
			effect_button.name = "Effect" + str(i) + "Button"
			effect_button.text = effect_name
			effect_button.button_pressed = true
			effect_button.toggled.connect(_on_effect_toggled.bind(bus_name, i))
			effect_row.add_child(effect_button)
			
			# Edit button
			var edit_button = Button.new()
			edit_button.name = "Effect" + str(i) + "EditButton"
			edit_button.text = "⚙"
			edit_button.tooltip_text = "Edit " + effect_name + " parameters"
			edit_button.custom_minimum_size = Vector2(25, 25)
			edit_button.pressed.connect(_on_effect_edit_pressed.bind(bus_name, i))
			effect_row.add_child(edit_button)
	
	return container

func _update_from_audio_manager():
	if not AudioManager:
		return
	
	for bus_name in _bus_controls:
		var control = _bus_controls[bus_name]
		
		# Update volume
		var volume_db = AudioManager.get_bus_volume_db(bus_name)
		var volume_slider = control.get_node("VolumeSlider")
		volume_slider.set_value_no_signal(volume_db)
		_update_volume_label(control, volume_db)
		
		# Update mute/solo
		var mute_button = control.get_node("MuteButton")
		var solo_button = control.get_node("SoloButton")
		mute_button.set_pressed_no_signal(AudioManager.is_bus_muted(bus_name))
		solo_button.set_pressed_no_signal(AudioManager.is_bus_soloed(bus_name))
		
		# Update effect states
		var effects_container = control.get_node_or_null("EffectsContainer")
		if effects_container:
			for i in range(effects_container.get_child_count()):
				var effect_button = effects_container.get_child(i)
				effect_button.set_pressed_no_signal(AudioManager.is_bus_effect_enabled(bus_name, i))

func _update_volume_label(control: Control, volume_db: float):
	var volume_label = control.get_node("VolumeLabel")
	volume_label.text = "%.1f dB" % volume_db

func _on_volume_changed(value: float, bus_name: String):
	AudioManager.set_bus_volume_db(bus_name, value)
	var control = _bus_controls[bus_name]
	_update_volume_label(control, value)
	volume_changed.emit(bus_name, value)

func _on_mute_toggled(pressed: bool, bus_name: String):
	AudioManager.set_bus_mute(bus_name, pressed)
	mute_changed.emit(bus_name, pressed)

func _on_solo_toggled(pressed: bool, bus_name: String):
	AudioManager.set_bus_solo(bus_name, pressed)
	solo_changed.emit(bus_name, pressed)

func _on_effect_toggled(pressed: bool, bus_name: String, effect_idx: int):
	AudioManager.set_bus_effect_enabled(bus_name, effect_idx, pressed)
	effect_toggled.emit(bus_name, effect_idx, pressed)

func _on_effect_edit_pressed(bus_name: String, effect_idx: int):
	_show_effect_controls(bus_name, effect_idx)

func _show_effect_controls(bus_name: String, effect_idx: int):
	var effect_panel = get_node("MainVBox/SplitContainer/RightPanel/Effects/EffectVBox")
	
	# Remove current effect control if exists
	if _current_effect_panel:
		_current_effect_panel.queue_free()
		_current_effect_panel = null
	
	# Hide placeholder
	var placeholder = effect_panel.get_node("EffectPlaceholder")
	placeholder.visible = false
	
	# Create new effect control
	var effect_control = AudioEffectControl.new()
	effect_control.name = "CurrentEffectControl"
	effect_control.parameter_changed.connect(_on_effect_parameter_changed)
	effect_panel.add_child(effect_control)
	
	# Setup the control with the selected effect
	effect_control.setup(bus_name, effect_idx)
	_current_effect_panel = effect_control

func _on_effect_parameter_changed(bus_name: String, effect_idx: int, parameter_name: String, value: float):
	effect_parameter_changed.emit(bus_name, effect_idx, parameter_name, value)

func _on_preset_loaded(preset_name: String):
	# Update all UI controls after preset is loaded
	_update_from_audio_manager()
	print("Loaded preset: " + preset_name)

func _on_preset_saved(preset_name: String):
	print("Saved preset: " + preset_name)

# Public methods
func get_bus_volume(bus_name: String) -> float:
	if bus_name in _bus_controls:
		var control = _bus_controls[bus_name]
		var slider = control.get_node("VolumeSlider")
		return slider.value
	return -80.0

func set_bus_volume(bus_name: String, volume_db: float):
	if bus_name in _bus_controls:
		var control = _bus_controls[bus_name]
		var slider = control.get_node("VolumeSlider")
		slider.value = volume_db

func is_bus_muted(bus_name: String) -> bool:
	if bus_name in _bus_controls:
		var control = _bus_controls[bus_name]
		var mute_button = control.get_node("MuteButton")
		return mute_button.button_pressed
	return false

func is_bus_soloed(bus_name: String) -> bool:
	if bus_name in _bus_controls:
		var control = _bus_controls[bus_name]
		var solo_button = control.get_node("SoloButton")
		return solo_button.button_pressed
	return false