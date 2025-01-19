from json import dumps
from sys import argv as sys_argv
from ephem import Sun, Moon, separation, Observer, degrees
from datetime import datetime, timedelta
from dateutil.tz import gettz
from timezonefinder import TimezoneFinder


# Функция для расчёта процента покрытия
def eclipse_magnitude(ang_dist, sun_radius, moon_radius):
    R1 = sun_radius
    R2 = moon_radius
    D = ang_dist
    R_sum = R1 + R2
    R_diff = abs(R1 - R2)

    # Если не пересекаются
    if D >= R1 + R2:
        return 0, ""

    if R_diff < D <= R_sum:
        return (R_sum - D) / (2 * R1), "Частное"

    if D <= R_diff:
        if R1 > R2:
            return R2 / R1, "Кольцеобразное"
        else:
            return R2 / R1, "Полное"


# Функция для проверки затмения
def is_eclipse(observer):
    sun = Sun(observer)
    moon = Moon(observer)

    # Угловое расстояние Солнце - Луна
    angular_distance = separation(sun, moon)

    # Угловые радиусы
    sun_radius = sun.size / 2 / 3600
    moon_radius = moon.size / 2 / 3600

    # Есть ли затмение
    magnitude = eclipse_magnitude(angular_distance, sun_radius, moon_radius)

    if magnitude[0] > 0:
        return True, magnitude[0], angular_distance, sun_radius, moon_radius, magnitude[1]

    return False, 0, angular_distance, sun_radius, moon_radius, magnitude[1]


# Функция расчёта затмений
def calculate_eclipses(args):
    start_date, end_date, step_seconds, latitude, longitude = args

    tf = TimezoneFinder()
    time_zone_str = tf.timezone_at(lat=float(latitude), lng=float(longitude))
    from_zone = gettz(time_zone_str)

    start_time = datetime.strptime(start_date, "%Y-%m-%d %H:%M:%S")
    start_time = start_time.replace(tzinfo=from_zone)
    start_time = start_time.astimezone(tz=gettz("UTC"))

    end_time = datetime.strptime(end_date, "%Y-%m-%d %H:%M:%S")
    end_time = end_time.replace(tzinfo=from_zone)
    end_time = end_time.astimezone(tz=gettz("UTC"))

    delta = timedelta(seconds=step_seconds)

    observer = Observer()  # Наблюдатель
    observer.lat = degrees(latitude)
    observer.lon = degrees(longitude)

    # Переменные для отслеживания текущего затмения
    in_eclipse = False
    eclipse_data = {}
    eclipses = []

    from_zone = gettz("UTC")
    to_zone = gettz(time_zone_str)

    # Цикл по времени
    current_time = start_time
    while current_time <= end_time:
        observer.date = current_time.strftime("%Y-%m-%d %H:%M:%S")

        utc_time = current_time.replace(tzinfo=from_zone)
        local_time = utc_time.astimezone(to_zone)

        # Видимо ли Солнце
        sun = Sun(observer)
        if sun.alt <= 0:  # Солнце под землёй
            if in_eclipse:
                in_eclipse = False
                eclipse_data["end_time"] = local_time.strftime("%Y-%m-%d %H:%M:%S")
                eclipses.append(eclipse_data)
            current_time += delta
            continue

        eclipse, magnitude, angular_distance, sun_radius, moon_radius, eclipse_type = is_eclipse(observer)

        if eclipse:
            if not in_eclipse:  # Начало нового затмения
                in_eclipse = True

                eclipse_data = {
                    "start_time": local_time.strftime("%Y-%m-%d %H:%M:%S"),
                    "end_time": "",
                    "magnitude": 0,
                    "peak_time": None,
                    "type": ""
                }

            # Обновляем данные о затмении
            if magnitude > eclipse_data["magnitude"]:
                eclipse_data["magnitude"] = magnitude
                eclipse_data["peak_time"] = local_time.strftime("%Y-%m-%d %H:%M:%S")
                eclipse_data["type"] = eclipse_type
        elif in_eclipse:  # Окончание затмения
            in_eclipse = False

            eclipse_data["end_time"] = local_time.strftime("%Y-%m-%d %H:%M:%S")
            eclipses.append(eclipse_data)

        current_time += delta

    return eclipses


if __name__ == "__main__":
    if len(sys_argv) == 8:
        path, lat, lon, st_d, st_t, en_d, en_t, freq = sys_argv
    else:
        path, lat, lon, st_d, st_t, en_d, en_t, freq = ["", "55", "37", "2025/1/1", "1/1/1", "2025/6/1", "1/1/1", "100"]
    latitude = lat
    longitude = lon
    start_date = '-'.join(st_d.split('/')) + ' ' + ':'.join(st_t.split('/'))
    end_date = '-'.join(en_d.split('/')) + ' ' + ':'.join(en_t.split('/'))
    step_seconds = int(freq)

    eclipses = calculate_eclipses([start_date, end_date, step_seconds, latitude, longitude])

    ans = {}
    for i in eclipses:
        ans[i["peak_time"]] = i
    print(dumps(ans))
