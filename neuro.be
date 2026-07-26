# neuro.be - настоящая обучаемая нейросеть XOR на ESP32.
#
#   neuro          обучить сеть, показать результат и сохранить checkpoint
#   neuro --load   загрузить готовую модель и выполнить inference

var MODEL_PATH = "/home/xor.bml"
var SAMPLES = [
  [0.0, 0.0],
  [0.0, 1.0],
  [1.0, 0.0],
  [1.0, 1.0]
]
var LABELS = [0, 1, 1, 0]

def winner(probabilities)
  if probabilities[1] > probabilities[0]   return 1   end
  return 0
end

def show_predictions(model)
  screen.print("\nXOR inference\n", screen.CYAN)
  var i = 0
  for sample : SAMPLES
    var probabilities = ml.predict(model, sample)
    screen.print(str(int(sample[0])) + " xor " + str(int(sample[1])) + " = ",
                 screen.WHITE)
    var result = winner(probabilities)
    var color = result == LABELS[i] ? screen.GREEN : screen.RED
    screen.print(str(result), color)
    screen.print("  p=" + str(probabilities[LABELS[i]]) + "\n", screen.CYAN)
    i = i + 1
  end
end

def train_model()
  var model = ml.create(2, 8, 2)
  var info = ml.info(model)
  screen.clear()
  screen.print("ON-DEVICE NEURAL TRAINING\n", screen.CYAN)
  screen.print("Params: " + str(info["parameters"]) + "\n", screen.YELLOW)

  var epoch = 0
  var loss = 0.0
  while epoch < 1200
    loss = ml.train_batch(model, SAMPLES, LABELS, 0.08)
    epoch = epoch + 1
    if epoch % 200 == 0
      screen.print("Epoch " + str(epoch) + " loss " + str(loss) + "\n",
                   screen.GREEN)
    end
    if sys.aborted()   break   end
  end

  show_predictions(model)
  if ml.save(model, MODEL_PATH)
    screen.print("Saved: " + MODEL_PATH + "\n", screen.MAGENTA)
  else
    screen.print("Checkpoint save failed\n", screen.RED)
  end
  ml.close(model)
end

def load_model()
  var model = ml.load(MODEL_PATH)
  if model == nil
    screen.print("No checkpoint. Run: neuro\n", screen.RED)
    return
  end
  show_predictions(model)
  ml.close(model)
end

if arg == "--load"
  load_model()
else
  train_model()
end
