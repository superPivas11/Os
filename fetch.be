# fetch.be - красивая загрузка пакетов с твоего гита.
#
# Примеры:
#   fetch stat            скачать один пакет
#   fetch stat time       скачать несколько за раз
#   fetch --list          что уже установлено
#
# Отличие от встроенного "pkg install": показывает сводку в стиле pacman,
# умеет ставить несколько пакетов одной командой и считает статистику.

# Разбить строку аргументов по пробелам в список слов
def split_args(s)
  var out = []
  var cur = ""
  for i : 0 .. size(s) - 1
    var c = s[i]
    if c == " "
      if size(cur) > 0
        out.push(cur)
        cur = ""
      end
    else
      cur = cur + c
    end
  end
  if size(cur) > 0
    out.push(cur)
  end
  return out
end

def print_installed()
  var items = fs.list("/lib")
  if items == nil || size(items) == 0
    screen.print("No packages installed\n", screen.YELLOW)
    return
  end
  screen.print(":: ", screen.BLUE)
  screen.print("Installed packages\n", screen.WHITE)
  var total = 0
  for it : items
    screen.print(" ", screen.WHITE)
    screen.print(it["name"], screen.GREEN)
    screen.print(" ", screen.WHITE)
    screen.print(str(it["size"]) + "B\n", screen.CYAN)
    total = total + it["size"]
  end
  screen.print("Total: ", screen.YELLOW)
  screen.print(str(size(items)) + " pkgs, " + str(total) + " B\n", screen.WHITE)
end

def main()
  if arg == nil || arg == ""
    screen.print("Usage: fetch <pkg> [pkg2 ...]\n", screen.RED)
    screen.print("       fetch --list\n", screen.YELLOW)
    return
  end

  if arg == "--list" || arg == "-l"
    print_installed()
    return
  end

  if !wifi.connected()
    screen.print("Not connected to Wi-Fi\n", screen.RED)
    return
  end

  var reg = pkg.registry()
  if reg == nil
    screen.print("Registry not set. Use:\n", screen.RED)
    screen.print("pkg registry <url>\n", screen.YELLOW)
    return
  end

  var names = split_args(arg)
  var okCount = 0
  var failed = []

  screen.print(":: ", screen.BLUE)
  screen.print("Fetching " + str(size(names)) + " pkg(s)\n", screen.WHITE)

  var idx = 0
  for name : names
    idx = idx + 1

    # Счётчик "(2/5) имя" как в pacman
    screen.print("(" + str(idx) + "/" + str(size(names)) + ") ", screen.MAGENTA)
    screen.print(name + "\n", screen.CYAN)

    var url = reg + "/" + name + ".be"
    var dst = "/lib/" + name + ".be"

    if http.download(url, dst)
      okCount = okCount + 1
    else
      failed.push(name)
    end
  end

  # Итоговая сводка
  screen.print(":: ", screen.BLUE)
  if size(failed) == 0
    screen.print("All " + str(okCount) + " installed\n", screen.GREEN)
  else
    screen.print(str(okCount) + " ok, " + str(size(failed)) + " failed\n", screen.YELLOW)
    for f : failed
      screen.print("  ! " + f + "\n", screen.RED)
    end
  end
end

main()
