#!/usr/bin/env python
# -*- coding: utf-8 -*-
# emacs: -*- mode: python; py-indent-offset: 4; indent-tabs-mode: nil -*-
# vi: set ft=python sts=4 ts=4 sw=4 et

import os
import sys
import time
import numpy as np
import keras

import ants
import antspynet

args = sys.argv


#folder_dicom_data='/home/vozenne/Reseau/Imagerie/DICOM_DATA/'
#folder_ex_vivo=folder_dicom_data+'2022-12-20_ExVivoBrain/'

if len(args) != 5:
    help_message = ("Usage:  python doBrainExtraction.py" +
        " inputFile outputFile reorientationTemplate model_file_name")
    raise AttributeError(help_message)
else:
    input_file_name = args[1]
    output_file_name = args[2]
    reorient_template_file_name = args[3]
    model_file_name=args[4]

classes = ("background", "brain")
number_of_classification_labels = len(classes)

image_mods = ["T1"]
channel_size = len(image_mods)

print("Reading reorientation template " + reorient_template_file_name)
start_time = time.time()
reorient_template = ants.image_read(reorient_template_file_name)
end_time = time.time()
elapsed_time = end_time - start_time
print("  (elapsed time: ", elapsed_time, " seconds)")

resampled_image_size = reorient_template.shape
template_size = reorient_template.shape

#ancien unet
#unet_model = antspynet.create_unet_model_3d( (*resampled_image_size, channel_size),
#  number_of_outputs = number_of_classification_labels,
#  number_of_layers = 4, number_of_filters_at_base_layer = 8, dropout_rate = 0.0,
#  convolution_kernel_size = (3, 3, 3), deconvolution_kernel_size = (2, 2, 2),
#  weight_decay = 1e-5 )
  
#nouveau unet  
#unet_model = antspynet.create_unet_model_3d((*template_size, channel_size),
#    number_of_outputs=1, mode = "sigmoid",
#    number_of_filters=(16, 32), dropout_rate=0.0,
#    convolution_kernel_size=3, deconvolution_kernel_size=2,
#    weight_decay=1e-5)

unet_model = antspynet.create_unet_model_3d((*template_size, channel_size),
    number_of_outputs=1, mode = "sigmoid",
    number_of_filters=(16, 32, 64, 128), dropout_rate=0.0,
    convolution_kernel_size=3, deconvolution_kernel_size=2,
    weight_decay=1e-5)




print( "Loading weights file" )
start_time = time.time()
weights_file_name = model_file_name
print("reading: " , weights_file_name)
if not os.path.exists(weights_file_name):
     print('error')
     quit() 
#    weights_file_name = antspynet.get_pretrained_network("brainExtraction", weights_file_name)

unet_model.load_weights(weights_file_name)
end_time = time.time()
elapsed_time = end_time - start_time
print("  (elapsed time: ", elapsed_time, " seconds)")

start_time_total = time.time()

print( "Reading ", input_file_name )
start_time = time.time()
image = ants.image_read(input_file_name)
image = (image - image.min()) / (image.max() - image.min())
end_time = time.time()
elapsed_time = end_time - start_time
print("  (elapsed time: ", elapsed_time, " seconds)")

print( "Normalizing to template" )
start_time = time.time()
center_of_mass_template = ants.get_center_of_mass(reorient_template)
center_of_mass_image = ants.get_center_of_mass(image)
translation = np.asarray(center_of_mass_image) - np.asarray(center_of_mass_template)
xfrm = ants.create_ants_transform(transform_type="Euler3DTransform",
  center=np.asarray(center_of_mass_template),
  translation=translation)
warped_image = ants.apply_ants_transform_to_image(xfrm, image,
  reorient_template)
warped_image = (warped_image - warped_image.mean()) / warped_image.std()


ants.image_write(warped_image, 'warped_image.nii.gz')

batchX = np.expand_dims(warped_image.numpy(), axis=0)
batchX = np.expand_dims(batchX, axis=-1)
batchX = (batchX - batchX.mean()) / batchX.std()

end_time = time.time()
elapsed_time = end_time - start_time
print("  (elapsed time: ", elapsed_time, " seconds)")


print("Prediction and decoding")
start_time = time.time()
predicted_data = unet_model.predict(batchX, verbose=0)

print(np.sum(predicted_data))

origin = reorient_template.origin
spacing = reorient_template.spacing
direction = reorient_template.direction

print(np.shape(predicted_data))

probability_images_array = list()
probability_images_array.append(
   ants.from_numpy(np.squeeze(predicted_data[0, :, :, :, 0]),
     origin=origin, spacing=spacing, direction=direction))
#probability_images_array.append(
#   ants.from_numpy(np.squeeze(predicted_data[0, :, :, :, 1]),
#     origin=origin, spacing=spacing, direction=direction))


probability_images_array[0]
end_time = time.time()
elapsed_time = end_time - start_time
print("  (elapsed time: ", elapsed_time, " seconds)")

print("Renormalize to native space")
start_time = time.time()
probability_image = ants.apply_ants_transform_to_image(
  ants.invert_ants_transform(xfrm), probability_images_array[0],
  image)
end_time = time.time()
elapsed_time = end_time - start_time
print("  (elapsed time: ", elapsed_time, " seconds)")

print("Writing", output_file_name)
start_time = time.time()
ants.image_write(probability_image, output_file_name)
end_time = time.time()
elapsed_time = end_time - start_time
print("  (elapsed time: ", elapsed_time, " seconds)")

end_time_total = time.time()
elapsed_time_total = end_time_total - start_time_total
print( "Total elapsed time: ", elapsed_time_total, "seconds" )
