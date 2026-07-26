# digits.be - streaming MNIST training and evaluation on the ESP32-S3.
# Dataset is 14x14 uint8 images produced by scripts/convert_mnist.py.

var INPUTS = 196
var BATCH = 64
var MODEL = "/home/mnist14.bml"
var TRAIN_IMAGES = "/home/mnist14-train-images.u8"
var TRAIN_LABELS = "/home/mnist14-train-labels.u8"
var TEST_IMAGES = "/home/mnist14-test-images.u8"
var TEST_LABELS = "/home/mnist14-test-labels.u8"

def open_model()
  var model = ml.load(MODEL)
  if model == nil
    model = ml.create(INPUTS, 32, 10)
    screen.print("New 196 -> 32 -> 10 model\n", screen.YELLOW)
  else
    screen.print("Checkpoint loaded\n", screen.GREEN)
  end
  return model
end

def open_pair(images_path, labels_path)
  var images = fs.open(images_path, "r")
  var labels = fs.open(labels_path, "r")
  if images == nil || labels == nil
    if images != nil   fs.close(images)   end
    if labels != nil   fs.close(labels)   end
    return nil
  end
  return [images, labels]
end

def train_epoch()
  var files = open_pair(TRAIN_IMAGES, TRAIN_LABELS)
  if files == nil
    screen.print("Dataset not found in /home\n", screen.RED)
    return
  end
  var model = open_model()
  var batches = 0
  var samples = 0
  var total_loss = 0.0

  while true
    var labels = fs.read_chunk(files[1], BATCH)
    var count = size(labels)
    if count == 0   break   end
    var images = fs.read_chunk(files[0], count * INPUTS)
    if size(images) != count * INPUTS
      screen.print("Truncated image dataset\n", screen.RED)
      break
    end
    var loss = ml.train_bytes(model, images, labels, 0.025)
    total_loss = total_loss + loss * count
    samples = samples + count
    batches = batches + 1

    if batches % 20 == 0
      screen.print(str(samples) + " samples loss " +
                   str(total_loss / samples) + "\n", screen.CYAN)
    end
    if batches % 100 == 0   ml.save(model, MODEL)   end
  end

  fs.close(files[0])
  fs.close(files[1])
  if samples > 0 && ml.save(model, MODEL)
    screen.print("Saved " + str(samples) + " samples\n", screen.GREEN)
  end
  ml.close(model)
end

def evaluate()
  var files = open_pair(TEST_IMAGES, TEST_LABELS)
  if files == nil
    screen.print("Test dataset not found in /home\n", screen.RED)
    return
  end
  var model = ml.load(MODEL)
  if model == nil
    screen.print("Train the model first\n", screen.RED)
    fs.close(files[0])
    fs.close(files[1])
    return
  end

  var samples = 0
  var correct = 0
  var total_loss = 0.0
  while true
    var labels = fs.read_chunk(files[1], BATCH)
    var count = size(labels)
    if count == 0   break   end
    var images = fs.read_chunk(files[0], count * INPUTS)
    if size(images) != count * INPUTS   break   end
    var metrics = ml.evaluate_bytes(model, images, labels)
    samples = samples + count
    correct = correct + metrics["correct"]
    total_loss = total_loss + metrics["loss"] * count
  end

  fs.close(files[0])
  fs.close(files[1])
  if samples > 0
    var accuracy = int(correct * 1000 / samples) / 10.0
    screen.print("Accuracy " + str(accuracy) + "% (" + str(correct) + "/" +
                 str(samples) + ")\n", screen.GREEN)
    screen.print("Loss " + str(total_loss / samples) + "\n", screen.CYAN)
  end
  ml.close(model)
end

screen.clear()
screen.print("MNIST 14x14 ON-DEVICE ML\n", screen.CYAN)
if arg == "train"
  train_epoch()
elif arg == "eval"
  evaluate()
else
  screen.print("Usage: digits train | eval\n", screen.WHITE)
end
