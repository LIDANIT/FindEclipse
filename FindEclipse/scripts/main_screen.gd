extends Control


func _ready():
	DisplayServer.window_set_min_size(Vector2(980, 540))
	G.set_point.connect(open_in_point)
	$"../../SceneChanger".change_scene("MainScreen")
	G.start_calculating.connect(visible_text.bind(true))
	G.stop_calculating.connect(visible_text.bind(false))


func open_in_point(lat: float, lon: float):
	if !G.is_calculating:
		$"../../SceneChanger".change_scene("CalculateEclipse", true)
		$"../CalculateEclipse".set_point(lat, lon)


func visible_text(val: bool) -> void:
	if !val:
		if G.page == {}:
			$MarginContainer/PanelContainer.stop()
			await get_tree().create_timer(5).timeout
		$MarginContainer/PanelContainer.visible = false
		G.is_calculating = false
	else:
		$MarginContainer/PanelContainer.visible = true
		$MarginContainer/PanelContainer.start()


func _on_set_date_button_pressed():
	if !G.is_calculating:
		$"../../SceneChanger".change_scene("SetDate", true)


func _on_calculate_eclipse_button_pressed():
	if !G.is_calculating:
		$"../../SceneChanger".change_scene("CalculateEclipse", true)


func _on_autor_pressed():
	if !G.is_calculating:
		$"../../SceneChanger".change_scene("Info", true)
