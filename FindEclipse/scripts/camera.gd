extends Camera3D

var zoom = 1.0 ## Текущее приближение

@onready var start_fov = fov ## Начальное приближение
@onready var zoom_min = 179.0 / start_fov - 0.9 ## Максимальное приближение
@onready var zoom_max = 1.0 / start_fov + 0.3 ## Минимальное приближение
@onready var zoom_step = (zoom_min - zoom_max) / 70.0 ## Шаг приближения


func _ready() -> void:
	G.camera = self
	G.go_to.connect(go)


func _unhandled_input(_event) -> void:
	if G.scene_changer.current_upscene != "":
		return

	if Input.is_action_just_pressed("zoom+"):
		if zoom > zoom_max + zoom_step:
			zoom -= zoom_step
			G.zoom.emit(zoom)
	elif Input.is_action_just_pressed("zoom-"):
		if zoom < zoom_min - zoom_step:
			zoom += zoom_step
			G.zoom.emit(zoom)


func _process(_delta) -> void:
	fov = zoom * start_fov


func go(_lat: float, _lon: float) -> void:
	zoom = zoom_max
