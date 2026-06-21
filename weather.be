# weather.be - погода по названию города через Open-Meteo (без API-ключа).
# Пример:  weather Moscow
#          weather Vitebsk
#          weather Polotsk
#
# Как работает:
#   1) Geocoding API возвращает lat/lon для названия города.
#   2) Forecast API отдаёт current_weather (температура, ветер, код погоды).

import json

def main()
  if arg == nil || arg == ""
    screen.print("Usage: weather <city>\n", screen.RED)
    return
  end
  if !wifi.connected()
    screen.print("Not connected\n", screen.RED)
    return
  end

  # 1. Геокодинг
  screen.print("Locating...\n", screen.CYAN)
  var geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + arg + "&count=1"
  var raw = http.get(geoUrl)
  if raw == nil
    screen.print("Geocode failed\n", screen.RED)
    return
  end
  var geo = json.load(raw)
  if geo == nil || geo.find("results") == nil
    screen.print("City not found\n", screen.RED)
    return
  end
  var results = geo["results"]
  if size(results) == 0
    screen.print("City not found\n", screen.RED)
    return
  end
  var place   = results[0]
  var lat     = place["latitude"]
  var lon     = place["longitude"]
  var name    = place["name"]
  var country = place.find("country", "?")

  # 2. Текущая погода
  screen.print("Fetching wx...\n", screen.CYAN)
  var wxUrl = "https://api.open-meteo.com/v1/forecast?latitude=" +
              str(lat) + "&longitude=" + str(lon) + "&current_weather=true"
  var wxRaw = http.get(wxUrl)
  if wxRaw == nil
    screen.print("Weather failed\n", screen.RED)
    return
  end
  var wx = json.load(wxRaw)
  if wx == nil || wx.find("current_weather") == nil
    screen.print("Bad weather data\n", screen.RED)
    return
  end
  var cw = wx["current_weather"]

  # 3. Вывод
  screen.clear()
  screen.print(name, screen.CYAN)
  screen.print(", ")
  screen.print(country, screen.CYAN)
  screen.print("\n--------\n")

  screen.print("Temp:  ", screen.YELLOW)
  screen.print(str(cw["temperature"]), screen.GREEN)
  screen.print(" C\n")

  screen.print("Wind:  ", screen.YELLOW)
  screen.print(str(cw["windspeed"]), screen.GREEN)
  screen.print(" km/h\n")

  screen.print("Dir:   ", screen.YELLOW)
  screen.print(str(cw["winddirection"]), screen.GREEN)
  screen.print(" deg\n")

  screen.print("Code:  ", screen.YELLOW)
  screen.print(str(cw["weathercode"]), screen.GREEN)
  screen.print("\n")

  if cw.find("time") != nil
    screen.print("Time:  ", screen.YELLOW)
    screen.print(cw["time"], screen.MAGENTA)
    screen.print("\n")
  end
end

main()
