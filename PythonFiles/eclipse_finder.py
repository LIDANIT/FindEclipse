# Библиотеки для работы с системой
import os
from sys import argv as sys_argv
import sys
# Библиотеки для работы с многопроцессорностью и многопоточностью
import multiprocessing
import multiprocessing.popen_spawn_win32
from threading import Thread
# Библиотеки для работы со временем
import time
from timezonefinder import TimezoneFinder
from dateutil.tz import gettz, UTC
from datetime import datetime, timedelta
# Работа с сокетами
import socket
# Библиотеки для работы с космическими телами
from ephem import Sun, Moon, separation, Observer, degrees

from astropy.coordinates import get_body, EarthLocation, AltAz
from astropy import units as u
from astropy.time import Time
# Дополнительные библиотеки
from json import dumps
from math import atan


HOST = "127.0.0.1"  # Хост сервера
PORT = 4242  # Порт сервера
global_terminate = False  # Глобальная переменная для остановки "быстрого поиска"


# Класс для работы с многопроцессорностью внутри exe-файла
class _Popen(multiprocessing.popen_spawn_win32.Popen):
    def __init__(self, *args, **kw):
        if hasattr(sys, 'frozen'):
            os.putenv('_MEIPASS2', sys._MEIPASS)
        try:
            super(_Popen, self).__init__(*args, **kw)
        finally:
            if hasattr(sys, 'frozen'):
                if hasattr(os, 'unsetenv'):
                    os.unsetenv('_MEIPASS2')
                else:
                    os.putenv('_MEIPASS2', '')


# Оболочка для процесса
class Process(multiprocessing.Process):
    _Popen = _Popen


# Класс прогресс-бара
class ProgressObserver:

    def __init__(self):
        self.receive_thread = None
        self.s = None
        self.terminate_var = None
        self.last_percent = 0
        self.value = 0
        self.total = 0
        self.server_address = (HOST, PORT)
        self.running = False

    # Создание прогресс-бара
    def start(self, type: str, total: int, terminate_var=None) -> bool:
        self.terminate_var = terminate_var
        self.total = total
        # Подключение к серверу
        self.s = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
        self.s.sendto("register".encode(), self.server_address)  # Отправка регистрационного сообщения
        # Запуск слушателя
        self.running = True
        self.receive_thread = Thread(target=self._receive_loop, daemon=True)
        self.receive_thread.start()
        # Отправка сообщения с типом прогресс-бара
        if type == "fast":
            self.s.sendto(str("fast").encode(), self.server_address)
        elif type == "accurate":
            self.s.sendto(str("accurate").encode(), self.server_address)
        else:
            return False
        return True

    # Слушатель
    def _receive_loop(self) -> None:
        global global_terminate
        while self.running:
            try:
                data, addr = self.s.recvfrom(1024)  # Получение данных с сервера
                message = data.decode().strip().lower()

                # Прерывание расчёта в случае намеренной остановки
                if message == 'close':
                    self.close()
                    global_terminate = True
                    if not (self.terminate_var is None):
                        self.terminate_var.value = 1
                    break
            except (OSError, ConnectionResetError) as e:
                self.running = False
                break

    # Отправка сообщений на сервер
    def _broadcast_msg(self, msg):
        self.s.sendto(str(msg).encode(), self.server_address)

    # Обновление прогресс-бара
    def update(self) -> bool:
        global global_terminate
        self.value += 1
        # Во избежание ошибки деления на 0
        if self.total == 0:
            return False
        # Обновление данных на сервере
        if int(100 * self.value / self.total) > self.last_percent:
            self.last_percent = int(100 * self.value / self.total)
            self._broadcast_msg(self.last_percent)
            time.sleep(0.1)
        # Прекращение работы прогресс-бара
        if self.value >= self.total or self.last_percent == 100:
            self.close()
        return True

    # Прекращение работы прогресс-бара (отключение слушателя, отсоединение клиента)
    def close(self):
        self.running = False
        self.value = 0
        self.total = 0
        self.last_percent = 0
        self.s.close()


# Определение фазы и типа затмения
def eclipse_magnitude(ang_dist, sun_radius, moon_radius) -> tuple:
    R1 = sun_radius
    R2 = moon_radius
    D = ang_dist
    R_sum = R1 + R2
    R_diff = abs(R1 - R2)

    if D >= R_sum:
        return 0, ""

    if R_diff < D <= R_sum:
        return (R_sum - D) / (2 * R1), "Частное"

    if D <= R_diff:
        if R1 > R2:
            return R2 / R1, "Кольцеобразное"
        else:
            return R2 / R1, "Полное"


