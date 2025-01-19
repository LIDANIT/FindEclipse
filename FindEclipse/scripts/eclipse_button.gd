extends Button


func start(eclipse_name: String):
	text = eclipse_name


func _on_pressed():
	G.eclipse = text
	G.set_eclipse.emit()
