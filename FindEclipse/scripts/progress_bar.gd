extends Control

var started := false ## Запущен ли прогресс-бар
var connection: PacketPeerUDP ## Соединение с сервером
var type := "" ## Тип поиска
var text_is_setting := false ## Происходит ли обновление текста прогресс-бара

@onready var label = $PanelContainer/VBoxContainer/Label
@onready var progress_bar = $PanelContainer/VBoxContainer/TextureProgressBar
@onready var timer = $Timer

## Подключение к серверу
func start():
	if S.start():
		connection = PacketPeerUDP.new()
		connection.connect_to_host("127.0.0.1", S.PORT)
		connection.put_packet("register".to_utf8_buffer())
		started = true
		print_debug("Сервер запущен[" + str(S.PORT) + "].")
	else:
		print_debug("Ошибка при создании сервера.")


func _process(_delta):
	if visible and !started:
		start()
	# Если клиент подключен
	if started:
		if !text_is_setting: set_text() # Обновление текста прогресс-бара
		if connection.get_available_packet_count() > 0:
			var packet = connection.get_packet() # Полученный пакет
			var data = packet.get_string_from_utf8()
			if data == "fast" and type != "fast":
				type = "fast"
			elif data == "accurate" and type != "accurate":
				type = "accurate"
				progress_bar.value = 0.0
				label.text = "Запуск точного поиска"
			elif data.is_valid_int():
				progress_bar.value = int(data)
			else:
				print_debug("Получено неизвестное сообщение: " + data)
		# Остановка прогресс-бара
		if (type == "accurate" and progress_bar.value == 100.0) or !G.is_calculating:
			if connection.is_socket_connected():
				S.stop()
			started = false
			G.scene_changer.return_to_current_scene()
			type = ""
			progress_bar.value = 0.0

## Установка и обновление текста
func set_text() -> Error:
	text_is_setting = true
	var last_type = type
	var text = ""
	if type == "fast":
		text = "Быстрый поиск"
	elif type == "accurate":
		text = "Точный поиск"
	else:
		text = "Запуск поиска"
	label.text = text + "."
	timer.start(1)
	await timer.timeout
	if !started or type != last_type: 
		text_is_setting = false
		return OK
	label.text = text + ".."
	timer.start(1)
	await timer.timeout
	if !started or type != last_type:
		text_is_setting = false
		return OK
	label.text = text + "..."
	timer.start(1)
	await timer.timeout
	text_is_setting = false
	return OK

## Запрос на преостановку расчётов кнопкой "Отмена"
func _on_stop_pressed():
	connection.put_packet("close".to_utf8_buffer())
	print_debug("Запрос остановки расчёта отправлен")
	G.is_calculating = false
	G.stop_calculating.emit()
