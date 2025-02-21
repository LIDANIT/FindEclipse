extends Node

const PORT = 4242 ## Порт сервера

var server := UDPServer.new() ## UDP-сервер для прогресс-бара
var peers := [] ## Все подключенные клиенты
var online := false ## Активен ли сервер

## Запуск сервера
func start() -> bool:
	if server.listen(PORT, "127.0.0.1") != OK:
		online = false
		return false
	online = true
	return true


func _process(_delta):
	if online:
		server.poll() # Обновление статуса сервера
		if server.is_connection_available():
			var peer: PacketPeerUDP = server.take_connection() # Соединённый клиент
			var packet = peer.get_packet() # Полученный пакет
			if packet.get_string_from_utf8() == "register": # Запрос на регистрацию
				print("Зарегистрирован новый адрес: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
				if peer not in peers: peers.append(peer)
		# Рассылка полученных сообщений всем зарегистрированным адресам
		for p in peers:
			var packet = p.get_packet()
			if packet:
				print_debug("Адрес отправки: %s:%s\nПринятое сообщение: %s" % [
					p.get_packet_ip(), 
					p.get_packet_port(), 
					packet.get_string_from_utf8()
				])
				for i in peers:
					i.put_packet(packet)

## Остановка сервера
func stop():
	if online:
		server.stop()
		online = false


func _exit_tree():
	stop()
