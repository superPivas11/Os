# /lib/stat.be  —  команда для просмотра статистики файла

# Проверяем аргумент
if var(arg) == nil or arg == "" then
    print("Usage: stat <file>")
    return
end

# Разрешаем путь относительно CWD (если не абсолютный)
var path = arg
if path[0] != '/' then
    path = os.cwd() + "/" + path
end

# Получаем статистику
var info = fs.stat(path)
if info == nil then
    print("stat: cannot access '" + arg + "'")
    return
end

# Выводим информацию в красивом виде
print("--- File: " + info.name + " ---")

# Размер
if info.isDir then
    print("Type: Directory")
else
    print("Type: File")
    print("Size: " + str(info.size) + " bytes")
end

# Дата (Unix timestamp)
print("Modified: " + str(info.mtime))

# Если это картинка — покажем разрешение
if info.width != nil and info.height != nil then
    print("Resolution: " + str(info.width) + " x " + str(info.height))
end
