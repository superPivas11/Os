# sysmon.be - компактное состояние ESP32, памяти и сети.

def human_kb(bytes)
  return str(bytes / 1024) + " KB"
end

def main()
  var ms = os.uptime()
  var sec = ms / 1000

  screen.clear()
  screen.print("SYSTEM MONITOR\n", screen.CYAN)
  screen.print("--------------\n", screen.CYAN)
  screen.print("Uptime: ", screen.YELLOW)
  screen.print(str(sec / 3600) + "h " + str((sec % 3600) / 60) + "m\n")
  screen.print("CPU:    ", screen.YELLOW)
  screen.print(str(sys.freq()) + " MHz\n", screen.GREEN)
  screen.print("Temp:   ", screen.YELLOW)
  screen.print(str(int(sys.temp())) + " C\n", screen.GREEN)
  screen.print("Heap:   ", screen.YELLOW)
  screen.print(human_kb(os.heap_free()) + " free\n", screen.GREEN)
  screen.print("PSRAM:  ", screen.YELLOW)
  screen.print(human_kb(os.psram_free()) + " free\n", screen.GREEN)

  if wifi.connected()
    screen.print("Wi-Fi:  ", screen.YELLOW)
    screen.print(wifi.ssid() + "\n", screen.GREEN)
    screen.print("IP:     " + wifi.ip() + "\n", screen.CYAN)
    screen.print("RSSI:   " + str(wifi.rssi()) + " dBm\n")
  else
    screen.print("Wi-Fi:  offline\n", screen.RED)
  end
end

main()
