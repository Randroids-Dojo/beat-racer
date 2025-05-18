# context7_example.gd
# Example of how to use Context7 for Godot documentation lookup

extends Node

# This is an example of how you should use Context7 to verify Godot class properties
# before implementing audio systems or any other Godot features

func _ready():
	print("Context7 Example - How to lookup Godot documentation")
	
	# Step 1: First, you would call mcp__context7-mcp__resolve-library-id
	# with libraryName: "godot" to get the proper library ID
	
	# Step 2: Then, use mcp__context7-mcp__get-library-docs with:
	# - context7CompatibleLibraryID: the ID from step 1
	# - topic: the specific class name (e.g., "AudioEffectDelay")
	
	print("Example lookup process:")
	print("1. Get Godot library ID from Context7")
	print("2. Look up AudioEffectDelay documentation")
	print("3. Verify property names before using them")
	print("4. Implement with correct properties")
	
	# Example of what you'd learn from Context7:
	# AudioEffectDelay has these properties:
	# - dry: float (0.0 to 1.0)
	# - tap1_active: bool
	# - tap1_delay_ms: float
	# - tap1_level_db: float
	# - tap1_pan: float
	# - tap2_active: bool
	# - tap2_delay_ms: float
	# - tap2_level_db: float
	# - tap2_pan: float
	# - feedback_active: bool
	# - feedback_delay_ms: float
	# - feedback_level_db: float
	# - feedback_lowpass: float
	# NOTE: There is NO "mix" property!
	
	demonstrate_correct_implementation()

func demonstrate_correct_implementation():
	# This is how you'd implement AudioEffectDelay after checking Context7
	var delay = AudioEffectDelay.new()
	
	# Use the correct properties discovered via Context7
	delay.tap1_active = true
	delay.tap1_delay_ms = 250.0
	delay.tap1_level_db = -6.0
	delay.feedback_active = true
	delay.feedback_delay_ms = 250.0
	delay.feedback_level_db = -12.0
	
	# NOT: delay.mix = 0.2  # This property doesn't exist!
	
	print("AudioEffectDelay configured correctly using Context7-verified properties")