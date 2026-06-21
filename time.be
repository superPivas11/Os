# time.be - точное московское время через timeapi.io.
# Пример:  time
#
# Не использует системные часы ESP - всегда тянет свежее значение из инета.
# Если хочется чаще / без интернета - надо настроить NTP через configTime()
# на C-стороне и пробросить в Berry (TODO).

import json

def main()
  if !wifi.connected()
    screen.print("Not connected\n", screen.RED)
    return
  end
  screen.print("Fetching MSK time...\n", screen.CYAN)
  var raw = http.get(
    "https://timeapi.io/api/Time/current/zone?timeZone=Europe/Moscow")
  if raw == nil
    screen.print("Request failed\n", screen.RED)
    return
  end
  var data = json.load(raw)
  if data == nil
    screen.print("Bad JSON\n", screen.RED)
    return
  end
  var date = data.find("date", "?")     # "01/15/2025"
  var t    = data.find("time", "?")     # "17:00"
  var sec  = data.find("seconds", 0)
  var day  = data.find("dayOfWeek", "?")

  screen.clear()
  screen.print("Moscow time\n", screen.CYAN)
  screen.print("------------\n", screen.CYAN)
  screen.print(date, screen.GREEN)
  screen.print(" ")
  screen.print(day, screen.YELLOW)
  screen.print("\n")
  screen.print(t, screen.GREEN)
  screen.print(":")
  if sec < 10
    screen.print("0")
  end
  screen.print(str(sec), screen.GREEN)
  screen.print("\n")
end

main()
