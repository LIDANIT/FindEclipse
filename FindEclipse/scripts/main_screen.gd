extends Control


func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2(980, 540))
	G.set_point.connect(open_in_point)
	$"../../SceneChanger".change_scene("MainScreen")
	G.stop_calculating.connect(visible_text)

## Открытие двойным кликом
func open_in_point(lat: float, lon: float) -> void:
	if !G.is_calculating:
		$"../../SceneChanger".change_scene("CalculateEclipse", true)
		$"../CalculateEclipse".set_point(lat, lon)

## Панель ненайденных затмений
func visible_text() -> void:
	if G.page == {} and !G.no_eclipses_window:
		# Затмений не найдено
		G.no_eclipses_window = true
		$MarginContainer/PanelContainer.visible = true
		await get_tree().create_timer(5).timeout
		$MarginContainer/PanelContainer.visible = false
		G.no_eclipses_window = false


func _on_calculate_eclipse_button_pressed() -> void:
	if !G.is_calculating:
		$"../../SceneChanger".change_scene("CalculateEclipse", true)


func _on_autor_pressed() -> void:
	if !G.is_calculating:
		$"../../SceneChanger".change_scene("Info", true)


func _on_help_pressed():
	if !G.is_calculating:
		$"../../SceneChanger".change_scene("Help", true)
