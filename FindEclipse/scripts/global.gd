extends Node

const R = 100.0 ## Радиус модели Земли

var camera: Camera3D = null ## Текущая камера
var page := {} ## Данные о найденных затмениях
var eclipse := "" ## Выбранное затмение

# Вспомогательные переменные
var thread: Thread = null # Поток для расчёта затмений
var scene_changer: Control = null # Сцена, отвечающая за смену сцен
var is_calculating := false # Активен ли расчёт
var no_eclipses_window := false # Активно ли окно "Затмений не найдено"
var lat # Широта
var lon # Долгота
var st_d # Стартовая дата
var en_d # Конечная дата
var st_t # Стартовое время
var en_t # Конечное время
var freq # Временной шаг

signal zoom(cur_zoom: float) ## Приближение/отдаление камеры ("zoom-", "zoom+")
signal start_calculating ## Начало расчёта
signal go_to(lat: float, lon: float) ## Прокрутка Земли до координат
signal stop_calculating ## Конец расчёта
signal no_eclipses ## Затмений не найдено
signal set_point(lat: float, lon: float) ## Установка координат по двойному нажатию
signal set_eclipse ## Выбор затмения


func _ready():
	DisplayServer.window_set_min_size(Vector2i(960, 540))
	get_tree().set_auto_accept_quit(false)


## Функция для запуска расчёта затмений
func calculate_eclipse(data: Dictionary) -> void:
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
	
	var args = [lat, lon, st_d, st_t, en_d, en_t, freq]
	print_debug("Отправляемые параметры: ", args)
	
	await scene_changer.change_scene("MainScreen")
	
	start_calculating.emit()
	print_debug("Начало расчёта...")
	go_to.emit(float(lat), float(lon))
	print_debug("Перемещение камеры по координатам: ", lat, ' ', lon)
	is_calculating = true
	thread = Thread.new()
	print_debug("Новый поток создан: ", thread)
	thread.start(get_calculations.bind(args, "eclipse_finder.exe"))
	print_debug("Запущен: pyephem.exe")
	scene_changer.change_scene("ProgressBar", true)


## Открытие сцены с затмениями
func start_page(output) -> void:
	# Парсинг данных
	page = JSON.parse_string(output[0].substr(output[0].find('{'), output[0].rfind('}') - output[0].find('{') + 1))
	
	if page == null or page == {}:
		page = {}
		print_debug("Не получено данных или в них допущена ошибка:")
		print_debug("-----------------")
		print_debug(output[0])
		print_debug("-----------------")
		G.is_calculating = false
		stop_calculating.emit()
	else:
		print_debug("Данные получены:")
		print_debug("-----------------")
		print_debug(page)
		print_debug("-----------------")
		stop_calculating.emit()
		G.is_calculating = false
		scene_changer.change_scene("Page")

## Открытие страницы с ранее просчитанными затмениями через маркер
func open_eclipses(eclipses: Dictionary) -> void:
	if G.is_calculating:
		await G.stop_calculating
	page = eclipses
	scene_changer.change_scene("Page")


## Запуск и получение результата расчёта
func get_calculations(args, f) -> void:
	var output = []
	var path_to_calculation_file
	if !OS.is_debug_build():
		path_to_calculation_file = OS.get_executable_path().get_base_dir().path_join("/res/" + f)
	else:
		path_to_calculation_file = ProjectSettings.globalize_path("res://resources/res/" + f)
	var ex = OS.execute(path_to_calculation_file, args, output)
	if ex == OK:
		output[0] = output[0].substr(output[0].find("End:"), -1)
		call_deferred("start_page", output)
		print_debug("Успешное вычисление!")
	else:
		print_debug("Неверное выполнение скрипта(" + f + ')')
		page = {}
		G.is_calculating = false
		stop_calculating.emit()

## Окончание рассчёта в потоке
func _exit_tree() -> void:
	if thread != null and thread.is_started():
		thread.wait_to_finish()
		print_debug("Поток завершил работу!")

## Запрос на закрытие
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Если ведётся расчёт - отказ
		if thread is Thread and thread.is_alive():
			var dialog = AcceptDialog.new()
			dialog.theme = load("res://resources/styles/main_theme.tres")
			dialog.title = "Ошибка закрытия"
			dialog.dialog_text = "Дождитесь завершения процесса расчёта или отмените его."
			dialog.ok_button_text = "Ясно!"
			get_tree().current_scene.add_child(dialog)
			dialog.popup_centered(Vector2i(150, 150))
			await dialog.confirmed
			return FAILED
		
		# Подтверждение запроса
		var dialog_close = AcceptDialog.new()
		dialog_close.theme = load("res://resources/styles/main_theme.tres")
		dialog_close.title = "Выход"
		dialog_close.dialog_text = "Вы уверены, что хотите выйти?"
		dialog_close.ok_button_text = "Да!"
		dialog_close.add_cancel_button("Нет.")
		dialog_close.confirmed.connect(exit.bind(true, dialog_close))
		dialog_close.canceled.connect(exit.bind(false, dialog_close))
		get_tree().current_scene.add_child(dialog_close)
		dialog_close.popup_centered(Vector2i(150, 10))
		return OK

## Согласие или несогласие закрыть приложение
func exit(answer: bool, dialog: AcceptDialog) -> void:
	if answer:
		get_tree().quit(0)
	dialog.queue_free()
