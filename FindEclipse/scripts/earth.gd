extends Node3D

var planets = {}

var mouse_button_hold = false
var exit = false
var prev = Vector2.ZERO
var next = Vector2.ZERO

const a = 50

var v = Vector2.ZERO

var a1 = 0
var a2 = 0


func _ready():
	G.go_to.connect(turn)


func turn(lat: float, lon: float):
	global_rotation = Vector3(0, 0, 0)
	rotate_y(-deg_to_rad(lon))
	rotate_x(deg_to_rad(lat))



func _process(delta):
	if G.scene_changer.current_upscene != "" or G.is_calculating:
		next = get_viewport().get_mouse_position()
		prev = next
		return
	if mouse_button_hold:
		v = Vector2.ZERO
		next = get_viewport().get_mouse_position()
		rotate_y((next.x - prev.x) * .1 * delta)
		rotate_x((next.y - prev.y) * .1 * delta)
		prev = next
	else:
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

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.is_pressed():
			mouse_button_hold = true
			prev = get_viewport().get_mouse_position()
		if event.button_index == 1 and not event.is_pressed():
			mouse_button_hold = false
			exit = true
