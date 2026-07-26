# time.be - текущее московское время.
#
# Примеры:
#   time            дата и время
#   time --sync     то же, но принудительно из интернета
#
# По умолчанию берёт системные часы: они синхронизируются по NTP
# автоматически через несколько секунд после подключения к Wi-Fi.
# Это мгновенно и работает даже когда интернет отвалился.
#
# Раньше эта либа КАЖДЫЙ раз лезла на timeapi.io - отсюда и было
# "работает через раз": любой сбой сети означал полный отказ.

import json
import string
import time as btime

var DAYS = ["Voskresenje", "Ponedelnik", "Vtornik", "Sreda",
            "Chetverg", "Pyatnica", "Subbota"]

# Красивый вывод из системных часов. false - часы ещё не синхронизированы.
def show_local()
  var s = os.date()
  if s == "unknown"
    return false
  end

  # os.date() отдаёт "YYYY-MM-DD HH:MM:SS"
  var parts = string.split(s, " ")
  if size(parts) < 2
    return false
  end

  screen.clear()
  screen.print("Moscow time\n", screen.CYAN)
  screen.print("-----------\n", screen.CYAN)
  screen.print(parts[1] + "\n", screen.GREEN)
  screen.print(parts[0] + "\n", screen.YELLOW)

  # День недели считаем из timestamp через встроенный time.dump
  var d = btime.dump(os.time())
  if d != nil && d.find("weekday") != nil
    var wd = d["weekday"]
    if wd >= 0 && wd < size(DAYS)
      screen.print(DAYS[wd] + "\n", screen.MAGENTA)
    end
  end
  return true
end

# Запасной путь: тянем время из интернета.
def show_remote()
  if !wifi.connected()
    screen.print("No Wi-Fi and clock not synced\n", screen.RED)
    return
  end

  screen.print("Fetching...\n", screen.CYAN)
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

  var date = data.find("date", "?")
  var t    = data.find("time", "?")
  var sec  = data.find("seconds", 0)
  var day  = data.find("dayOfWeek", "?")

  screen.clear()
  screen.print("Moscow time\n", screen.CYAN)
  screen.print("-----------\n", screen.CYAN)

  var secs = str(sec)
  if sec < 10
    secs = "0" + secs
  end
  screen.print(t + ":" + secs + "\n", screen.GREEN)
  screen.print(date + "\n", screen.YELLOW)
  screen.print(day + "\n", screen.MAGENTA)
end

def main()
  var force = (arg == "--sync" || arg == "-s")

  if !force
    if show_local()
      return
    end
    # Часы ещё не синхронизированы - предупредим и сходим в сеть
    screen.print("Clock not synced yet\n", screen.YELLOW)
  end

  show_remote()
end

main()
