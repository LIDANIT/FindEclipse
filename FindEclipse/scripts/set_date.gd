extends Control


func _on_kill_scene_pressed():
	$"../../SceneChanger".return_to_current_scene()


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


func _on_enter_data_pressed():
	var y = $PanelContainer/VBoxContainer/Date/Data/Param1.text
	var m = $PanelContainer/VBoxContainer/Date/Data/Param2.text
	var d = $PanelContainer/VBoxContainer/Date/Data/Param3.text
	
	while len(y) < 4:
		y = '0' + y
	while len(m) < 2:
		m = '0' + m
	while len(d) < 2:
		d = '0' + d
	
	
	if check_date_string(y + '-' + m + '-' + d) == OK:
		G.set_date(y, m, d)
		
		$PanelContainer/VBoxContainer/Date/Data/Param1.text = ""
		$PanelContainer/VBoxContainer/Date/Data/Param2.text = ""
		$PanelContainer/VBoxContainer/Date/Data/Param3.text = ""
		
		$PanelContainer/VBoxContainer/Label.set("theme_override_colors/font_color", Color.WHITE)
		$"../../SceneChanger".return_to_current_scene()
	else:
		$PanelContainer/VBoxContainer/Label.set("theme_override_colors/font_color", Color.RED)