# Функция для проверки затмения в PyEphem
def is_eclipse_low(observer) -> bool:
    sun = Sun(observer)
    moon = Moon(observer)

    # Угловое расстояние Солнце - Луна
    angular_distance = separation(sun, moon)

    # Угловые радиусы
    sun_radius = sun.size / 2 / 3600
    moon_radius = moon.size / 2 / 3600

    if angular_distance <= sun_radius + moon_radius:
        return True
    return False


# Определение затмения в Astropy
def is_eclipse(location, time) -> tuple:
    # Небо в данное время в этом месте
    altaz_frame = AltAz(obstime=time, location=location)

    # Объекты Солнце и Луна
    sun = get_body("sun", time).transform_to(altaz_frame)
    moon = get_body("moon", time).transform_to(altaz_frame)

    if sun.alt <= 0:  # Солнце под горизонтом
        return False, 0, ""

    # Усгловое расстояние Солнца - Луна
    angular_distance = sun.separation(moon).to(u.rad).value
    # Угловые радиусы
    sun_radius = atan(695780 / sun.distance.to(u.km).value)
    moon_radius = atan(1737.4 / moon.distance.to(u.km).value)

    magnitude = eclipse_magnitude(angular_distance, sun_radius, moon_radius)  # Фаза затмения

    if magnitude[0] > 0:  # Затмение есть
        return True, magnitude[0], magnitude[1]

    return False, 0, ""


# Функция расчёта затмений с помощью PyEphem
def calculate_eclipses_low(args) -> list:
    global global_terminate
    # Стартовая дата/конечная дата/интервал времени/широта/долгота
    start_date, end_date, step_seconds, latitude, longitude = args

    # Объект для смены часовых поясов
    tf = TimezoneFinder()
    time_zone_str = tf.timezone_at(lat=float(latitude), lng=float(longitude))  # Часовая зона
    from_zone = gettz(time_zone_str)
    # Начало поиска в UTC
    start_time = datetime.strptime(start_date, "%Y-%m-%d %H:%M:%S")
    start_time = start_time.replace(tzinfo=from_zone)
    start_time = start_time.astimezone(tz=gettz("UTC"))
    # Конец поиска в UTC
    end_time = datetime.strptime(end_date, "%Y-%m-%d %H:%M:%S")
    end_time = end_time.replace(tzinfo=from_zone)
    end_time = end_time.astimezone(tz=gettz("UTC"))

    delta = timedelta(seconds=step_seconds)  # Интервал времени
    # Наблюдатель и его местоположение
    observer = Observer()
    observer.lat = degrees(latitude)
    observer.lon = degrees(longitude)

    # Переменные для отслеживания текущего затмения
    in_eclipse = False
    eclipse_data = []
    eclipses = []
    # Переопределение перехода между часовыми поясами
    from_zone = gettz("UTC")
    to_zone = gettz(time_zone_str)

    current_time = start_time
    total = (end_time - start_time) // timedelta(seconds=step_seconds)  # Всего итераций
    # Прогресс-бар
    progress = ProgressObserver()
    progress.start("fast", total)

    while current_time <= end_time:
        if global_terminate:  # Остановка программы
            return eclipses
        observer.date = current_time.strftime("%Y-%m-%d %H:%M:%S")  # Установка даты наблюдения
        # Определение Мирового и Местного времени
        utc_time = current_time.replace(tzinfo=from_zone)
        local_time = utc_time.astimezone(to_zone)

        # Видно ли Солнце
        sun = Sun(observer)
        if sun.alt <= 0:  # Солнце под землёй
            if in_eclipse:  # Окончание затмения, если оно продолжается
                in_eclipse = False
                eclipse_data.append(local_time)
                eclipses.append(tuple(eclipse_data))
                eclipse_data = []
            current_time += delta
            progress.update()
            continue
        # Есть ли затмение
        eclipse = is_eclipse_low(observer)

        if eclipse:
            if not in_eclipse:  # Начало нового затмения
                in_eclipse = True
                eclipse_data.append(local_time)
        elif in_eclipse:  # Окончание затмения
            in_eclipse = False
            eclipse_data.append(local_time)
            eclipses.append(tuple(eclipse_data))
            eclipse_data = []

        current_time += delta
        progress.update()

    progress.close()
    return eclipses


