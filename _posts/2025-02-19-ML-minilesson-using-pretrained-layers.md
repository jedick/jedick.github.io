---
title: "ML MiniLesson: Using pretrained layers"
date: 2025-02-19T14:32:17+08:00
categories:
  - Blog
tags:
  - Machine Learning
  - Transfer Learning
  - TensorFlow
header:
  teaser: /assets/images/2025-02-19-ML-minilesson-using-pretrained-layers/base_model.png
  header: /assets/images/2025-02-19-ML-minilesson-using-pretrained-layers/base_model.png
  og_image: /assets/images/2025-02-19-ML-minilesson-using-pretrained-layers/base_model.png
---

Transfer learning take layers of an existing neural network previously trained on a (usually large) dataset.
These layers are the starting point to build a new model that is then trained on your own (usually smaller) dataset.
This allows features learned from the large dataset to *transfer* and help with the learning task on new data.

Let's use the VGG16 image classification model to start building a transfer learning model in TensforFlow.
The first tutorials I came across used this programming pattern for removing the "top" or last layer from VGG16.
As we'll see below, this is last layer (but not the only one) used for classification:

```python
from tf.keras.applications.vgg16 import VGG16
base_model = VGG16()
model = Sequential()
for layer in base_model.layers[:-1]:
  model.add(layer)
```

This does several things: 1) instantiates the VGG16 model as `base_model`; 2) initializes a new, empty Sequential() model as `model`; 3) adds all but the last layer from VGG16 to the new model.
After running `model.trainable = False`, we are ready to add our own custom trainable layers.

However, this is not an efficient structure, as we are instantiating two models, and it guides us into using the Sequential API in TensorFlow instead of the more flexible [Functional API](https://www.tensorflow.org/guide/keras/functional_api).

Fortunately, François Chollet's guide for [Transfer learning & fine-tuning](https://www.tensorflow.org/guide/keras/transfer_learning) in TensorFlow shows how to achieve the removal of the top **layers** with one command.
That guide uses the Xception image classifier.
I modified it as follows for transfer learning with the VGG16 classifier:

```python
base_model = VGG16(
    weights = "imagenet",
    include_top = False,
    input_shape = X_train.shape[1:],
    classes = 10)
```

This instantiates a model with pre-trained weights from ImageNet.
With the `include_top = False` argument the result [does not include the 3 fully-connected layers at the top of the network](https://keras.io/api/applications/vgg/).
Notably, removing these layers ([which together make up the *classifier* in VGG16](https://learnopencv.com/understanding-convolutional-neural-networks-cnn/#Fully-Connected-Classifier)) is different from removing only the top layer as in the previous example.
The other arguments adjust the model to accept input with the dimensions of the training images and to make predictions for a specified number of classes.

Be sure to check out my completed [Transfer Learning with Keras](https://github.com/jedick/mec2-projects/blob/main/Student_MLE_MiniProject_Fine_Tuning.ipynb) mini-project (done during the Springboard ML Engineering bootcamp) to see the code in action, including both transfer learning and fine tuning!
Fine tuning unfreezes all of the model layers for a good boost in performance, but should be done *after* transfer learning so that large gradients from the new layers don't wipe out previously learned features.

Here are places where I first came across the `include_top` argument before finally sitting down to digest the excellent TensorFlow guide mentioned above.
- <https://github.com/mjiansun/cifar10-vgg16>
- <https://stackoverflow.com/questions/42243323/using-keras-with-tensorflow-as-backend-to-train-cifar10-using-vgg16-py-from-kera>
