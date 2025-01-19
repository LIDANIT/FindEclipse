extends Control


func set_point(lat: float, lon: float):
	$PanelContainer/VBoxContainer/VBoxContainer/Latitude/Data/Param1.text = str(abs(lat))
	$PanelContainer/VBoxContainer/VBoxContainer/Longitude/Data/Param1.text = str(abs(lon))
	
	if lat > 0: $PanelContainer/VBoxContainer/VBoxContainer/Latitude/Data/Param2.selected = 1
	else: $PanelContainer/VBoxContainer/VBoxContainer/Latitude/Data/Param2.selected = 0
	if lon > 0: $PanelContainer/VBoxContainer/VBoxContainer/Longitude/Data/Param2.selected = 1
	else: $PanelContainer/VBoxContainer/VBoxContainer/Longitude/Data/Param2.selected = 0
	
	if G.date != "0000-00-00":
		$PanelContainer/VBoxContainer/VBoxContainer/StartDate/Data/Param1.text = G.date.split('-')[0]
		$PanelContainer/VBoxContainer/VBoxContainer/StartDate/Data/Param2.text = G.date.split('-')[1]
		$PanelContainer/VBoxContainer/VBoxContainer/StartDate/Data/Param3.text = G.date.split('-')[2]


func is_year_leap(year: int) -> bool:
	if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0:
		return true
	return false


func check_date(year: int, month: int, day: int) -> int:
	if year < 1:
		return FAILED
	if month < 1 or month > 12:
		return FAILED
	if day < 1 or day > 31:
		return FAILED
	if month in [4, 6, 9, 11]:
		if day == 31:
			return FAILED
	elif month == 2:
		if is_year_leap(year):
			if day > 29:
				return FAILED
		else:
			if day > 28:
				return FAILED
	return OK


func check_date_string(date_string: String) -> int:
	var year: int
	var month: int
	var day: int
	var splitted: PackedStringArray = date_string.split('-')
	year = int(splitted[0])
	month = int(splitted[1])
	day = int(splitted[2])
	
	return check_date(year, month, day)


func _on_kill_scene_pressed():
	for data_block in $PanelContainer/VBoxContainer/VBoxContainer.get_children():
			data_block.get_node("Label").set("theme_override_colors/font_color", Color.WHITE)
			for param in data_block.get_node("Data").get_children():
				if param is LineEdit:
					param.text = ""
				elif param is OptionButton:
					param.selected = 0
	$"../../SceneChanger".return_to_current_scene()


func _on_enter_params_button_pressed():
	var data: Dictionary = {}
	
	for data_block in $PanelContainer/VBoxContainer/VBoxContainer.get_children():
		var block_name := data_block.name
		var data_array := []
		for param in data_block.get_node("Data").get_children():
			if param is LineEdit:
				if "Date" in block_name and param.name == "Param1":
					if len(param.text) == 1:
						param.text = "000" + param.text
					elif len(param.text) == 2:
						param.text = "00" + param.text
					elif len(param.text) == 3:
						param.text = '0' + param.text
				data_array.append(param.text)
			elif param is OptionButton:
				if param.get_selected_id() != -1:
					data_array.append(param.get_item_text(param.get_item_index(param.get_selected_id())))
				else:
					data_array.append("")
			else:
				print("No current type")
		data[block_name] = data_array

	var check = check_data(data)
	if len(check) == 0:
		for data_block in $PanelContainer/VBoxContainer/VBoxContainer.get_children():
			data_block.get_node("Label").set("theme_override_colors/font_color", Color.WHITE)
			for param in data_block.get_node("Data").get_children():
				if param is LineEdit:
					param.text = ""
				elif param is OptionButton:
					param.selected = 0
		$"../../SceneChanger".return_to_current_scene()
		G.calculate_eclipse(data)
	else:
		for data_block in $PanelContainer/VBoxContainer/VBoxContainer.get_children():
			data_block.get_node("Label").set("theme_override_colors/font_color", Color.WHITE)
			var block_name := data_block.name
			if block_name in check:
				data_block.get_node("Label").set("theme_override_colors/font_color", Color.RED)

func check_data(data: Dictionary) -> Array:
	var errors := []
	
	for param in data.keys():
		match param:
			"Latitude":
				if !data[param][0].is_valid_float():
					errors.append("Latitude")
					continue
				if float(data[param][0]) < 0 or float(data[param][0]) > 90:
					errors.append("Latitude")
					continue
				if data[param][1] == "":
					errors.append("Latitude")
					continue
			"Longitude":
				if !data[param][0].is_valid_float():
					errors.append("Longitude")
					continue
				if float(data[param][0]) < 0 or float(data[param][0]) > 180:
					errors.append("Longitude")
					continue
				if data[param][1] == "":
					errors.append("Longitude")
					continue
			"StartDate":
				if !data[param][0].is_valid_int() or\
					!data[param][1].is_valid_int() or\
					!data[param][2].is_valid_int():
						errors.append("StartDate")
						continue
				
				var y = data[param][0]
				var m = data[param][1]
				var d = data[param][2]
				
				while len(y) < 4:
					y = '0' + y
				while len(m) < 2:
					m = '0' + m
				while len(d) < 2:
					d = '0' + d
				
				if !(check_date_string(y + '-' + m + '-' + d) == OK):
					errors.append("StartDate")
					continue
			"StartTime":
				if !data[param][0].is_valid_int() or\
					!data[param][1].is_valid_int() or\
					!data[param][2].is_valid_int():
						errors.append("StartTime")
						continue
				
				var h = data[param][0]
				var m = data[param][1]
				var s = data[param][2]
				
				if int(h) > 23 or int(h) < 0:
					errors.append("StartTime")
					continue
				if int(m) > 59 or int(m) < 0:
					errors.append("StartTime")
					continue
				if int(s) > 59 or int(s) < 0:
					errors.append("StartTime")
					continue
			"EndDate":
				if !data[param][0].is_valid_int() or\
					!data[param][1].is_valid_int() or\
					!data[param][2].is_valid_int():
						errors.append("EndDate")
						continue
				
				var y = data[param][0]
				var m = data[param][1]
				var d = data[param][2]
				
				while len(y) < 4:
					y = '0' + y
				while len(m) < 2:
					m = '0' + m
				while len(d) < 2:
					d = '0' + d
				
				if !(check_date_string(y + '-' + m + '-' + d) == OK):
					errors.append("EndDate")
					continue
			"EndTime":
				if !data[param][0].is_valid_int() or\
					!data[param][1].is_valid_int() or\
					!data[param][2].is_valid_int():
						errors.append("EndTime")
						continue
				
				var h = data[param][0]
				var m = data[param][1]
				var s = data[param][2]
				
				if int(h) > 23 or int(h) < 0:
					errors.append("EndTime")
					continue
				if int(m) > 59 or int(m) < 0:
					errors.append("EndTime")
					continue
				if int(s) > 59 or int(s) < 0:
					errors.append("EndTime")
					continue
			"TimeFrequency":
				if !data[param][0].is_valid_int():
					errors.append("TimeFrequency")
					continue
				
				if int(data[param][0]) < 0:
					errors.append("TimeFrequency")
					continue
			_:
				continue
	return errors
