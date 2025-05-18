# verification_helpers.gd

# Use this to check if a property exists on an object
static func property_exists(obj, property_name: String) -> bool:
	if obj == null:
		print("Object is null")
		return false
	
	var properties = []
	for prop in obj.get_property_list():
		properties.append(prop.name)
	
	var exists = property_name in properties
	if not exists:
		print("Property '%s' does not exist on %s" % [property_name, obj.get_class()])
		print("Available properties: %s" % str(properties))
	
	return exists

# Use this to list all available properties for an object
static func list_properties(obj) -> Array:
	if obj == null:
		print("Object is null")
		return []
	
	var properties = []
	print("Properties for %s:" % obj.get_class())
	for prop in obj.get_property_list():
		if not prop.name.begins_with("_"):  # Skip internal properties
			properties.append(prop.name)
			print("- %s: %s" % [prop.name, TYPE_STRING])
	
	return properties