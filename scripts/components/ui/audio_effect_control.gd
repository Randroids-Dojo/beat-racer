extends VBoxContainer

signal parameter_changed(bus_name: String, effect_idx: int, parameter_name: String, value: float)

const EFFECT_PARAMETERS = {
	"AudioEffectReverb": {
		"room_size": {"label": "Room Size", "min": 0.0, "max": 1.0, "default": 0.8},
		"damping": {"label": "Damping", "min": 0.0, "max": 1.0, "default": 0.5},
		"wet": {"label": "Wet", "min": 0.0, "max": 1.0, "default": 0.33},
		"dry": {"label": "Dry", "min": 0.0, "max": 1.0, "default": 0.66},
		"spread": {"label": "Spread", "min": 0.0, "max": 1.0, "default": 1.0}
	},
	"AudioEffectDelay": {
		"dry": {"label": "Dry", "min": 0.0, "max": 1.0, "default": 0.8},  # NOT 'mix'!
		"tap1_delay_ms": {"label": "Tap1 Delay (ms)", "min": 0.0, "max": 2000.0, "default": 250.0},
		"tap1_level_db": {"label": "Tap1 Level (dB)", "min": -60.0, "max": 0.0, "default": -6.0},
		"tap1_pan": {"label": "Tap1 Pan", "min": -1.0, "max": 1.0, "default": 0.2},
		"feedback_delay_ms": {"label": "Feedback Delay (ms)", "min": 0.0, "max": 2000.0, "default": 250.0},
		"feedback_level_db": {"label": "Feedback Level (dB)", "min": -60.0, "max": 0.0, "default": -12.0}
	},
	"AudioEffectCompressor": {
		"threshold": {"label": "Threshold (dB)", "min": -60.0, "max": 0.0, "default": -20.0},
		"ratio": {"label": "Ratio", "min": 1.0, "max": 32.0, "default": 4.0},
		"attack_us": {"label": "Attack (μs)", "min": 20.0, "max": 2000.0, "default": 20.0},
		"release_ms": {"label": "Release (ms)", "min": 20.0, "max": 2000.0, "default": 250.0},
		"gain": {"label": "Gain (dB)", "min": -20.0, "max": 20.0, "default": 0.0}
	},
	"AudioEffectChorus": {
		"dry": {"label": "Dry", "min": 0.0, "max": 1.0, "default": 0.85},
		"wet": {"label": "Wet", "min": 0.0, "max": 1.0, "default": 0.15},
		"voice_count": {"label": "Voices", "min": 1, "max": 4, "default": 2, "step": 1}
	},
	"AudioEffectEQ": {
		"band_db/32_hz": {"label": "32 Hz", "min": -60.0, "max": 24.0, "default": 0.0},
		"band_db/100_hz": {"label": "100 Hz", "min": -60.0, "max": 24.0, "default": 0.0},
		"band_db/320_hz": {"label": "320 Hz", "min": -60.0, "max": 24.0, "default": 0.0},
		"band_db/1000_hz": {"label": "1 kHz", "min": -60.0, "max": 24.0, "default": 0.0},
		"band_db/3200_hz": {"label": "3.2 kHz", "min": -60.0, "max": 24.0, "default": 0.0},
		"band_db/10000_hz": {"label": "10 kHz", "min": -60.0, "max": 24.0, "default": 0.0}
	}
}

var _bus_name: String
var _effect_idx: int
var _effect: AudioEffect
var _parameter_controls: Dictionary = {}

func setup(bus_name: String, effect_idx: int):
	_bus_name = bus_name
	_effect_idx = effect_idx
	_effect = AudioManager.get_bus_effect(bus_name, effect_idx)
	
	if not _effect:
		push_error("Effect not found: bus=%s, idx=%d" % [bus_name, effect_idx])
		return
	
	_clear_controls()
	_create_controls()
	_update_values()

func _clear_controls():
	for child in get_children():
		child.queue_free()
	_parameter_controls.clear()

