extends Camera3D

var zoom = 1.0
@onready var start_fov = fov
@onready var zoom_max = 179.0 / start_fov - 0.9
@onready var zoom_min = 1.0 / start_fov + 0.3
@onready var zoom_step = (zoom_max - zoom_min) / 70.0


func _ready():
	G.camera = self
	G.go_to.connect(go)


func _unhandled_input(_event):
	if G.scene_changer.current_upscene != "":
		return
	if Input.is_action_just_pressed("zoom+"):
		if zoom > zoom_min + zoom_step:
			zoom -= zoom_step
			G.zoom.emit(zoom)
	elif Input.is_action_just_pressed("zoom-"):
		if zoom < zoom_max - zoom_step:
			zoom += zoom_step
			G.zoom.emit(zoom)


func _process(_delta):
	fov = zoom * start_fov


func go(_lat: float, _lon: float):
	zoom = zoom_min
