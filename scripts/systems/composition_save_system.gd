class_name CompositionSaveSystem
extends Node

signal composition_saved(filepath: String, composition: CompositionResource)
signal composition_loaded(filepath: String, composition: CompositionResource)
signal save_error(error_message: String)
signal load_error(error_message: String)

const SAVE_DIRECTORY := "user://compositions/"
const FILE_EXTENSION := ".beatcomp"
const AUTOSAVE_PREFIX := "autosave_"
const MAX_AUTOSAVES := 5

static var instance: CompositionSaveSystem

func _enter_tree() -> void:
	instance = self
	_ensure_save_directory()

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("compositions"):
		dir.make_dir("compositions")

func save_composition(composition: CompositionResource, filename: String = "") -> String:
	if filename.is_empty():
		filename = _generate_filename(composition.composition_name)
	
	if not filename.ends_with(FILE_EXTENSION):
		filename += FILE_EXTENSION
	
	var filepath := SAVE_DIRECTORY + filename
	
	composition.modification_date = Time.get_datetime_string_from_system()
	
	var error := ResourceSaver.save(composition, filepath)
	if error != OK:
		var error_msg := "Failed to save composition: " + error_string(error)
		save_error.emit(error_msg)
		push_error(error_msg)
		return ""
	
	composition_saved.emit(filepath, composition)
	return filepath

func load_composition(filepath: String) -> CompositionResource:
	if not filepath.begins_with("user://") and not filepath.begins_with("res://"):
		filepath = SAVE_DIRECTORY + filepath
	
	if not filepath.ends_with(FILE_EXTENSION):
		filepath += FILE_EXTENSION
	
	if not FileAccess.file_exists(filepath):
		var error_msg := "Composition file not found: " + filepath
		load_error.emit(error_msg)
		push_error(error_msg)
		return null
	
	var composition := load(filepath) as CompositionResource
	if not composition:
		var error_msg := "Failed to load composition from: " + filepath
		load_error.emit(error_msg)
		push_error(error_msg)
		return null
	
	composition_loaded.emit(filepath, composition)
	return composition

func autosave_composition(composition: CompositionResource) -> String:
	_cleanup_old_autosaves()
	
	var timestamp := Time.get_unix_time_from_system()
	var filename := AUTOSAVE_PREFIX + str(timestamp) + "_" + composition.composition_name
	return save_composition(composition, filename)

func list_saved_compositions() -> Array[Dictionary]:
	var compositions: Array[Dictionary] = []
	var dir := DirAccess.open(SAVE_DIRECTORY)
	
	if not dir:
		push_error("Failed to open compositions directory")
		return compositions
	
	dir.list_dir_begin()
	var filename := dir.get_next()
	
	while not filename.is_empty():
		if filename.ends_with(FILE_EXTENSION):
			var info := _get_composition_info(SAVE_DIRECTORY + filename)
			if info:
				compositions.append(info)
		filename = dir.get_next()
	
	dir.list_dir_end()
	
	compositions.sort_custom(func(a, b): return a.modification_date > b.modification_date)
	
	return compositions

func delete_composition(filename: String) -> bool:
	if not filename.begins_with("user://"):
		filename = SAVE_DIRECTORY + filename
	
	if not filename.ends_with(FILE_EXTENSION):
		filename += FILE_EXTENSION
	
	var dir := DirAccess.open("user://")
	if dir:
		return dir.remove(filename) == OK
	
	return false

func composition_exists(filename: String) -> bool:
	if not filename.begins_with("user://"):
		filename = SAVE_DIRECTORY + filename
	
	if not filename.ends_with(FILE_EXTENSION):
		filename += FILE_EXTENSION
	
	return FileAccess.file_exists(filename)

func export_composition(composition: CompositionResource, export_path: String) -> bool:
	if not export_path.ends_with(FILE_EXTENSION):
		export_path += FILE_EXTENSION
	
	var error := ResourceSaver.save(composition, export_path)
	return error == OK

func import_composition(import_path: String) -> CompositionResource:
	if not FileAccess.file_exists(import_path):
		load_error.emit("Import file not found: " + import_path)
		return null
	
	var composition := load(import_path) as CompositionResource
	if composition:
		var filename := _generate_filename(composition.composition_name + "_imported")
		save_composition(composition, filename)
	
	return composition

func _generate_filename(base_name: String) -> String:
	base_name = base_name.strip_edges().replace(" ", "_")
	base_name = base_name.to_lower()
	
	for c in [".", "/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		base_name = base_name.replace(c, "")
	
	if base_name.is_empty():
		base_name = "composition"
	
	var filename := base_name
	var counter := 1
	
	while composition_exists(filename):
		filename = base_name + "_" + str(counter)
		counter += 1
	
	return filename

func _get_composition_info(filepath: String) -> Dictionary:
	var composition := load(filepath) as CompositionResource
	if not composition:
		return {}
	
	var file := FileAccess.open(filepath, FileAccess.READ)
	var file_size := 0
	if file:
		file_size = file.get_length()
		file.close()
	
	return {
		"filename": filepath.get_file(),
		"filepath": filepath,
		"name": composition.composition_name,
		"author": composition.author,
		"duration": composition.get_formatted_duration(),
		"layers": composition.get_layer_count(),
		"bpm": composition.bpm,
		"creation_date": composition.creation_date,
		"modification_date": composition.modification_date,
		"file_size": file_size,
		"is_autosave": filepath.get_file().begins_with(AUTOSAVE_PREFIX)
	}

func _cleanup_old_autosaves() -> void:
	var autosaves := []
	var dir := DirAccess.open(SAVE_DIRECTORY)
	
	if not dir:
		return
	
	dir.list_dir_begin()
	var filename := dir.get_next()
	
	while not filename.is_empty():
		if filename.begins_with(AUTOSAVE_PREFIX) and filename.ends_with(FILE_EXTENSION):
			autosaves.append(filename)
		filename = dir.get_next()
	
	dir.list_dir_end()
	
	if autosaves.size() >= MAX_AUTOSAVES:
		autosaves.sort()
		for i in range(autosaves.size() - MAX_AUTOSAVES + 1):
			dir.remove(autosaves[i])