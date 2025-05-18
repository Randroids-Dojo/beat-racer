extends Control

# Reference to verification helpers and debugger
const VerificationHelpers = preload("res://scripts/components/verification_helpers.gd")
const AudioDebugger = preload("res://scripts/components/audio_debugger.gd")

@onready var effect_option := $VBoxContainer/EffectTypeContainer/OptionButton
@onready var verify_button := $VBoxContainer/EffectTypeContainer/VerifyButton
@onready var output_text := $VBoxContainer/ScrollContainer/OutputText

var audio_debugger: AudioDebugger

func _ready():
	# Initialize audio debugger
	audio_debugger = AudioDebugger.new()
	add_child(audio_debugger)
	
	# Populate effect types
	effect_option.add_item("Reverb")
	effect_option.add_item("Delay")
	effect_option.add_item("Chorus")
	effect_option.add_item("Compressor")
	effect_option.add_item("EQ")
	effect_option.add_item("Filter")
	effect_option.add_item("Distortion")
	
	# Connect button
	verify_button.pressed.connect(_on_verify_button_pressed)

func _on_verify_button_pressed():
	var selected_idx = effect_option.selected
	var effect_name = effect_option.get_item_text(selected_idx).to_lower()
	
	output_text.text = "[b]Verifying %s effect properties...[/b]\n\n" % effect_name
	
	# Create the effect
	var effect = audio_debugger.test_effect(effect_name)
	if effect == null:
		output_text.text += "[color=red]Failed to create effect[/color]"
		return
	
	# List all properties
	output_text.text += "[b]Properties for %s:[/b]\n" % effect.get_class()
	for prop in effect.get_property_list():
		if not prop.name.begins_with("_") and prop.name != "resource_name" and prop.name != "resource_path":
			var value = effect.get(prop.name)
			var type_name = _get_type_name(prop.type)
			output_text.text += "• [color=cyan]%s[/color]: %s (default: %s)\n" % [prop.name, type_name, str(value)]
	
	# Test specific properties
	output_text.text += "\n[b]Common property tests:[/b]\n"
	_test_property(effect, "mix")
	_test_property(effect, "wet")
	_test_property(effect, "dry")
	_test_property(effect, "feedback")
	_test_property(effect, "delay_ms")
	_test_property(effect, "feedback_delay_ms")
	_test_property(effect, "room_size")
	_test_property(effect, "threshold")

func _test_property(effect, property_name: String):
	if VerificationHelpers.property_exists(effect, property_name):
		output_text.text += "[color=green]✓[/color] Property '%s' exists\n" % property_name
	else:
		output_text.text += "[color=red]✗[/color] Property '%s' does not exist\n" % property_name

func _get_type_name(type: int) -> String:
	match type:
		TYPE_NIL: return "nil"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR3: return "Vector3"
		TYPE_COLOR: return "Color"
		TYPE_OBJECT: return "Object"
		TYPE_ARRAY: return "Array"
		TYPE_DICTIONARY: return "Dictionary"
		_: return "Unknown"