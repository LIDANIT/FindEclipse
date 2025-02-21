extends Control


const button := preload("res://scenes/eclipse_button.tscn") ## Сцена кнопки затмения

var vis := false # Нужна для проверки открытия сцены


func _ready() -> void:
	G.set_eclipse.connect(open_eclipse_info)

## Открытие сцены
func start() -> void:
	# Удаление предыдущих блоков
	for i in $MarginContainer/PanelContainerLeft/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer.get_children():
		i.queue_free()
	
	var group = ButtonGroup.new() # Группа кнопок затмения (для переключения)
	
	for eclipse in G.page.keys():
		# Установка магнитуды в название
		var k = snapped(float(G.page[eclipse]["magnitude"]), 0.001)
		var str_k = str(k)
		if k == 0:
			continue
		elif len(str_k) == 1:
			str_k += ".000"
		elif len(str_k) == 3:
			str_k += "00"
		elif len(str_k) == 4:
			str_k += '0'
		
		var but = button.instantiate()
		but.button_group = group
		$MarginContainer/PanelContainerLeft/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer.add_child(but)
		but.start(eclipse + '(' + str_k + ')')

## Открыто конкретное затмение
func open_eclipse_info() -> void:
	print_debug("Открыты характеристики: ")
	print_debug("-----------------")
	for i in G.page[G.eclipse.split('(')[0]].keys():
		match i:
			"start_time":
				$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param1/Data.text = G.page[G.eclipse.split('(')[0]]["start_time"].split(' ')[0]
				$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param2/Data.text = G.page[G.eclipse.split('(')[0]]["start_time"].split(' ')[1]
			"end_time":
				$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param3/Data.text = G.page[G.eclipse.split('(')[0]]["end_time"].split(' ')[1]
			"peak_time":
				$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param6/Data.text = G.page[G.eclipse.split('(')[0]]["peak_time"].split(' ')[1]
			"magnitude":
				var k = snapped(float(G.page[G.eclipse.split('(')[0]]["magnitude"]), 0.001)
				var str_k = str(k)
				if k == 0:
					continue
				elif len(str_k) == 1:
					str_k += ".000"
				elif len(str_k) == 3:
					str_k += "00"
				elif len(str_k) == 4:
					str_k += '0'
				
				$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param5/Data.text = str_k
			"type":
				$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param4/Data.text = G.page[G.eclipse.split('(')[0]]["type"]
		print_debug(i, ' ', G.page[G.eclipse.split('(')[0]][i])
	print_debug("-----------------")


func _on_return_pressed() -> void:
	$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param1/Data.text = ''
	$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param2/Data.text = ''
	$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param3/Data.text = ''
	$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param4/Data.text = ''
	$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param5/Data.text = ''
	$MarginContainer/PanelContainerRight/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer/Param6/Data.text = ''
	vis = false
	$"../../SceneChanger".change_scene("MainScreen")


func _process(_delta) -> void:
	if visible and !vis:
		vis = true
		start()
