extends Control
## Extremely simple button test

@onready var test_button: Button = $TestButton
@onready var counter_label: Label = $CounterLabel

var click_count = 0

func _ready():
	print("Simple button test ready")
	if test_button:
		test_button.pressed.connect(_on_button_pressed)
		print("Button connected successfully")
	else:
		print("ERROR: Button not found")

func _on_button_pressed():
	click_count += 1
	print("Button clicked! Count: ", click_count)
	if counter_label:
		counter_label.text = "Clicks: %d" % click_count
	test_button.text = "Clicked %d times" % click_count