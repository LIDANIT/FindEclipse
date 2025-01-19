from json import dumps
from sys import argv as sys_argv
from datetime import datetime, timedelta
from astropy.coordinates import get_body, EarthLocation, AltAz
from astropy import units as u
from astropy.time import Time
from timezonefinder import TimezoneFinder
from dateutil.tz import gettz, UTC
from math import atan


def eclipse_magnitude(ang_dist, sun_radius, moon_radius):
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


def is_eclipse(location, time):
    altaz_frame = AltAz(obstime=time, location=location)

    sun = get_body("sun", time).transform_to(altaz_frame)
    moon = get_body("moon", time).transform_to(altaz_frame)

    if sun.alt <= 0:  # Солнце под горизонтом
        return False, 0, 0, 0, 0, ""

    angular_distance = sun.separation(moon).to(u.rad).value
    sun_radius = atan(695780 / sun.distance.to(u.km).value)
    moon_radius = atan(1737.4 / moon.distance.to(u.km).value)

    magnitude = eclipse_magnitude(angular_distance, sun_radius, moon_radius)
    if magnitude[0] > 0:
        return True, magnitude[0], angular_distance, sun_radius, moon_radius, magnitude[1]

    return False, 0, angular_distance, sun_radius, moon_radius, ""


def calculate_eclipses(args):
    start_date, end_date, step_seconds, latitude, longitude = args

    tf = TimezoneFinder()
    time_zone_str = tf.timezone_at(lat=float(latitude), lng=float(longitude))
    if not time_zone_str:
        raise ValueError("Невозможно определить часовой пояс для заданных координат.")

    local_tz = gettz(time_zone_str)

    start_time = datetime.strptime(start_date, "%Y-%m-%d %H:%M:%S").replace(tzinfo=local_tz)
    end_time = datetime.strptime(end_date, "%Y-%m-%d %H:%M:%S").replace(tzinfo=local_tz)

    step = timedelta(seconds=step_seconds)
    location = EarthLocation(lat=float(latitude) * u.deg, lon=float(longitude) * u.deg)

    current_time = start_time
    eclipses = []
    in_eclipse = False
    eclipse_data = {}

    while current_time <= end_time:
        time = Time(current_time.astimezone(UTC).strftime("%Y-%m-%d %H:%M:%S"))

        eclipse, magnitude, angular_distance, sun_radius, moon_radius, eclipse_type = is_eclipse(location, time)

        if eclipse:
            if not in_eclipse:
                in_eclipse = True
                eclipse_data = {
                    "start_time": current_time.strftime("%Y-%m-%d %H:%M:%S"),
                    "end_time": None,
                    "magnitude": 0,
                    "peak_time": None,
                    "type": None
                }
            if magnitude > eclipse_data["magnitude"]:
                eclipse_data["magnitude"] = magnitude
                eclipse_data["peak_time"] = current_time.strftime("%Y-%m-%d %H:%M:%S")
                eclipse_data["type"] = eclipse_type
        elif in_eclipse:
            in_eclipse = False
            eclipse_data["end_time"] = current_time.strftime("%Y-%m-%d %H:%M:%S")
            eclipses.append(eclipse_data)

        current_time += step

    return eclipses


if __name__ == "__main__":
    if len(sys_argv) == 8:
        path, lat, lon, st_d, st_t, en_d, en_t, freq = sys_argv
    else:
        path, lat, lon, st_d, st_t, en_d, en_t, freq = ["", "55", "37", "2030/6/1", "1/1/1", "2030/6/2", "1/1/1", "100"]

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
