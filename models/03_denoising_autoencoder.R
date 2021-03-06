########################################
######## Download the MNIST data #######
########################################

# Load the get_mnist function.
get_data_mnist = file.path(dirname(getwd()), 'utils', 'get_data_mnist.R')
source(get_data_mnist)

# Define directory for the data.
my_data_dir = file.path(dirname(getwd()), 'data')

# Download MNIST.
get_data_mnist(my_data_dir)


########################################
#### Load and noise the input data #####
########################################

# Load the train data.
load(file.path(my_data_dir, 'train.RData'))

# Load the test data.
load(file.path(my_data_dir, 'test.RData'))

# Since they are of no use, delete the labels
rm(list = c('trainLabels', 'testLabels'))

# Plot a few images from the test data.
vis_random_data = file.path(dirname(getwd()), 'utils', 'vis_random_data.R')
source(vis_random_data)
vis_random_data(testData, 16, my_seed = 1)

# Put some noise on the train and test data and plot it again
noise_fun = file.path(dirname(getwd()), 'utils', 'noise_data.R')
source(noise_fun)
noised_train_data = noise_data(trainData, 0.5)
noised_test_data = noise_data(testData, 0.5)
vis_random_data(noised_test_data, 16, my_seed = 1)


########################################
### Set a couple of mxnet parameters ###
########################################

# Load the package.
require('mxnet')

# Define the device, either mx.cpu() or mx.gpu().
devices = mx.cpu()

# We want a seed for reproducible results.
mx.set.seed(1)

# MXNet uses logger objects to save results during training.
logger = mx.metric.logger$new()


########################################
###### Build dense feedforward net #####
########################################

# Create the model's input layer.
input = mx.symbol.Variable('data')

# The encoder has 64 neurons.
encoder = mx.symbol.FullyConnected(data = input, num_hidden = 64)
act1 = mx.symbol.Activation(data = encoder, act_type = 'relu')

# Since pixels are normalized, we use a sigmoid to squash the values to [0, 1].
decoder = mx.symbol.FullyConnected(data = act1, num_hidden = 784)
act2 = mx.symbol.Activation(data = decoder, act_type = 'sigmoid')

# We would like to minimize the MSE.
output = mx.symbol.LinearRegressionOutput(data = act2)


########################################
#### Define model's hyperparameters ####
########################################

# MXNet follows a 'colmajor philosophy' (for whatever reason), thus it 
# is  recommended to transpose the data before feeding it into the model.
noised_train_data = t(noised_train_data)
noised_test_data = t(noised_test_data)

# Set the number of epochs we want to train the model .
num_epochs = 5
my_batchsize = 32

# Create a data frame for the results.
results = data.frame(matrix(ncol = 2, nrow = num_epochs))

# Train the model.
model = mx.model.FeedForward.create(output,
  X = noised_train_data, y = t(trainData),
  ctx = devices,
  optimizer = 'adam',
  num.round = num_epochs,
  array.batch.size = my_batchsize,
  initializer = mx.init.uniform(0.01),
  eval.metric = mx.metric.mse,
  epoch.end.callback = mx.callback.log.train.metric(5, logger),
  array.layout = 'colmajor')

# predict the test data
my_pred = predict(model, noised_test_data)

# visualize the denoised predictions
vis_random_data(t(my_pred), 16, my_seed = 1)

