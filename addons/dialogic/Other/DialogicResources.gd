tool
class_name DialogicResources


const RESOURCES_DIR: String = "res://dialogic" # Readonly, used for static data
const WORKING_DIR: String = "user://dialogic" # Readwrite, used for saves


static func load_json(path: String) -> Dictionary:
	# An easy function to load json files and handle common errors.
	var file:File = File.new()
	if file.open(path, File.READ) != OK:
		file.close()
		return {'error':'file read error'}
	var data_text: String = file.get_as_text()
	file.close()
	var data_parse:JSONParseResult = JSON.parse(data_text)
	if data_parse.error != OK:
		return {'error':'data parse error'}

	var final_data = data_parse.result
	if typeof(final_data) == TYPE_DICTIONARY:
		return final_data
	
	# If everything else fails
	return {'error':'data parse error'}


static func init_dialogic_files() -> void:
	# This functions makes sure that the needed files and folders
	# exists when the plugin is loaded. If they don't, we create 
	# them.
	# WARNING: only call while in the editor
	var directory = Directory.new()
	var paths = get_working_directories()
	var files = get_config_files_paths()
	# Create directories
	for dir in paths:
		if not directory.dir_exists(paths[dir]):
			directory.make_dir_recursive(paths[dir])
	# Create empty files
	for f in files:
		if not directory.file_exists(files[f]):
			create_empty_file(files[f])


static func get_working_directories() -> Dictionary:
	return {
		'RESOURCES_DIR': RESOURCES_DIR,
		'WORKING_DIR': WORKING_DIR,
		'TIMELINE_DIR': RESOURCES_DIR + "/timelines",
		'THEME_DIR': RESOURCES_DIR + "/themes",
		'CHAR_DIR': RESOURCES_DIR + "/characters",
	}


static func get_config_files_paths() -> Dictionary:
	return {
		'SETTINGS_FILE': RESOURCES_DIR + "/settings.cfg",
		'DEFAULT_DEFINITIONS_FILE': RESOURCES_DIR + "/definitions.cfg",
		'SAVED_DEFINITIONS_FILE': WORKING_DIR + "/definitions.cfg",
	}


static func init_definitions_saves(overwrite: bool=true):
	var directory := Directory.new()
	var source := File.new()
	var sink := File.new()
	var paths := get_config_files_paths()
	
	var err := directory.make_dir_recursive(get_working_directories()['WORKING_DIR'])
	
	if err == OK:
		if not directory.file_exists(paths["SAVED_DEFINITIONS_FILE"]):
			err = sink.open(paths["SAVED_DEFINITIONS_FILE"], File.WRITE)
			print('Saved definitions not present, creating file: ' + str(err))
			if err == OK:
				sink.store_string('')
				sink.close()
			else:
				print('Error opening saved definitions file: ' + str(err))
		
		err = sink.open(paths["SAVED_DEFINITIONS_FILE"], File.READ_WRITE)
		if err == OK:
			if overwrite or sink.get_len() == 0:
				err = source.open(paths["DEFAULT_DEFINITIONS_FILE"], File.READ)
				if err == OK:
					sink.store_string(source.get_as_text())
				else:
					print('Error opening default definitions file: ' + str(err))
			else:
				print('Did not overwrite previous saved definitions')
		else:
			print('Error opening saved definitions file: ' + str(err))
	else:
		print('Error creating working directory: ' + str(err))
	
	source.close()
	sink.close()


static func get_path(name: String, extra: String ='') -> String:
	var paths: Dictionary = get_working_directories()
	if extra != '':
		return paths[name] + '/' + extra
	else:
		return paths[name]


static func get_filename_from_path(path: String, extension = false) -> String:
	var file_name: String = path.split('/')[-1]
	if extension == false:
		file_name = file_name.split('.')[0]
	return file_name


static func listdir(path: String) -> Array:
	# https://docs.godotengine.org/en/stable/classes/class_directory.html#description
	var files: Array = []
	var dir := Directory.new()
	var err = dir.open(path)
	if err == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and not file_name.begins_with("."):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Error while accessing path " + path + " - Error: " + str(err))
	return files


static func create_empty_file(path):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string('')
	file.close()


# CONFIG UTIL


static func get_config(id: String) -> ConfigFile:
	var paths := get_config_files_paths()
	var config := ConfigFile.new()
	if id in paths.keys():
		var err = config.load(paths[id])
		if err != OK:
			print("Error while opening config file " + paths[id] + ". Error: " + str(err))
	return config


# FILE UTIL


static func remove_file(path: String):
	var dir = Directory.new()
	dir.remove(path)


# JSON UTIL


static func get_json(dir_id: String, path: String):
	return load_json(get_path(dir_id, path))


static func set_json(dir_id: String, path: String, data: Dictionary):
	var directory = Directory.new()
	var base_path := get_path(dir_id)
	if not directory.dir_exists(base_path):
		directory.make_dir_recursive(base_path)
	var file = File.new()
	file.open(get_path(dir_id, path), File.WRITE)
	file.store_line(to_json(data))
	file.close()


