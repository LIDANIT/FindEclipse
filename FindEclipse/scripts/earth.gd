extends Node3D

const a := 50.0 ## Ускорение замедления

var mouse_button_hold := false ## Зажата ли мышь
var exit := false ## Отжата мышь в моменте

var prev := Vector2.ZERO ## Предыдущее положение курсора
var next := Vector2.ZERO ## Текущее положение курсора
var v := Vector2.ZERO ## Скорость курсора/вращения

var a1 := 0.0 ## Замедление по OX
var a2 := 0.0 ## Замедление по OY

var marker_preload = preload("res://scenes/marker.tscn") # Предварительная загрузка сцены точки на Земле

func _ready() -> void:
	G.go_to.connect(turn)

## Поворот по координатам
func turn(lat: float, lon: float) -> void:
	global_rotation = Vector3(0, 0, 0)
	rotate_y(-deg_to_rad(lon))
	rotate_x(deg_to_rad(lat))
	
	var marker = Marker.new()
	$Markers.add_child(marker)


func _process(delta) -> void:
	if G.scene_changer.current_upscene != "" or G.is_calculating:
		next = get_viewport().get_mouse_position()
		prev = next
		return

	if mouse_button_hold:
		# Вращение при зажатии
		v = Vector2.ZERO
		next = get_viewport().get_mouse_position()
		rotate_y((next.x - prev.x) * .1 * delta)
		rotate_x((next.y - prev.y) * .1 * delta)
		prev = next
	else:
		# Остаточное вращение
		if exit:
			next = get_viewport().get_mouse_position()
			v = next - prev
			exit = false
			a1 = abs(v.x) / (abs(v.y) + abs(v.x)) * a
			a2 = abs(v.y) / (abs(v.y) + abs(v.x)) * a

		rotate_y(v.x * .1 * delta)
		rotate_x(v.y * .1 * delta)
		if v:
			if v.x < 0: v.x += a1 * delta
			elif v.x > 0: v.x -= a1 * delta
			if v.y < 0: v.y += a2 * delta
			elif v.y > 0: v.y -= a2 * delta
			if abs(v.x) <= a1 * delta * 2: v.x = 0
			if abs(v.y) <= a2 * delta * 2: v.y = 0


func _unhandled_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.is_pressed():
			mouse_button_hold = true
			prev = get_viewport().get_mouse_position()
		if event.button_index == 1 and not event.is_pressed():
			mouse_button_hold = false
			exit = true
