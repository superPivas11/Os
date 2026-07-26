# diag.be - hardware acceptance test for the assembled ESP32-S3 terminal.
#   diag           automatic checks without changing user files
#   diag --visual  display color/geometry test and wait for a keyboard key

var failures = 0
var warnings = 0

def result(name, ok, detail)
  var color = ok ? screen.GREEN : screen.RED
  var mark = ok ? "OK   " : "FAIL "
  screen.print(mark, color)
  screen.print(name, screen.WHITE)
  if detail != ""   screen.print("  " + detail, screen.CYAN)   end
  screen.print("\n", screen.WHITE)
  if !ok   failures = failures + 1   end
end

def warning(name, detail)
  warnings = warnings + 1
  screen.print("WARN " + name + "  " + detail + "\n", screen.YELLOW)
end

def mb(value)
  return str(value / (1024 * 1024)) + " MB"
end

def automatic_test()
  screen.clear()
  screen.print("HARDWARE SELFTEST\n", screen.CYAN)
  screen.print("-----------------\n", screen.CYAN)
  var info = sys.info()

  result("chip", info["chip"] == "ESP32-S3",
         info["chip"] + " rev " + str(info["revision"]) + " / " + str(info["cores"]) + " cores")
  result("CPU", info["cpu_mhz"] >= 240, str(info["cpu_mhz"]) + " MHz")
  result("flash N16", info["flash_bytes"] >= 16 * 1024 * 1024, mb(info["flash_bytes"]))
  result("PSRAM R8", info["psram_bytes"] >= 8 * 1024 * 1024,
         mb(info["psram_bytes"]) + " / free " + mb(info["psram_free"]))
  result("heap", info["heap_free"] >= 32 * 1024,
         str(info["heap_free"] / 1024) + " KB free")
  result("SD mount", info["sd_total_mb"] > 0, str(info["sd_total_mb"]) + " MB")

  var path = "/tmp/.mini-os-selftest"
  var pattern = "S3-OS stream test 0123456789"
  var out = fs.open(path, "w")
  var wrote = out != nil && fs.write_chunk(out, pattern) == size(pattern)
  if out != nil   fs.close(out)   end
  var input_file = wrote ? fs.open(path, "r") : nil
  var read_ok = false
  if input_file != nil
    var data = fs.read_chunk(input_file, 128)
    read_ok = data.asstring() == pattern
    fs.close(input_file)
  end
  fs.remove(path)
  var stream_ok = wrote && read_ok
  var stream_detail = str(size(pattern)) + " bytes"
  result("SD stream R/W", stream_ok, stream_detail)

  if wifi.connected()
    result("Wi-Fi", true, wifi.ssid() + " " + wifi.ip())
  else
    warning("Wi-Fi", "offline; connect before network acceptance")
  end

  screen.print("-----------------\n", screen.CYAN)
  if failures == 0
    screen.print("AUTOMATIC PASS", screen.GREEN)
  else
    screen.print("FAILED: " + str(failures), screen.RED)
  end
  screen.print("  warnings: " + str(warnings) + "\n", screen.YELLOW)
  screen.print("Run: diag --visual\n", screen.WHITE)
end

def visual_test()
  gfx.begin()
  input.begin()
  gfx.clear(gfx.BLACK)
  var colors = [gfx.RED, gfx.GREEN, gfx.BLUE, gfx.WHITE, gfx.BLACK]
  for i : 0 .. 4
    gfx.fillrect(i * 32, 0, 32, 92, colors[i])
    gfx.rect(i * 32, 0, 32, 92, gfx.WHITE)
  end
  gfx.rect(0, 0, gfx.W, gfx.H, gfx.YELLOW)
  gfx.line(0, 92, gfx.W - 1, gfx.H - 1, gfx.CYAN)
  gfx.line(gfx.W - 1, 92, 0, gfx.H - 1, gfx.MAGENTA)
  gfx.text(8, 98, "DISPLAY + KEYBOARD", gfx.WHITE, 1, gfx.BLACK)
  gfx.text(17, 112, "PRESS ANY KEY", gfx.YELLOW, 1, gfx.BLACK)
  gfx.flush()
  var event = input.wait()
  input.close()
  gfx.close()
  screen.clear()
  if event != nil
    screen.print("Keyboard event OK: HID " + str(event["key"]) + "\n", screen.GREEN)
  else
    screen.print("Keyboard event missing\n", screen.RED)
  end
end

if arg == "--visual"
  visual_test()
else
  automatic_test()
end
