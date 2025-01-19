extends Node

var camera = null
var thread: Thread
var page := {}
var eclipse := ""
var scene_changer
var date = "0000-00-00"
var is_calculating := false

signal zoom(now: float)
signal marker_clicked(id: int)
signal start_calculating
signal go_to(lat: float, lon: float)
signal stop_calculating
signal no_eclipses
signal set_point(lat: float, lon: float)
signal set_eclipse()

func calculate_eclipse(data: Dictionary):
	var lat
	var lon
	var st_d
	var en_d
	var st_t
	var en_t
	var freq
	var file
	
	for param in data.keys():
		match param:
			"Latitude":
				var plus = ""
				if data[param][1] == "ю. ш.": plus = "-"
				lat = plus + data[param][0]
			"Longitude":
				var plus = ""
				if data[param][1] == "з. д.": plus = "-"
				lon = plus + data[param][0]
			"StartDate":
				st_d = data[param][0] + '/' + data[param][1] + '/' + data[param][2]
			"StartTime":
				st_t = data[param][0] + '/' + data[param][1] + '/' + data[param][2]
			"EndDate":
				en_d = data[param][0] + '/' + data[param][1] + '/' + data[param][2]
			"EndTime":
				en_t = data[param][0] + '/' + data[param][1] + '/' + data[param][2]
			"TimeFrequency":
				freq = data[param][0]
			"Accuracy":
				if data[param][0] == "высокая":
					file = "astropy.exe"
				else:
					file = "pyephem.exe"
	
	var args = [lat, lon, st_d, st_t, en_d, en_t, freq]
	print("Отправляемые параметры: ", args)
	await scene_changer.change_scene("MainScreen")
	start_calculating.emit()
	print("Начало расчёта...")
	go_to.emit(float(lat), float(lon))
	print("Перемещение камеры по координатам: ", lat, ' ', lon)
	is_calculating = true
	thread = Thread.new()
	print("Новый поток создан: ", thread)
	thread.start(get_calculations.bind(args, file))
	print("Запущен: " + file)


func start_page(output):
	page = JSON.parse_string(output[0].substr(output[0].find('{'), output[0].rfind('}') - output[0].find('{') + 1))
	if page == null or page == {}:
		page = {}
		print("Не получено данных или в них допущена ошибка:")
		print("-----------------")
		print(output[0])
		print("-----------------")
		stop_calculating.emit()
	else:
		print("Данные получены:")
		print("-----------------")
		print(page)
		print("-----------------")
		stop_calculating.emit()
		scene_changer.change_scene("Page")


func get_calculations(args, file):
	var output = []
	print(OS.get_executable_path())
	var exit = OS.execute(OS.get_executable_path().get_base_dir().path_join("/res/" + file), args, output)
	if exit == OK:
		call_deferred("start_page", output)
		print("Успешное вычисление!")
	else:
		print("Неверное выполнение скрипта(" + file + ')')
	

func _exit_tree():
	if thread != null and thread.is_started():
		thread.wait_to_finish()
		print("Поток завершил работу!")


func set_date(y: String, m: String, d: String):
	date = y + '-' + m + '-' + d
	print("Установлена новая дата: ", date)
