import ants
import antspynet
import re
import os
os.environ["CUDA_VISIBLE_DEVICES"] = "1"
import glob

import random
import math

import tensorflow as tf
import tensorflow.keras as keras
import tensorflow.keras.backend as K

K.clear_session()
gpus = tf.config.experimental.list_physical_devices("GPU")
if len(gpus) > 0:
    tf.config.experimental.set_memory_growth(gpus[0], True)

base_directory = '/home/valeryozenne/mount/Imagerie/DICOM_DATA/2022-12-20_ExVivoBrain/'

folder_dicom_data='/home/valeryozenne/mount/Imagerie/DICOM_DATA/'
folder_ex_vivo=folder_dicom_data+'2022-12-20_ExVivoBrain/'


from batch_generator import batch_generator

#template = ants.image_read(base_directory + 'S_template3.nii.gz')
#template_brain_mask = ants.image_read(base_directory + 'S_templateBrainMask.nii.gz')

list_contrast=['Gado', 'Sans_Gado']
list_letter=['b', 'c']
list_method=['only_b0', 'only_b0_mean','only_dw_mean', 'only_b0_N4', 'only_b0_mean_N4','only_dw_mean_N4']

epochs=256
steps_per_epoch=20


for idx_method in range (3,6):

    method_name=list_method[idx_method]

    for idx_contrast in range(0,2):

        contrast_name=list_contrast[idx_contrast]
        letter_name=list_letter[idx_contrast]

        print('method_name', method_name)
     
        template = ants.image_read(folder_ex_vivo+'template_64/'+'Gado'+'/MYtemplate0.nii.gz')
        template_brain_mask = ants.image_read(folder_ex_vivo+'template_64/'+'Gado'+'/MYtemplate0.nii.gz')
        template_size = template.shape

        ################################################
        #
        #  Create the model and load weights
        #
        ################################################

        classes = ['background', 'brain']
        number_of_classification_labels = len(classes)
        image_modalities = ["T1"]
        channel_size = len(image_modalities)

        unet_model = antspynet.create_unet_model_3d((*template_size, channel_size),
            number_of_outputs=1, mode = "sigmoid",
            number_of_filters=(16, 32, 64, 128), dropout_rate=0.0,
            convolution_kernel_size=3, deconvolution_kernel_size=2,
            weight_decay=1e-5)

        weights_filename = folder_ex_vivo+'model_64/'+ 'mouseExVivoBrainExtraction_'+contrast_name+'_'+method_name+'_server_dec2022.h5'
        if os.path.exists(weights_filename):
            unet_model.load_weights(weights_filename)

        # unet_loss = antspynet.weighted_categorical_crossentropy(weights=(1, 2))
        # unet_loss = antspynet.multilabel_dice_coefficient(dimensionality=3, smoothing_factor=0.5)
        unet_loss = antspynet.binary_dice_coefficient(smoothing_factor=0.)
        dice_loss = antspynet.binary_dice_coefficient(smoothing_factor=0.)

        unet_model.compile(optimizer=keras.optimizers.Adam(),
                        loss=unet_loss,
                        metrics=['accuracy', dice_loss])


        ################################################
        #
        #  Load the brain data
        #
        ################################################

        print("Loading braindata.")

        #base_data_directory = base_directory + '/Data/'
        #mask_images_1 = glob.glob(base_data_directory + "CorticalThicknessData2014/*/*BrainExtractionMask.nii.gz")
        #mask_images_2 = glob.glob(base_data_directory + "Oasis3BrainExtractionProcessed/*/*/*/*ants_BrainMask.nii.gz")
        #mask_images_3 = glob.glob(base_data_directory + "ADNI/*BrainExtractionMask.nii.gz")
        #mask_images = (*mask_images_1, *mask_images_2, *mask_images_3)


        if (method_name == 'only_b0' and 'N4' not in method_name):
            
           images_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/'+letter_name+'*_only_b0_?.nii.gz'
           masks_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/mask_'+letter_name+'*.nii.gz'
           
        elif (method_name == 'only_b0_mean' and 'N4' not in method_name):    
           images_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/'+letter_name+'*_only_b0_mean.nii.gz'
           masks_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/mask_'+letter_name+'*_dwi_0.nii.gz'
       
        elif (method_name == 'only_dw_mean' and 'N4' not in method_name):        
           images_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/'+letter_name+'*_only_dw_mean.nii.gz'
           masks_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/mask_'+letter_name+'*_dwi_0.nii.gz'

        elif (method_name == 'only_b0_N4'):
           images_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/'+letter_name+'*_only_b0_*_N4.nii.gz'
           masks_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/mask_'+letter_name+'*.nii.gz'
           
        elif (method_name == 'only_b0_mean_N4'):    
           images_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/'+letter_name+'*_only_b0_mean_N4.nii.gz'
           masks_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/mask_'+letter_name+'*_dwi_0.nii.gz'
       
        elif (method_name == 'only_dw_mean_N4'):        
           images_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/'+letter_name+'*_only_dw_mean_N4.nii.gz'
           masks_to_find=folder_ex_vivo+'data_64/'+contrast_name+'/*/DWI/mask_'+letter_name+'*_dwi_0.nii.gz'   
       
        # ici on exclut le numero 109
        substring="109"

        image_images_1 = glob.glob(images_to_find)
        mask_images_1 = glob.glob(masks_to_find)

        
        print('image_images_1', len(image_images_1))
        print('mask_images_1', len(mask_images_1))
        

        image_images_1_ok = list(filter(lambda x: not re.search(substring, x), image_images_1))
        mask_images_1_ok = list(filter(lambda x: not re.search(substring, x), mask_images_1))
        print(type(image_images_1_ok))

        print(len(image_images_1_ok))
        print(len(mask_images_1_ok))

        print((image_images_1_ok))
        print((mask_images_1_ok))
        quit()
        #for ele in images_to_find:
        #    if substring in ele:
        #        print("Found!")
        #    else:
        #        print("Not found!")


        image_images = image_images_1_ok
        mask_images= mask_images_1_ok

        print(len(mask_images))
        print(len(image_images))

        training_image_files = list()
        training_mask_files = list()

        for i in range(len(mask_images)):
            mask = mask_images[i]
            image = image_images[i]
            #image = mask.replace("_ants_BrainMask", "")
            #if "IXI" in image:
            #    image = image.replace("-BrainExtractionMask", "-T1")
            #elif "Kirby" in image:
            #    image = image.replace("-BrainExtractionMask", "-MPRAGE")
            #image = image.replace("_BrainExtractionMask", "_defaced_MPRAGE")
            #image = image.replace("BrainExtractionMask", "")

            if not os.path.exists(image) or not os.path.exists(mask):
                print(mask + " ---> " + image)
                continue

            training_image_files.append(image)
            training_mask_files.append(mask)

        print("Total training image files: ", len(training_image_files))
        print( "Training")


        ###
        #
        # Set up the training generator
        #

        batch_size = 2

        generator = batch_generator(batch_size=batch_size,
                                    template=template,
                                    template_brain_mask=template_brain_mask,
                                    image_size=template_size,
                                    images=training_image_files,
                                    brain_masks=training_mask_files,
                                    do_random_contralateral_flips=False,
                                    do_histogram_intensity_warping=False,
                                    do_add_noise=True,
                                    do_data_augmentation=True
                                    )

        track = unet_model.fit(x=generator, epochs=epochs, verbose=1, steps_per_epoch=steps_per_epoch,
            callbacks=[
            keras.callbacks.ModelCheckpoint(weights_filename, monitor='loss',
                save_best_only=True, save_weights_only=True, mode='auto', verbose=1),
            keras.callbacks.ReduceLROnPlateau(monitor='loss', factor=0.5,
                verbose=1, patience=10, mode='auto'),
            keras.callbacks.EarlyStopping(monitor='loss', min_delta=0.001,
                patience=20)
            ]
        )

        unet_model.save_weights(weights_filename)

        from time import gmtime, strftime
        str_time=strftime("%Y-%m-%d %H:%M:%S", gmtime())
        str_time_new=str_time.replace(':','-').replace(' ','-')
        import numpy as np
        
        filename_history= folder_ex_vivo+'model_64/'+ 'history_'+contrast_name+'_'+method_name + str_time_new+str(epochs)+ '_steps_per_epoch_' + str(steps_per_epoch)+'.npy'
        np.save(filename_history, track.history)


        import matplotlib.pyplot as plt
        accuracy=track.history['accuracy']
        loss_values=track.history['loss']
        #val_accuracy=track.history['val_accuracy']
        #val_loss_values=track.history['val_loss']
        binary_dice_coefficient_fixed=track.history['binary_dice_coefficient_fixed']
        #val_binary_dice_coefficient_fixed=track.history['val_binary_dice_coefficient_fixed']

        fig=plt.figure()
        plt.subplot(131)
        plt.plot(loss_values)
        #plt.plot(val_loss_values)
        plt.subplot(132)
        plt.plot(accuracy)
        #plt.plot(val_accuracy)
        plt.subplot(133)
        plt.plot(binary_dice_coefficient_fixed)
        #plt.plot(val_binary_dice_coefficient_fixed)
        plt.ioff()
        plt.savefig("Plot-generated-using-Matplotlib.png")
        fname= folder_ex_vivo+'model_64/'+ 'fig_loss_'+contrast_name+'_'+method_name + str_time_new+str(epochs)+ '_steps_per_epoch_' + str(steps_per_epoch)+'.png'
        plt.savefig(fname, dpi=100)  


