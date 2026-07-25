# mania.be - ритм-игра в стиле osu!mania на 4 клавиши.
#
# Ноты падают сверху вниз по четырём дорожкам. Нажимай D F J K в момент,
# когда нота доходит до линии внизу. Пропустил ноту - игра окончена.
# Со временем скорость растёт и ноты идут чаще.
#
# Управление:
#   D F J K   - дорожки слева направо
#   ESC       - выход
#   ENTER     - рестарт на экране проигрыша
#
# Установка:  pkg install mania     Запуск:  mania

# --- Геометрия под экран 160x128 ---
var LANES      = 4
var LANE_W     = 40          # 160 / 4
var HIT_Y      = 104         # линия, по которой судим попадание
var NOTE_H     = 7
var BOTTOM     = 128

# Окна попадания в пикселях от линии.
var W_PERFECT  = 6
var W_GOOD     = 14

# HID-коды клавиш D F J K. Берём именно коды, а не символы: тогда игра
# работает одинаково и в русской раскладке (там на этих клавишах в ф о л).
var KEY_D = 0x07
var KEY_F = 0x09
var KEY_J = 0x0D
var KEY_K = 0x0E

# Цвета дорожек - крайние синие, средние оранжевые, как в mania
var LANE_COLORS = [0, 0, 0, 0]

def init_colors()
  LANE_COLORS[0] = gfx.CYAN
  LANE_COLORS[1] = gfx.WHITE
  LANE_COLORS[2] = gfx.WHITE
  LANE_COLORS[3] = gfx.CYAN
end

def key_to_lane(code)
  if   code == KEY_D  return 0
  elif code == KEY_F  return 1
  elif code == KEY_J  return 2
  elif code == KEY_K  return 3
  end
  return -1
end

# ------------------------------------------------------------------
# Состояние партии
# ------------------------------------------------------------------
var notes        = []     # список map {lane, y}
var score        = 0
var combo        = 0
var max_combo    = 0
var speed        = 0.0    # пикселей за кадр
var spawn_every  = 0      # кадров между нотами
var spawn_timer  = 0
var frames       = 0
var alive        = true
var judge_text   = ""     # "PERFECT" / "GOOD" - показываем пару кадров
var judge_color  = 0
var judge_left   = 0
var flash        = [0, 0, 0, 0]   # подсветка дорожки при нажатии

def reset_game()
  notes       = []
  score       = 0
  combo       = 0
  max_combo   = 0
  speed       = 1.8
  spawn_every = 26
  spawn_timer = 8
  frames      = 0
  alive       = true
  judge_text  = ""
  judge_left  = 0
  flash       = [0, 0, 0, 0]
end

# Сложность растёт плавно: каждые ~8 секунд чуть быстрее и чуть чаще.
def bump_difficulty()
  if frames % 240 != 0   return  end
  speed = speed + 0.35
  if speed > 7.0   speed = 7.0   end
  spawn_every = spawn_every - 2
  if spawn_every < 8   spawn_every = 8   end
end

def spawn_note()
  # Не даём двум нотам налезть друг на друга в одной дорожке.
  var lane = math.rand() % LANES
  for n : notes
    if n["lane"] == lane && n["y"] < NOTE_H * 2
      return
    end
  end
  notes.push({"lane": lane, "y": -NOTE_H})
end

def set_judge(text, color)
  judge_text  = text
  judge_color = color
  judge_left  = 12
end

# Нажатие по дорожке: ищем ближайшую к линии ноту в этой дорожке.
def hit_lane(lane)
  flash[lane] = 4

  var best  = -1
  var bestd = 9999
  for i : 0 .. size(notes) - 1
    var n = notes[i]
    if n["lane"] != lane   continue  end
    var d = n["y"] - HIT_Y
    if d < 0   d = -d   end
    if d < bestd
      bestd = d
      best  = i
    end
  end

  if best < 0 || bestd > W_GOOD
    # Промах по пустой дорожке комбо рвёт, но игру не заканчивает.
    combo = 0
    set_judge("MISS", gfx.RED)
    return
  end

  notes.pop(best)
  combo = combo + 1
  if combo > max_combo   max_combo = combo   end

  # Комбо-множитель: каждые 10 нот подряд +10% к очкам, максимум x2.
  var mult = 10 + combo / 10
  if mult > 20   mult = 20   end

  if bestd <= W_PERFECT
    score = score + 300 * mult / 10
    set_judge("PERFECT", gfx.YELLOW)
  else
    score = score + 100 * mult / 10
    set_judge("GOOD", gfx.GREEN)
  end
end

# Двигаем ноты. Возвращает false если что-то улетело за экран - это проигрыш.
def update_notes()
  var i = 0
  while i < size(notes)
    var n = notes[i]
    n["y"] = n["y"] + speed
    if n["y"] > BOTTOM
      return false
    end
    i = i + 1
  end
  return true
end

