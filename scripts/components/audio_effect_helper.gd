# audio_effect_helper.gd
# Template for adding audio effects to buses safely

extends Node

# Reference to verification helpers
const VerificationHelpers = preload("res://scripts/components/verification_helpers.gd")

# IMPORTANT: Before using this helper, always check the actual Godot documentation
# using Context7 to verify property names and valid ranges:
# 1. Call mcp__context7-mcp__resolve-library-id with libraryName: "godot"
# 2. Call mcp__context7-mcp__get-library-docs with the library ID and class name
# 3. Verify the correct property names from the documentation

# Template for adding audio effects to buses
# Replace comments with actual properties for each effect type
static func add_effect_to_bus(bus_name: String, effect_type: String) -> void:
	# Get bus index
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		print("Bus '%s' not found" % bus_name)
		return
	
	var effect = null
	
	# Create effect based on type
	match effect_type:
		"reverb":
			effect = AudioEffectReverb.new()
			# Reverb-specific properties
			if VerificationHelpers.property_exists(effect, "room_size"):
				effect.room_size = 0.8
			if VerificationHelpers.property_exists(effect, "damping"):
				effect.damping = 0.5
			if VerificationHelpers.property_exists(effect, "spread"):
				effect.spread = 1.0
			if VerificationHelpers.property_exists(effect, "wet"):
				effect.wet = 0.3
			if VerificationHelpers.property_exists(effect, "dry"):
				effect.dry = 0.7
		
		"delay":
			effect = AudioEffectDelay.new()
			# Delay-specific properties (NOTE: AudioEffectDelay does not have 'mix' property)
			if VerificationHelpers.property_exists(effect, "feedback_active"):
				effect.feedback_active = true
			if VerificationHelpers.property_exists(effect, "feedback_delay_ms"):
				effect.feedback_delay_ms = 250.0
			if VerificationHelpers.property_exists(effect, "feedback_level_db"):
				effect.feedback_level_db = -6.0
			if VerificationHelpers.property_exists(effect, "tap1_active"):
				effect.tap1_active = true
			if VerificationHelpers.property_exists(effect, "tap1_delay_ms"):
				effect.tap1_delay_ms = 250.0
			if VerificationHelpers.property_exists(effect, "tap1_level_db"):
				effect.tap1_level_db = -3.0
			
		"chorus":
			effect = AudioEffectChorus.new()
			# Chorus-specific properties
			if VerificationHelpers.property_exists(effect, "rate"):
				effect.rate = 1.0
			if VerificationHelpers.property_exists(effect, "depth"):
				effect.depth = 0.2
			if VerificationHelpers.property_exists(effect, "wet"):
				effect.wet = 0.5
			if VerificationHelpers.property_exists(effect, "dry"):
				effect.dry = 0.5
			
		"compressor":
			effect = AudioEffectCompressor.new()
			# Compressor-specific properties
			if VerificationHelpers.property_exists(effect, "threshold"):
				effect.threshold = -12.0
			if VerificationHelpers.property_exists(effect, "ratio"):
				effect.ratio = 4.0
			if VerificationHelpers.property_exists(effect, "attack_us"):
				effect.attack_us = 20.0
				
		# Add more effect types as needed
		
		_:
			print("Unknown effect type: %s" % effect_type)
			return
	
	# Add effect to bus
	AudioServer.add_bus_effect(bus_idx, effect)
	print("Added %s effect to bus '%s'" % [effect_type, bus_name])