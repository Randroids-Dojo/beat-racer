extends PanelContainer
class_name VehicleSelector

# Vehicle Selector
# UI component for selecting different vehicle types

signal vehicle_selected(vehicle_type: VehicleType)
signal color_changed(color: Color)

# Vehicle types
enum VehicleType { STANDARD, DRIFT, SPEED, HEAVY }

# Vehicle data
class VehicleData:
	var name: String
	var description: String
	var base_color: Color
	var speed_modifier: float
	var handling_modifier: float
	
	func _init(n: String, d: String, c: Color, s: float = 1.0, h: float = 1.0):
		name = n
		description = d
		base_color = c
		speed_modifier = s
		handling_modifier = h

# Visual settings
@export var selector_size: Vector2 = Vector2(250, 150)
@export var show_vehicle_preview: bool = true
@export var allow_color_customization: bool = true

# UI References
var vehicle_name_label: Label
var vehicle_desc_label: Label
var prev_button: Button
var next_button: Button
var vehicle_preview: Panel
var color_picker_button: ColorPickerButton
var stats_container: VBoxContainer

# State
var current_vehicle_index: int = 0
var current_color: Color = Color.WHITE
var vehicle_data: Array[VehicleData] = []


func _ready():
	custom_minimum_size = selector_size
	
	# Initialize vehicle data
	_init_vehicle_data()
	
	# Create UI structure
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Select Vehicle"
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	# Vehicle navigation
	var nav_container = HBoxContainer.new()
	nav_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(nav_container)
	
	prev_button = Button.new()
	prev_button.text = "<"
	prev_button.custom_minimum_size = Vector2(30, 30)
	prev_button.pressed.connect(_on_prev_pressed)
	nav_container.add_child(prev_button)
	
	# Vehicle info container
	var info_container = VBoxContainer.new()
	info_container.custom_minimum_size.x = 150
	info_container.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_container.add_child(info_container)
	
	vehicle_name_label = Label.new()
	vehicle_name_label.add_theme_font_size_override("font_size", 16)
	vehicle_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(vehicle_name_label)
	
	vehicle_desc_label = Label.new()
	vehicle_desc_label.add_theme_font_size_override("font_size", 10)
	vehicle_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vehicle_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vehicle_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(vehicle_desc_label)
	
	next_button = Button.new()
	next_button.text = ">"
	next_button.custom_minimum_size = Vector2(30, 30)
	next_button.pressed.connect(_on_next_pressed)
	nav_container.add_child(next_button)
	
	# Vehicle preview
	if show_vehicle_preview:
		vehicle_preview = Panel.new()
		vehicle_preview.custom_minimum_size = Vector2(60, 40)
		vehicle_preview.set_script(preload("res://scripts/components/ui/vehicle_preview.gd") if ResourceLoader.exists("res://scripts/components/ui/vehicle_preview.gd") else null)
		vbox.add_child(vehicle_preview)
	
	# Stats display
	stats_container = VBoxContainer.new()
	vbox.add_child(stats_container)
	_create_stats_display()
	
	# Color customization
	if allow_color_customization:
		var color_container = HBoxContainer.new()
		color_container.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(color_container)
		
		var color_label = Label.new()
		color_label.text = "Color: "
		color_container.add_child(color_label)
		
		color_picker_button = ColorPickerButton.new()
		color_picker_button.custom_minimum_size = Vector2(50, 25)
		color_picker_button.color = current_color
		color_picker_button.color_changed.connect(_on_color_changed)
		color_container.add_child(color_picker_button)
	
	# Set initial theme
	_update_theme()
	
	# Select first vehicle
	_select_vehicle(0)


func _init_vehicle_data():
	"""Initialize available vehicles"""
	vehicle_data.append(VehicleData.new(
		"Standard",
		"Balanced performance",
		Color(0.7, 0.7, 0.7),
		1.0,
		1.0
	))
	
	vehicle_data.append(VehicleData.new(
		"Drift",
		"Better cornering",
		Color(0.8, 0.3, 0.3),
		0.9,
		1.2
	))
	
	vehicle_data.append(VehicleData.new(
		"Speed",
		"Higher top speed",
		Color(0.3, 0.8, 0.3),
		1.3,
		0.8
	))
	
	vehicle_data.append(VehicleData.new(
		"Heavy",
		"More stable",
		Color(0.3, 0.3, 0.8),
		0.8,
		0.9
	))


