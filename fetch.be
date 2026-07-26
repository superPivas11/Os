# fetch.be - массовая установка пакетов, в стиле pacman.
#
# Примеры:
#   fetch stat              один пакет
#   fetch stat time mania   несколько за раз
#   fetch --list            что уже установлено
#
# Отличие от встроенного "pkg install": ставит несколько пакетов одной
# командой и печатает сводку.
#
# Раньше эта либа сама собирала URL и качала только "<имя>.be" - поэтому
# архивы с играми через неё не ставились, а при сбое сети не было повтора.
# Теперь она зовёт pkg.install, который умеет и .tar, и повторы.

import string

def print_installed()
  var items = fs.list("/lib")
  if items == nil || size(items) == 0
    screen.print("No packages installed\n", screen.YELLOW)
    return
  end

  screen.print(":: ", screen.BLUE)
  screen.print("Installed\n", screen.WHITE)

  var total = 0
  var count = 0
  for it : items
    screen.print(" ", screen.WHITE)
    if it["isDir"]
      # Каталог - это многофайловый пакет
      screen.print(it["name"] + "/\n", screen.MAGENTA)
    else
      screen.print(it["name"], screen.GREEN)
      screen.print(" " + str(it["size"]) + "B\n", screen.CYAN)
      total = total + it["size"]
    end
    count = count + 1
  end

  screen.print("Total: ", screen.YELLOW)
  screen.print(str(count) + " items, " + str(total) + " B\n", screen.WHITE)
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
    screen.print("No Wi-Fi\n", screen.RED)
    return
  end

  if pkg.registry() == nil
    screen.print("Registry not set:\n", screen.RED)
    screen.print("pkg registry <url>\n", screen.YELLOW)
    return
  end

  var names = string.split(arg, " ")

  # string.split на "a  b" даёт пустые элементы - выкидываем их
  var clean = []
  for n : names
    if size(n) > 0
      clean.push(n)
    end
  end
  names = clean

  if size(names) == 0
    screen.print("Nothing to do\n", screen.YELLOW)
    return
  end

  var ok     = 0
  var failed = []
  var idx    = 0

  for name : names
    idx = idx + 1

    # Счётчик "(2/5) имя" как в pacman
    screen.print("(" + str(idx) + "/" + str(size(names)) + ") ", screen.MAGENTA)
    screen.print(name + "\n", screen.CYAN)

    # pkg.install сам разберётся: архив это или одиночный скрипт,
    # и сам повторит попытку при сбое сети.
    if pkg.install(name)
      ok = ok + 1
    else
      failed.push(name)
    end
  end

  screen.print(":: ", screen.BLUE)
  if size(failed) == 0
    screen.print("All " + str(ok) + " installed\n", screen.GREEN)
  else
    screen.print(str(ok) + " ok, " + str(size(failed)) + " failed\n", screen.YELLOW)
    for f : failed
      screen.print("  ! " + f + "\n", screen.RED)
    end
  end
end

main()
