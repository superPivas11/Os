# todo.be - простой список дел в /home/todo.txt.
# todo add buy milk | todo list | todo done 2 | todo clear

import string

var FILE = "/home/todo.txt"

def load_items()
  var items = fs.lines(FILE)
  if items == nil   return []   end
  return items
end

def show()
  var items = load_items()
  screen.print("TODO (" + str(size(items)) + ")\n", screen.CYAN)
  if size(items) == 0
    screen.print("  nothing here\n", screen.GREEN)
    return
  end
  var i = 0
  for item : items
    i = i + 1
    screen.print(str(i) + ". ", screen.YELLOW)
    screen.print(item + "\n")
  end
end

def add(parts)
  if size(parts) < 2
    screen.print("Usage: todo add <text>\n", screen.RED)
    return
  end
  var text = parts[1]
  var i = 2
  while i < size(parts)
    if parts[i] != ""   text = text + " " + parts[i]   end
    i = i + 1
  end
  if text == ""   return   end
  if fs.append(FILE, text + "\n")
    screen.print("Added: " + text + "\n", screen.GREEN)
  else
    screen.print("Cannot write todo file\n", screen.RED)
  end
end

def done(parts)
  if size(parts) < 2
    screen.print("Usage: todo done <number>\n", screen.RED)
    return
  end
  var target = int(parts[1]) - 1
  var items = load_items()
  if target < 0 || target >= size(items)
    screen.print("No such item\n", screen.RED)
    return
  end

  var out = ""
  var i = 0
  for item : items
    if i != target   out = out + item + "\n"   end
    i = i + 1
  end
  fs.write(FILE, out)
  screen.print("Done: " + items[target] + "\n", screen.GREEN)
end

def main()
  var parts = string.split(arg, " ")
  if arg == "" || arg == "list" || arg == "-l"
    show()
  elif parts[0] == "add"
    add(parts)
  elif parts[0] == "done" || parts[0] == "rm"
    done(parts)
  elif parts[0] == "clear"
    fs.write(FILE, "")
    screen.print("TODO cleared\n", screen.YELLOW)
  else
    screen.print("todo: add/list/done/clear\n", screen.YELLOW)
  end
end

main()