func _create_controls():
	var effect_class = _effect.get_class()
	
	# Title
	var title = Label.new()
	title.text = effect_class.replace("AudioEffect", "")
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)
	
	# Separator
	add_child(HSeparator.new())
	
	# Get parameters for this effect type
	if not effect_class in EFFECT_PARAMETERS:
		var no_params_label = Label.new()
		no_params_label.text = "No parameters available"
		add_child(no_params_label)
		return
	
	var parameters = EFFECT_PARAMETERS[effect_class]
	
	# Create control for each parameter
	for param_name in parameters:
		var param_config = parameters[param_name]
		var control_container = _create_parameter_control(param_name, param_config)
		add_child(control_container)
		_parameter_controls[param_name] = control_container

func _create_parameter_control(param_name: String, config: Dictionary) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Label
	var label = Label.new()
	label.text = config.label
	label.custom_minimum_size.x = 120
	container.add_child(label)
	
	# Slider
	var slider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = config.min
	slider.max_value = config.max
	slider.value = config.default
	slider.step = config.get("step", 0.01)  # CRITICAL for smooth control
	slider.custom_minimum_size.x = 150
	slider.value_changed.connect(_on_parameter_changed.bind(param_name))
	container.add_child(slider)
	
	# Value label
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = _format_value(config.default, param_name)
	value_label.custom_minimum_size.x = 80
	container.add_child(value_label)
	
	return container

func _update_values():
	if not _effect:
		return
	
	var effect_class = _effect.get_class()
	if not effect_class in EFFECT_PARAMETERS:
		return
	
	var parameters = EFFECT_PARAMETERS[effect_class]
	
	for param_name in _parameter_controls:
		var container = _parameter_controls[param_name]
		var slider = container.get_node("Slider")
		var value_label = container.get_node("ValueLabel")
		
		# Get current value from effect
		var value = _get_effect_parameter(param_name)
		if value != null:
			slider.set_value_no_signal(value)
			value_label.text = _format_value(value, param_name)

func _get_effect_parameter(param_name: String):
	if not _effect:
		return null
	
	# Handle special cases
	if param_name.begins_with("band_db/"):
		# EQ band parameter
		if _effect is AudioEffectEQ:
			var band_idx = _get_eq_band_index(param_name)
			if band_idx >= 0:
				return _effect.get_band_gain_db(band_idx)
	elif param_name == "voice_count" and _effect is AudioEffectChorus:
		return _effect.voice_count
	else:
		# Standard property
		if param_name in _effect:
			return _effect.get(param_name)
	
	return null

func _set_effect_parameter(param_name: String, value: float):
	if not _effect:
		return
	
	# Handle special cases
	if param_name.begins_with("band_db/"):
		# EQ band parameter
		if _effect is AudioEffectEQ:
			var band_idx = _get_eq_band_index(param_name)
			if band_idx >= 0:
				_effect.set_band_gain_db(band_idx, value)
	elif param_name == "voice_count" and _effect is AudioEffectChorus:
		_effect.voice_count = int(value)
	else:
		# Standard property
		if param_name in _effect:
			_effect.set(param_name, value)

func _get_eq_band_index(param_name: String) -> int:
	# Map frequency names to band indices for AudioEffectEQ
	var freq_map = {
		"band_db/32_hz": 0,
		"band_db/100_hz": 1,
		"band_db/320_hz": 2,
		"band_db/1000_hz": 3,
		"band_db/3200_hz": 4,
		"band_db/10000_hz": 5
	}
	return freq_map.get(param_name, -1)

func _format_value(value: float, param_name: String) -> String:
	if param_name.ends_with("_db"):
		return "%.1f dB" % value
	elif param_name.ends_with("_ms"):
		return "%.0f ms" % value
	elif param_name.ends_with("_us"):
		return "%.0f μs" % value
	elif param_name == "ratio":
		return "%.1f:1" % value
	elif param_name == "voice_count":
		return "%d" % int(value)
	elif param_name == "tap1_pan":
		if value < -0.1:
			return "L%.0f" % (abs(value) * 100)
		elif value > 0.1:
			return "R%.0f" % (value * 100)
		else:
			return "C"
	else:
		return "%.2f" % value

func _on_parameter_changed(value: float, param_name: String):
	_set_effect_parameter(param_name, value)
	
	# Update value label
	if param_name in _parameter_controls:
		var container = _parameter_controls[param_name]
		var value_label = container.get_node("ValueLabel")
		value_label.text = _format_value(value, param_name)
	
	parameter_changed.emit(_bus_name, _effect_idx, param_name, value)