# ------------------------------------------------------------------
# Отрисовка
# ------------------------------------------------------------------
def draw_playfield()
  gfx.clear()

  # Разделители дорожек
  for i : 1 .. LANES - 1
    gfx.line(i * LANE_W, 0, i * LANE_W, BOTTOM, 0x2104)
  end

  # Подсветка нажатой дорожки
  for i : 0 .. LANES - 1
    if flash[i] > 0
      gfx.fillrect(i * LANE_W + 1, HIT_Y - 4, LANE_W - 2, NOTE_H + 8, 0x2145)
      flash[i] = flash[i] - 1
    end
  end

  # Линия попадания
  gfx.fillrect(0, HIT_Y, 160, 2, gfx.WHITE)

  # Приёмники под каждой дорожкой
  for i : 0 .. LANES - 1
    gfx.rect(i * LANE_W + 6, HIT_Y - 3, LANE_W - 12, NOTE_H + 6, LANE_COLORS[i])
  end

  # Ноты
  for n : notes
    var x = n["lane"] * LANE_W + 4
    var y = n["y"]
    if y > -NOTE_H && y < BOTTOM
      gfx.fillrect(x, y, LANE_W - 8, NOTE_H, LANE_COLORS[n["lane"]])
    end
  end

  # Счёт слева сверху, комбо по центру
  gfx.text(2, 2, str(score), gfx.WHITE, 1)
  if combo > 1
    var ctxt = str(combo) + "x"
    gfx.text(80 - size(ctxt) * 3, 2, ctxt, gfx.YELLOW, 1)
  end

  # Оценка последнего нажатия
  if judge_left > 0
    gfx.text(80 - size(judge_text) * 3, 88, judge_text, judge_color, 1)
    judge_left = judge_left - 1
  end
end

def draw_ready()
  gfx.clear()
  gfx.text(28, 24, "OSU MANIA", gfx.CYAN, 1)
  gfx.line(28, 34, 132, 34, gfx.CYAN)
  gfx.text(20, 48, "Lovi noty klavishami", gfx.WHITE, 1)

  # Показываем раскладку клавиш прямо на дорожках
  var labels = ["D", "F", "J", "K"]
  for i : 0 .. LANES - 1
    var x = i * LANE_W + LANE_W / 2 - 3
    gfx.rect(i * LANE_W + 6, 66, LANE_W - 12, 14, LANE_COLORS[i])
    gfx.text(x, 69, labels[i], gfx.WHITE, 1)
  end

  var best = nvs.get("mania_best", 0)
  if best > 0
    gfx.text(24, 90, "Rekord: " + str(best), gfx.YELLOW, 1)
  end
  gfx.text(16, 108, "ENTER - start, ESC - vyhod", gfx.GREEN, 1)
  gfx.flush()
end

def draw_gameover(is_record)
  gfx.clear()
  gfx.text(46, 16, "PROIGRAL", gfx.RED, 1)
  gfx.line(30, 26, 130, 26, gfx.RED)

  gfx.text(16, 40, "Ochki:", gfx.WHITE, 1)
  gfx.text(80, 40, str(score), gfx.YELLOW, 1)

  gfx.text(16, 54, "Max combo:", gfx.WHITE, 1)
  gfx.text(96, 54, str(max_combo), gfx.CYAN, 1)

  gfx.text(16, 68, "Rekord:", gfx.WHITE, 1)
  gfx.text(80, 68, str(nvs.get("mania_best", 0)), gfx.GREEN, 1)

  if is_record
    gfx.text(30, 86, "NOVYJ REKORD!", gfx.MAGENTA, 1)
  end

  gfx.text(10, 108, "ENTER - snova, ESC - vyhod", gfx.WHITE, 1)
  gfx.flush()
end

# ------------------------------------------------------------------
# Одна партия. Возвращает true если игрок хочет играть ещё.
# ------------------------------------------------------------------
def play_round()
  reset_game()

  while alive
    # 1. Ввод. Разгребаем всю очередь: за кадр могло накопиться несколько
    #    нажатий, и терять их нельзя - это прямая потеря очков.
    while true
      var e = input.key()
      if e == nil   break   end

      var k = e["key"]
      if k == input.ESC
        return false
      end
      var lane = key_to_lane(k)
      if lane >= 0
        hit_lane(lane)
      end
    end

    # Ctrl+C - аварийный выход, обрабатывается системой отдельно
    if sys.aborted()
      return false
    end

    # 2. Логика
    frames = frames + 1
    bump_difficulty()

    spawn_timer = spawn_timer - 1
    if spawn_timer <= 0
      spawn_note()
      spawn_timer = spawn_every
    end

    if !update_notes()
      alive = false
      break
    end

    # 3. Кадр
    draw_playfield()
    gfx.flush()
    delay(28)
  end

  # Партия окончена - обновляем рекорд
  var is_record = false
  if score > nvs.get("mania_best", 0)
    nvs.set("mania_best", score)
    is_record = true
  end

  draw_gameover(is_record)

  # Ждём решения игрока
  while true
    var e = input.wait(200)
    if sys.aborted()   return false   end
    if e == nil        continue       end
    if e["key"] == input.ENTER   return true   end
    if e["key"] == input.ESC     return false  end
  end
end

# ------------------------------------------------------------------
def main()
  init_colors()
  math.srand(millis())

  gfx.begin()
  input.begin()
  input.flush()

  draw_ready()

  # Стартовый экран
  var start = false
  while true
    var e = input.wait(200)
    if sys.aborted()   break   end
    if e == nil        continue end
    if e["key"] == input.ENTER   start = true  break  end
    if e["key"] == input.ESC     break               end
  end

  while start
    start = play_round()
  end

  input.close()
  gfx.close()
  print("Score:", score, " Max combo:", max_combo)
end

main()
