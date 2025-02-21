extends Button

## Создание кнопки
func start(eclipse_name: String) -> void:
	text = eclipse_name


func _on_pressed() -> void:
	G.eclipse = text
	G.set_eclipse.emit()
