# test_single_effect.gd
# Focused test for a single audio effect property
extends SceneTree

func _init():
	print("======= TESTING AUDIO EFFECT PROPERTY =======")
	
	var delay = AudioEffectDelay.new()
	print("Created AudioEffectDelay instance")
	
	# Test property existence
	print("\nTesting property existence:")
	
	# This WILL work
	if "feedback_active" in delay:
		print("✓ Property 'feedback_active' exists")
		delay.feedback_active = true
		print("  Set to: %s" % delay.feedback_active)
	else:
		print("✗ Property 'feedback_active' NOT found")
	
	# This WILL work
	if "tap1_delay_ms" in delay:
		print("✓ Property 'tap1_delay_ms' exists")
		delay.tap1_delay_ms = 250.0
		print("  Set to: %s" % delay.tap1_delay_ms)
	else:
		print("✗ Property 'tap1_delay_ms' NOT found")
	
	# This will NOT work (demonstrating the error)
	if "mix" in delay:
		print("✓ Property 'mix' exists")
		delay.mix = 0.5
		print("  Set to: %s" % delay.mix)
	else:
		print("✗ Property 'mix' NOT found (correctly - it doesn't exist!)")
	
	print("\n======= TEST COMPLETE =======")
	quit()