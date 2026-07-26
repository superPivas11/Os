# weather.be - погода по названию города через Open-Meteo (без API-ключа).
#
# Примеры:
#   weather Moscow
#   weather Vitebsk
#   weather              последний запрошенный город
#
# Как работает:
#   1) Geocoding API возвращает lat/lon для названия города.
#   2) Forecast API отдаёт current_weather по координатам.
#
# Два HTTPS-запроса подряд - тяжёлый случай для памяти (каждая TLS-сессия
# ~40-50 КБ). Поэтому координаты городов кэшируем в /home/.weather_cache:
# при повторном запросе того же города геокодинг не нужен вообще, остаётся
# один запрос вместо двух. Это и быстрее, и заметно надёжнее.

import json
import string

var CACHE = "/home/.weather_cache"

# Расшифровка WMO weather code - иначе на экране просто число
def describe(code)
  if   code == 0                 return "Yasno"
  elif code == 1 || code == 2    return "Peremen. oblachno"
  elif code == 3                 return "Pasmurno"
  elif code == 45 || code == 48  return "Tuman"
  elif code >= 51 && code <= 57  return "Morosit"
  elif code >= 61 && code <= 67  return "Dozhd"
  elif code >= 71 && code <= 77  return "Sneg"
  elif code >= 80 && code <= 82  return "Livni"
  elif code >= 85 && code <= 86  return "Snegopad"
  elif code >= 95                return "Groza"
  end
  return "?"
end

# Направление ветра в румбах
def wind_dir(deg)
  var names = ["S", "SV", "V", "UV", "U", "UZ", "Z", "SZ"]
  var idx = ((int(deg) + 22) / 45) % 8
  return names[idx]
end

def load_cache()
  var raw = fs.read(CACHE)
  if raw == nil   return {}   end
  var m = json.load(raw)
  if m == nil     return {}   end
  return m
end

def save_cache(c)
  fs.write(CACHE, json.dump(c))
end

# Координаты города: сперва из кэша, иначе через геокодинг.
def locate(city)
  var key   = string.tolower(city)
  var cache = load_cache()

  var hit = cache.find(key)
  if hit != nil
    return hit
  end

  screen.print("Locating...\n", screen.CYAN)
  var raw = http.get(
    "https://geocoding-api.open-meteo.com/v1/search?name=" +
    http.encode(city) + "&count=1")
  if raw == nil
    return nil
  end

  var geo = json.load(raw)
  if geo == nil || geo.find("results") == nil
    screen.print("City not found\n", screen.RED)
    return nil
  end

  var results = geo["results"]
  if size(results) == 0
    screen.print("City not found\n", screen.RED)
    return nil
  end

  var p = results[0]
  var place = {
    "lat":  p["latitude"],
    "lon":  p["longitude"],
    "name": p["name"],
    "cc":   p.find("country", "")
  }

  cache[key] = place
  save_cache(cache)
  return place
end

def main()
  var city = arg

  # Без аргумента - последний запрошенный город
  if city == nil || city == ""
    city = nvs.get("weather_last", "")
    if city == ""
      screen.print("Usage: weather <city>\n", screen.RED)
      return
    end
  end

  if !wifi.connected()
    screen.print("Not connected\n", screen.RED)
    return
  end

  var place = locate(city)
  if place == nil
    screen.print("Geocode failed\n", screen.RED)
    return
  end

  screen.print("Fetching wx...\n", screen.CYAN)
  var url = "https://api.open-meteo.com/v1/forecast?latitude=" +
            str(place["lat"]) + "&longitude=" + str(place["lon"]) +
            "&current_weather=true"
  var raw = http.get(url)
  if raw == nil
    screen.print("Weather failed\n", screen.RED)
    return
  end

  var wx = json.load(raw)
  if wx == nil || wx.find("current_weather") == nil
    screen.print("Bad weather data\n", screen.RED)
    return
  end
  var cw = wx["current_weather"]

  # Запомним город для запуска без аргумента
  nvs.set("weather_last", city)

  screen.clear()
  screen.print(place["name"], screen.CYAN)
  if place["cc"] != ""
    screen.print(", ")
    screen.print(place["cc"], screen.CYAN)
  end
  screen.print("\n----------\n")

  screen.print("Temp: ", screen.YELLOW)
  screen.print(str(cw["temperature"]) + " C\n", screen.GREEN)

  var wc = cw.find("weathercode", -1)
  if wc >= 0
    screen.print(describe(wc) + "\n", screen.MAGENTA)
  end

  screen.print("Veter: ", screen.YELLOW)
  screen.print(str(cw["windspeed"]) + " km/h ", screen.GREEN)
  var wd = cw.find("winddirection", -1)
  if wd >= 0
    screen.print(wind_dir(wd) + "\n", screen.CYAN)
  else
    screen.print("\n")
  end

  if cw.find("time") != nil
    screen.print(cw["time"] + "\n", screen.WHITE)
  end
end

main()