func _create_stats_display():
	"""Create vehicle stats bars"""
	# Speed stat
	var speed_container = HBoxContainer.new()
	stats_container.add_child(speed_container)
	
	var speed_label = Label.new()
	speed_label.text = "Speed:"
	speed_label.custom_minimum_size.x = 60
	speed_label.add_theme_font_size_override("font_size", 10)
	speed_container.add_child(speed_label)
	
	var speed_bar = ProgressBar.new()
	speed_bar.custom_minimum_size = Vector2(100, 10)
	speed_bar.value = 50
	speed_bar.show_percentage = false
	speed_bar.name = "SpeedBar"
	speed_container.add_child(speed_bar)
	
	# Handling stat
	var handling_container = HBoxContainer.new()
	stats_container.add_child(handling_container)
	
	var handling_label = Label.new()
	handling_label.text = "Handling:"
	handling_label.custom_minimum_size.x = 60
	handling_label.add_theme_font_size_override("font_size", 10)
	handling_container.add_child(handling_label)
	
	var handling_bar = ProgressBar.new()
	handling_bar.custom_minimum_size = Vector2(100, 10)
	handling_bar.value = 50
	handling_bar.show_percentage = false
	handling_bar.name = "HandlingBar"
	handling_container.add_child(handling_bar)


func _on_prev_pressed():
	"""Select previous vehicle"""
	var new_index = current_vehicle_index - 1
	if new_index < 0:
		new_index = vehicle_data.size() - 1
	_select_vehicle(new_index)


func _on_next_pressed():
	"""Select next vehicle"""
	var new_index = current_vehicle_index + 1
	if new_index >= vehicle_data.size():
		new_index = 0
	_select_vehicle(new_index)


func _on_color_changed(color: Color):
	"""Handle color picker change"""
	current_color = color
	_update_preview()
	emit_signal("color_changed", color)


func _select_vehicle(index: int):
	"""Select a vehicle by index"""
	current_vehicle_index = index
	var data = vehicle_data[index]
	
	# Update display
	vehicle_name_label.text = data.name
	vehicle_desc_label.text = data.description
	
	# Update color
	current_color = data.base_color
	if color_picker_button:
		color_picker_button.color = current_color
	
	# Update stats
	_update_stats(data)
	
	# Update preview
	_update_preview()
	
	# Emit signal
	emit_signal("vehicle_selected", index as VehicleType)


func _update_stats(data: VehicleData):
	"""Update stat bars"""
	var speed_bar = stats_container.find_child("SpeedBar") as ProgressBar
	var handling_bar = stats_container.find_child("HandlingBar") as ProgressBar
	
	if speed_bar:
		speed_bar.value = data.speed_modifier * 50 + 25
	
	if handling_bar:
		handling_bar.value = data.handling_modifier * 50 + 25


func _update_preview():
	"""Update vehicle preview"""
	if vehicle_preview and vehicle_preview.has_method("set_vehicle_type"):
		vehicle_preview.set_vehicle_type(current_vehicle_index)
		vehicle_preview.set_vehicle_color(current_color)
	elif vehicle_preview:
		# Simple color update
		var style = StyleBoxFlat.new()
		style.bg_color = current_color
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		vehicle_preview.add_theme_stylebox_override("panel", style)


func _update_theme():
	"""Update panel theme"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)


func get_selected_vehicle() -> VehicleType:
	"""Get currently selected vehicle type"""
	return current_vehicle_index as VehicleType


func get_selected_color() -> Color:
	"""Get currently selected color"""
	return current_color


func get_vehicle_data(type: VehicleType) -> VehicleData:
	"""Get data for a specific vehicle type"""
	if type < vehicle_data.size():
		return vehicle_data[type]
	return null
