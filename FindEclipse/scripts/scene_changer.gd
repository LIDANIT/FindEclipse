extends Control


@export var scenes: Dictionary


var current_scene: String = ""
var current_upscene: String = ""


func _ready():
	for scene in scenes.keys():
		scenes[scene] = get_node(scenes[scene])
	G.scene_changer = self
	print("Scene Chager установлен на ", G.scene_changer)


func change_scene(new_scene: String, save_current := false):
	if !(new_scene in scenes.keys()):
		return -1
	
	if current_scene == "":
		current_scene = new_scene
	elif !save_current:
		scenes[current_scene].visible = false
		current_scene = new_scene
	elif save_current:
		if current_upscene:
			scenes[current_upscene].visible = false
		current_upscene = new_scene
	
	scenes[new_scene].visible = true
	print("Сцена изменена на " + new_scene, ";поверх=", save_current)
	return OK


func return_to_current_scene():
	if current_upscene == "" or current_scene == "":
		return -1
	
	scenes[current_upscene].visible = false
	current_upscene = ""
	print("Сцена поверх скрыта")
	return OK
