extends Control


@export var scenes: Dictionary ## Все сцены

var current_scene: String = "" ## Текущая сцена
var current_upscene: String = "" ## Текущая сцена на переднем плане (сцена поверх)


func _ready() -> void:
	for scene in scenes.keys():
		if !(scenes[scene] is NodePath): continue
		scenes[scene] = get_node(scenes[scene])
	G.scene_changer = self
	print_debug("Scene Chager установлен на ", G.scene_changer)

## Смена текущей сцены
func change_scene(new_scene: String, save_current := false) -> Error:
	if !(new_scene in scenes.keys()):
		return FAILED
	
	# Нет ещё сцены
	if current_scene == "":
		current_scene = new_scene
	elif !save_current: # Сцена не поверх
		scenes[current_scene].visible = false
		current_scene = new_scene
	elif save_current: # Сцена поверх
		if current_upscene:
			scenes[current_upscene].visible = false
		current_upscene = new_scene
	
	scenes[new_scene].visible = true
	print_debug("Сцена изменена на " + new_scene, "; поверх = ", save_current)
	return OK

## Закрытие сцены поверх
func return_to_current_scene() -> Error:
	if current_upscene == "" or current_scene == "":
		return FAILED
	
	scenes[current_upscene].visible = false
	current_upscene = ""
	print_debug("Сцена поверх скрыта")
	return OK
	
	