# TIMELINE

static func get_timeline_json(path: String):
	return get_json('TIMELINE_DIR', path)


static func set_timeline(timeline: Dictionary):
	# WARNING: For use in the editor only
	set_json('TIMELINE_DIR', timeline['metadata']['file'], timeline)


static func delete_timeline(filename: String):
	# WARNING: For use in the editor only
	remove_file(get_path('TIMELINE_DIR', filename))


# CHARACTER


static func get_character_json(path: String):
	return get_json('CHAR_DIR', path)


static func set_character(character: Dictionary):
	# WARNING: For use in the editor only
	set_json('CHAR_DIR', character['id'], character)


static func delete_character(filename: String):
	# WARNING: For use in the editor only
	remove_file(get_path('CHAR_DIR', filename))


# THEME


static func get_theme_config(filename: String):
	var config = ConfigFile.new()
	var path
	if filename.begins_with('res://'):
		path = filename
	else:
		path = get_path('THEME_DIR', filename)
	var err = config.load(path)
	if err == OK:
		return config


static func set_theme_value(filename, section, key, value):
	# WARNING: For use in the editor only
	print('=> theme update')
	print(filename)
	var config = get_theme_config(filename)
	config.set_value(section, key, value)
	config.save(get_path('THEME_DIR', filename))


static func add_theme(filename: String):
	create_empty_file(get_path('THEME_DIR', filename))


# SETTINGS


static func get_settings_config():
	return get_config("SETTINGS_FILE")


static func set_settings_value(section: String, key: String, value):
	var config = get_settings_config()
	config.set_value(section, key, value)
	config.save(get_config_files_paths()['SETTINGS_FILE'])


# DEFINITIONS UTIL
# used by default and saved definitions

static func get_definition_key(config_id: String, section: String, key: String, default):
	var config = get_config(config_id)
	if config.has_section(section):
		return config.get_value(section, key, default)
	else:
		return default


static func set_definition_variable(config_id: String, section: String, name: String,  value):
	var config = get_config(config_id)
	config.set_value(section, 'name', name)
	config.set_value(section, 'type', 0)
	config.set_value(section, 'value', str(value))
	return config.save(get_config_files_paths()[config_id])


static func set_definition_glossary(config_id: String, section: String, name: String,  extra_title: String,  extra_text: String,  extra_extra: String):
	var config = get_config(config_id)
	config.set_value(section, 'name', name)
	config.set_value(section, 'type', 1)
	config.set_value(section, 'extra_title', extra_title)
	config.set_value(section, 'extra_text', extra_text)
	config.set_value(section, 'extra_extra', extra_extra)
	return config.save(get_config_files_paths()[config_id])


static func add_definition_variable(config_id: String, section: String, name: String, type: int, value):
	var config = get_config(config_id)
	config.set_value(section, 'name', name)
	config.set_value(section, 'type', type)
	config.set_value(section, 'value', str(value))
	return config.save(get_config_files_paths()[config_id])


static func delete_definition(config_id: String, section: String):
	var config = get_config(config_id)
	config.erase_section(section)
	return config.save(get_config_files_paths()[config_id])



# DEFAULT DEFINITIONS
# Can only be edited in the editor

static func get_default_definitions_config():
	return get_config('DEFAULT_DEFINITIONS_FILE')


static func get_default_definition_key(section: String, key: String, default):
	return get_definition_key('DEFAULT_DEFINITIONS_FILE', section, key, default)


static func set_default_definition_variable(section: String, name: String,  value):
	# WARNING: For use in the editor only
	return set_definition_variable('DEFAULT_DEFINITIONS_FILE', section, name, value)


static func set_default_definition_glossary(section: String, name: String,  extra_title: String,  extra_text: String,  extra_extra: String):
	# WARNING: For use in the editor only
	return set_definition_glossary('DEFAULT_DEFINITIONS_FILE', section, name, extra_title, extra_text, extra_extra)


static func add_default_definition_variable(section: String, name: String, type: int, value):
	# WARNING: For use in the editor only
	return add_definition_variable('DEFAULT_DEFINITIONS_FILE', section, name, type, value)


static func delete_default_definition(section: String):
	# WARNING: For use in the editor only
	return delete_definition('DEFAULT_DEFINITIONS_FILE', section)


# SAVED DEFINITIONS
# Can be edited at runtime, and will persist across runs


static func get_saved_definitions_config():
	return get_config("SAVED_DEFINITIONS_FILE")


static func set_saved_definition_variable(section: String, name: String,  value):
	return set_definition_variable('SAVED_DEFINITIONS_FILE', section, name, value)


static func set_saved_definition_variable_value(section: String, value):
	var config = get_saved_definitions_config()
	return set_definition_variable('SAVED_DEFINITIONS_FILE', section, config.get_value(section, 'name', section), value)


static func set_saved_definition_glossary(section: String, name: String,  extra_title: String,  extra_text: String,  extra_extra: String):
	return set_definition_glossary('SAVED_DEFINITIONS_FILE', section, name, extra_title, extra_text, extra_extra)

