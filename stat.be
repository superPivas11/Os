# stat.be - подробная информация о файле или каталоге.
#
# Примеры:
#   stat photo.jpg
#   stat /etc/wifi.conf
#   stat /lib
#
# Показывает: имя, тип, размер (с человекочитаемыми единицами), дату
# изменения, а для картинок - разрешение и мегапиксели.

# Человекочитаемый размер: 1536 -> "1.5 KB"
def human(bytes)
  if bytes < 1024
    return str(bytes) + " B"
  end
  if bytes < 1024 * 1024
    var kb = bytes / 1024
    var frac = (bytes % 1024) * 10 / 1024
    return str(kb) + "." + str(frac) + " KB"
  end
  var mb = bytes / (1024 * 1024)
  var mfrac = (bytes % (1024 * 1024)) * 10 / (1024 * 1024)
  return str(mb) + "." + str(mfrac) + " MB"
end

# Строка "ключ: значение" с выравниванием ключа
def row(key, value, color)
  screen.print(key, screen.YELLOW)
  screen.print(value, color)
  screen.print("\n")
end

def main()
  if arg == nil || arg == ""
    screen.print("Usage: stat <file>\n", screen.RED)
    return
  end

  # Относительный путь разрешаем от текущего каталога
  var path = arg
  if path[0] != "/"
    var base = os.cwd()
    if base == "/"
      path = "/" + arg
    else
      path = base + "/" + arg
    end
  end

  var info = fs.stat(path)
  if info == nil
    screen.print("stat: no such file\n", screen.RED)
    screen.print(path, screen.RED)
    screen.print("\n")
    return
  end

  screen.print("--- ", screen.CYAN)
  screen.print(info["name"], screen.WHITE)
  screen.print(" ---\n", screen.CYAN)

  if info["isDir"]
    row("Type:  ", "Directory", screen.MAGENTA)
    # Для каталога считаем содержимое
    var items = fs.list(path)
    if items != nil
      var files = 0
      var dirs  = 0
      var total = 0
      for it : items
        if it["isDir"]
          dirs = dirs + 1
        else
          files = files + 1
          total = total + it["size"]
        end
      end
      row("Files: ", str(files), screen.GREEN)
      row("Dirs:  ", str(dirs), screen.GREEN)
      row("Total: ", human(total), screen.GREEN)
    end
  else
    row("Type:  ", info["format"], screen.MAGENTA)
    row("Size:  ", human(info["size"]), screen.GREEN)

    # Разрешение есть только у распознанных картинок
    if info.find("width") != nil
      var w = info["width"]
      var h = info["height"]
      row("Res:   ", str(w) + "x" + str(h), screen.CYAN)

      # Мегапиксели с одним знаком после запятой
      var px = w * h
      var mp = px / 100000
      row("Pixels:", str(mp / 10) + "." + str(mp % 10) + " MP", screen.CYAN)

      # Влезет ли на наш экран 160x128 без масштабирования
      if w <= 160 && h <= 128
        row("Fits:  ", "yes (1:1)", screen.GREEN)
      else
        # Во сколько раз надо ужать
        var sw = (w + 159) / 160
        var sh = (h + 127) / 128
        var s = sw
        if sh > s
          s = sh
        end
        row("Scale: ", "1/" + str(s), screen.YELLOW)
      end
    end
  end

  row("Path:  ", info["path"], screen.WHITE)

  # Дата: os.date вернёт "unknown" пока NTP не отработал
  var d = os.date(info["mtime"])
  row("Date:  ", d, screen.WHITE)
end

main()
