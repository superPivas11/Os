# netcheck.be - проверка URL, HTTP-кода, задержки и размера ответа.
# netcheck https://example.com

def main()
  if arg == ""
    screen.print("Usage: netcheck <url>\n", screen.RED)
    return
  end
  if !wifi.connected()
    screen.print("Wi-Fi offline\n", screen.RED)
    return
  end

  screen.print("GET " + arg + "\n", screen.CYAN)
  var started = millis()
  var body = http.get(arg)
  var elapsed = millis() - started

  screen.print("HTTP: ", screen.YELLOW)
  var code = http.code()
  if code >= 200 && code < 300
    screen.print(str(code) + "\n", screen.GREEN)
  else
    screen.print(str(code) + "\n", screen.RED)
  end
  screen.print("Time: " + str(elapsed) + " ms\n")
  if body != nil
    screen.print("Body: " + str(size(body)) + " bytes\n", screen.CYAN)
  end
end

main()
