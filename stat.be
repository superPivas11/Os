# stat.be — Скрипт получения подробной информации о файле
import string

def format_size(bytes)
  if bytes < 1024
    return string.format("%d B", bytes)
  elif bytes < 1024 * 1024
    return string.format("%.2f KB", bytes / 1024.0)
  else
    return string.format("%.2f MB", bytes / (1024.0 * 1024.0))
  end
end

def format_time(ts)
  if ts == 0
    return "Неизвестно"
  end
  # Базовая конвертация POSIX timestamp в системное время UTC
  var sec = ts % 60
  var min = (ts / 60) % 60
  var hour = (ts / 3600) % 24
  var days = ts / 86400

  # Приблизительный расчет даты (начиная с 1 января 1970)
  var z = days + 719468
  var era = z / 146097
  var doe = z - era * 146097
  var yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  var y = yoe + era * 400
  var doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  var mp = (5 * doy + 2) / 153
  var d = doy - (153 * mp + 2) / 5 + 1
  var m = mp + (mp < 10 ? 3 : -9)
  y = y + (m <= 2 ? 1 : 0)

  return string.format("%04d-%02d-%02d %02d:%02d:%02d UTC", y, m, d, hour, min, sec)
end

def main()
  # В CLI аргументы передаются через глобальную переменную arg
  var filepath = nil
  if global("arg") != nil && arg != ""
    filepath = arg
  else
    screen.print("Использование: run stat.be <путь_к_файлу>\n", screen.YELLOW)
    return
  end

  # Вызываем native API fs.stat
  var info = fs.stat(filepath)

  if info == nil
    screen.print(string.format("Ошибка: файл '%s' не найден!\n", filepath), screen.RED)
    return
  end

  screen.print("--- Информация о файле ---\n", screen.CYAN)
  screen.print(string.format(" Имя:        %s\n", info["name"]))
  
  if info["isDir"]
    screen.print(" Тип:        Директория\n", screen.GREEN)
  else
    screen.print(" Тип:        Обычный файл\n")
    screen.print(string.format(" Размер:     %d байт (%s)\n", info["size"], format_size(info["size"])))
  end

  screen.print(string.format(" Изменен:    %s\n", format_time(info["mtime"])))

  # Проверяем, удалось ли C++ модулю определить параметры изображения (JPEG/PNG)
  if info.contains("width") && info.contains("height")
    screen.print(" --- Изображение ---\n", screen.MAGENTA)
    screen.print(string.format(" Разрешение: %dx%d пикселей\n", info["width"], info["height"]))
  end
  
  screen.print("--------------------------\n", screen.CYAN)
end

main()
