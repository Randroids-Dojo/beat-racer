# test_chorus_properties.gd
extends SceneTree

func _init():
	print("=== TESTING AUDIOCHORUS PROPERTIES ===")
	
	var chorus = AudioEffectChorus.new()
	
	print("\nAll AudioEffectChorus properties:")
	for prop in chorus.get_property_list():
		if not prop.name.begins_with("_") and prop.name != "script" and prop.name != "RefCounted" and prop.name != "Resource":
			var value = chorus.get(prop.name)
			print("  %s: %s (value: %s)" % [prop.name, _get_type_name(prop.type), str(value)])
	
	print("\n=== TEST COMPLETE ===")
	quit()

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