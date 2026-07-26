# i2cscan.be - поиск датчиков и периферии на I2C.
# По умолчанию SDA=8, SCL=9: i2cscan

import string

def main()
  if !i2c.begin()
    screen.print("I2C init failed\n", screen.RED)
    return
  end

  screen.print("Scanning I2C...\n", screen.CYAN)
  var devices = i2c.scan()
  if devices == nil || size(devices) == 0
    screen.print("No devices found\n", screen.YELLOW)
    return
  end

  for address : devices
    screen.print("  0x", screen.WHITE)
    if address < 16   screen.print("0")   end
    screen.print(string.hex(address) + "\n", screen.GREEN)
  end
  screen.print(str(size(devices)) + " device(s)\n", screen.CYAN)
end

main()