# Поиск затмений с помощью Astropy
def calculate_eclipses(args, val, terminate) -> list:
    # Стартовая дата/конечная дата/интервал времени/широта/долгота
    start_time, end_time, step_seconds, latitude, longitude = args

    step = timedelta(seconds=step_seconds)  # Интервал времени
    location = EarthLocation(lat=float(latitude) * u.deg, lon=float(longitude) * u.deg)  # Местоположение

    current_time = start_time
    # Вспомогательные переменные
    eclipses = []
    in_eclipse = False
    eclipse_data = {}

    while current_time <= end_time:
        if terminate.value:  # Остановка программы
            return eclipses
        time = Time(current_time.astimezone(UTC).strftime("%Y-%m-%d %H:%M:%S"))  # Установка времени
        # Определение наличия затмения
        eclipse, magnitude, eclipse_type = is_eclipse(location, time)

        if eclipse:
            if not in_eclipse:  # Начало затмения
                in_eclipse = True
                eclipse_data = {
                    "start_time": current_time.strftime("%Y-%m-%d %H:%M:%S"),
                    "end_time": None,
                    "magnitude": 0,
                    "peak_time": None,
                    "type": None
                }
            if magnitude > eclipse_data["magnitude"]:  # Обновление максимальной фазы
                eclipse_data["magnitude"] = magnitude
                eclipse_data["peak_time"] = current_time.strftime("%Y-%m-%d %H:%M:%S")
                eclipse_data["type"] = eclipse_type
        elif in_eclipse:  # Конец затмения
            in_eclipse = False
            eclipse_data["end_time"] = current_time.strftime("%Y-%m-%d %H:%M:%S")
            eclipses.append(eclipse_data)

        current_time += step
        val.value += 1

    return eclipses


# Запуск "точного поиска" многопроцессорно
def calculate(procnum, val, queue, return_dict, terminate):
    if queue.empty():  # Очередь пуста
        return_dict[procnum] = []
        return

    ans = []
    while not queue.empty() or terminate.value:
        eclipse = queue.get()
        start_time = eclipse[0][0]
        end_time = eclipse[0][1]
        latitude = eclipse[1]
        longitude = eclipse[2]
        # Поиск затмения
        founded_eclipses = calculate_eclipses([start_time, end_time, 25, latitude, longitude], val, terminate)
        ans += founded_eclipses
        if terminate.value:  # Прерывание расчётов
            return_dict[procnum] = []
            return

    return_dict[procnum] = ans


# Главная функция
def main():
    global global_terminate  # Прерывание на этапе "быстрого поиска"
    # Получение параметров:
    # путь/широта/долгота/начальная дата/начальное время/конечная дата/конечное время/интервал времени
    if len(sys_argv) == 8:
        path, lat, lon, st_d, st_t, en_d, en_t, freq = sys_argv
    else:
        path, lat, lon, st_d, st_t, en_d, en_t, freq = ["", "55", "37", "0001/3/20", "1/1/1", "0002/3/30", "1/1/1",
                                                        "100"]

    # Обработка полученных значений
    latitude = lat
    longitude = lon

    start_date = '-'.join(st_d.split('/')) + ' ' + ':'.join(st_t.split('/'))
    end_date = '-'.join(en_d.split('/')) + ' ' + ':'.join(en_t.split('/'))
    step_seconds = int(freq)
    # Запуск быстрого поиска
    eclipses_low = calculate_eclipses_low([start_date, end_date, step_seconds, latitude, longitude])

    if len(eclipses_low) == 0 or global_terminate:  # Прерывание или не найдено "быстрым поиском"
        print("End: {}")
        return -1

    # Подсчёт количества итераций для "точного поиска"
    total = 0
    for i in eclipses_low:
        total += (i[1] - i[0]) / timedelta(seconds=25)
    total = int(total)

    # Очередь для многопроцессорной обработки
    queue = multiprocessing.Queue(total)
    for i in range(len(eclipses_low)):
        queue.put([eclipses_low[i], latitude, longitude])

    value = multiprocessing.Value('i', 0)  # Значение прогресс-бара для "точного поиска"
    terminate = multiprocessing.Value('i', 0)  # Прерывание на этапе "точного поиска"
    result_manager = multiprocessing.Manager()
    return_dict = result_manager.dict()  # Словарь полученных данных
    # Запуск процессов
    for i in range(os.cpu_count() - 1):
        proc = Process(target=calculate, args=(i, value, queue, return_dict, terminate,))
        proc.start()

    last = 0
    last_time = time.time()
    # Создание прогресс-бара
    progress = ProgressObserver()
    progress.start("accurate", total, terminate)
    # Обновление прогресс-бара
    while value.value < total and last < total:
        if value.value > last:
            last += 1
            progress.update()
            last_time = time.time()
        elif time.time() - last_time > 5:
            progress.update()
            last += 1
    progress.close()  # Выключение прогресс-бара

    # Формирование итогового словаря данных
    eclipses = []
    for eclipse in return_dict.values():
        eclipses.extend(eclipse)

    # Преобразование ответа в json-строку для передачи в интерфейс
    ans = {}
    for i in eclipses:
        ans[i["peak_time"]] = i
    print("End: " + dumps(ans))
    return 0


if __name__ == "__main__":
    multiprocessing.freeze_support()  # Корректная инициализация многопроцессорности при упаковке в exe
    main()  # Запуск основной функции
