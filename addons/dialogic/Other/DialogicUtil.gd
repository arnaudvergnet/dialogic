tool
class_name DialogicUtil


static func get_character_list() -> Array:
	var characters: Array = []
	for file in DialogicResources.listdir(DialogicResources.get_path('CHAR_DIR')):
		if '.json' in file:
			var data: Dictionary     = DialogicResources.get_character_json(file)
			var color: Color         = Color("#ffffff")
			var c_name: String       = data['id']
			var default_speaker      = false
			var portraits: Array     = []
			var display_name: String = ''
			
			if data.has('color'):
				color = Color(data['color'])
			if data.has('name'):
				c_name = data['name']
			if data.has('default_speaker'):
				default_speaker = data['default_speaker']
			if data.has('portraits'):
				portraits = data['portraits']
			if data.has('display_name'):
				if data['display_name_bool']:
					if data.has('display_name'):
						display_name = data['display_name']
						
			characters.append({
				'name': c_name,
				'color': color,
				'file': file,
				'default_speaker' : default_speaker,
				'portraits': portraits,
				'display_name': display_name,
				'data': data # This should be the only thing passed... not sure what I was thinking
			})

	return characters


static func get_timeline_list() -> Array:
	var timelines: Array = []
	for file in DialogicResources.listdir(DialogicResources.get_path('TIMELINE_DIR')):
		if '.json' in file:
			var data = DialogicResources.get_timeline_json(file)
			if data.has('error') == false:
				var metadata = data['metadata']
				var color = Color("#ffffff")
				if metadata.has('name'):
					timelines.append({'name':metadata['name'], 'color': color, 'file': file })
				else:
					timelines.append({'name':file.split('.')[0], 'color': color, 'file': file })
	return timelines


static func get_theme_list() -> Array:
	var themes: Array = []
	for file in DialogicResources.listdir(DialogicResources.get_path('THEME_DIR')):
		if '.cfg' in file:
			var config = ConfigFile.new()
			var err = DialogicResources.get_theme_config(file)
			themes.append({
				'file': file,
				'name': config.get_value('settings','name', file),
				'config': config
			})
	return themes


static func get_default_definitions_list() -> Array:
	return DialogicDefinitionsUtil.definitions_json_to_array(DialogicResources.get_default_definitions())


static func generate_random_id() -> String:
	return str(OS.get_unix_time()) + '-' + str(100 + randi()%899+1)


static func compare_dicts(dict_1: Dictionary, dict_2: Dictionary) -> bool:
	# I tried using the .hash() function but it was returning different numbers
	# even when the dictionary was exactly the same.
	if str(dict_1) != "Null" and str(dict_2) != "Null":
		if str(dict_1) == str(dict_2):
			return true
	return false


