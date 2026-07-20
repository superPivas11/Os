# /lib/stat.be - команда для просмотра статистики файла

if var(arg) == nil or arg == "" then
    print("Usage: stat <file>")
    return
end

var path = arg
if path[0] != '/' then
    path = os.cwd() + "/" + path
end

var info = fs.stat(path)
if info == nil then
    print("stat: cannot access '" + arg + "'")
    return
end

print("--- File: " + info.name + " ---")

if info.isDir then
    print("Type: Directory")
else
    print("Type: File")
    print("Size: " + str(info.size) + " bytes")
end

print("Modified: " + str(info.mtime))

if info.width != nil and info.height != nil then
    print("Resolution: " + str(info.width) + " x " + str(info.height))
end
