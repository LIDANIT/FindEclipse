extends Node3D
class_name Marker

const R := 2.0 ## Радиус маркера
var eclipses := {} ## Посчитанные на этом месте затмения

@onready var mesh = MeshInstance3D.new()

func _ready() -> void:
	# Работа с моделью
	var material = StandardMaterial3D.new() # Материал цвета маркера
	material.albedo_color = Color.FIREBRICK
	
	var sphere = SphereMesh.new() # Сферический мэш маркера
	sphere.radius = R
	sphere.height = R * 2
	sphere.material = material
	
	mesh.mesh = sphere
	add_child(mesh) # Добавление мэша на сцену
	
	# Создание фигуры сферы для Area3D
	var shape = SphereShape3D.new()
	shape.radius = R
	
	# Создание объекта коллизии для Area3D
	var collision_area = CollisionShape3D.new()
	collision_area.shape = shape
	
	# Создание Area3D
	var area = Area3D.new()
	area.add_child(collision_area)
	
	# Подключение событий для обработки...
	area.connect("input_event", Callable(_on_area_3d_input_event)) # ...нажатия мышкой
	area.connect("mouse_entered", Callable(_on_area_3d_mouse_entered)) # ...наведения мыши
	area.connect("mouse_exited", Callable(_on_area_3d_mouse_exited)) # ...убирания мыши
	add_child(area)
	
	set_data() # Установка рассчитанных в этой точке затмений
	
	# Установка позиции
	global_position = Vector3(0, 0, G.R) # Изменяем позицию так, чтобы маркера поставился перед камерой на Земле

# Определение словаря eclipses
func set_data():
	await G.stop_calculating
	eclipses = G.page

# Обработка нажатия
func _on_area_3d_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed and event.double_click and !G.no_eclipses_window:
			print_debug("Открытие маркера с затмениями: ", eclipses)
			G.open_eclipses(eclipses) # Открываем сохранённые здесь затмения

# Наведение мышкой - увеличение размера
func _on_area_3d_mouse_entered():
	mesh.mesh.radius = R * 1.2
	mesh.mesh.height = R * 2 * 1.2

# НВозвращение к начальным параметрам
func _on_area_3d_mouse_exited():
	mesh.mesh.radius = R
	mesh.mesh.height = R * 2
