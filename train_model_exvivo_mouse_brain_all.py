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

list_contrast2=['before', 'after', 'with', 'long']
list_letter2=['c', 'a', 'b', 'l']

list_contrast=['allcontrasts','before', 'after', 'with', 'long' ]  #,  'allimages'
list_contrast=['after'  ] 
#list_contrast=['before'  ] 
list_letter=['x', 'c', 'a', 'b', 'l']
list_letter=[ 'a']   # ,  'x'
#list_letter=[ 'c'] 

list_method=['only_dw_mean_N4',  'only_b0_mean_N4']
list_method=['only_b0_mean_N4']
#list_method=['only_dw_mean',  'only_b0_mean']

#list_contrast=['allcontrasts'  ]
#list_letter=['x']
#list_method=['only_dw_mean_N4',  'only_b0_mean_N4', 'only_dw_mean',  'only_b0_mean']

epochs=256
steps_per_epoch=20

#for idx_contrast in range(0,2):
for idx_contrast in range(0,len(list_contrast)):

    contrast_name=list_contrast[idx_contrast]  
    if ( contrast_name == 'allimages'):
        number_of_method=1
    else:
        number_of_method=len(list_method)

    for idx_method in range (0,number_of_method):

        method_name=list_method[idx_method]
        #method_name_for_template=list_method[idx_method%3]
        #print(method_name_for_template)    

        contrast_name=list_contrast[idx_contrast]
        letter_name=list_letter[idx_contrast]
        
        print("---------------------------------------------------------------------------------")   
        print('idx_contrast: ',  contrast_name,  ' method_name: ', method_name)
        print('method_name', method_name)
        filename_template=folder_ex_vivo+'template_all64_initial/tous/MYtemplate0.nii.gz'
        
        if (os.path.isfile(filename_template) == False):
            raise Exception('error template filename is not valid')
        
        template = ants.image_read(filename_template)
        template_brain_mask = ants.image_read(filename_template)
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

        weights_filename = folder_ex_vivo+'modelall_64/'+ 'mouseExVivoBrainExtraction_'+contrast_name+'_'+method_name+'_server_july2025.h5'
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

        image_to_find_full_list=[] 
        masks_to_find_full_list=[]
                
        if ((method_name == 'only_b0_mean' and 'N4' not in method_name ) and 'all' not in contrast_name ):    

                  images_to_find=folder_ex_vivo+'all_64/'+contrast_name+'/'+letter_name+'*_only_b0_mean.nii.gz'
                  masks_to_find=folder_ex_vivo+'all_64/'+contrast_name+'/mask_'+letter_name+'*_dwi.nii.gz'

                  print(folder_ex_vivo+'all_64/'+contrast_name+'/'+letter_name+'*_only_b0_mean.nii.gz')
                  print(folder_ex_vivo+'all_64/'+contrast_name+'/mask_'+letter_name+'*_dwi.nii.gz')
                  
                  liste_tempo_image=glob.glob(images_to_find)
                  liste_tempo_mask=glob.glob(masks_to_find)

                  print('liste_tempo_image', len(liste_tempo_image))
                  print('liste_tempo_mask', len(liste_tempo_mask))

                  image_to_find_full_list=image_to_find_full_list+liste_tempo_image
                  masks_to_find_full_list=masks_to_find_full_list+liste_tempo_mask              
            
        elif ((method_name == 'only_dw_mean' and 'N4' not in method_name  )  and 'all' not in contrast_name): 

                  images_to_find=folder_ex_vivo+'all_64/'+contrast_name+'/'+letter_name+'*_only_dw_mean.nii.gz'
                  masks_to_find=folder_ex_vivo+'all_64/'+contrast_name+'/mask_'+letter_name+'*_dwi.nii.gz'

                  print(folder_ex_vivo+'all_64/'+contrast_name+'/'+letter_name+'*_only_dw_mean.nii.gz')
                  print(folder_ex_vivo+'all_64/'+contrast_name+'/mask_'+letter_name+'*_dwi.nii.gz')

                  liste_tempo_image=glob.glob(images_to_find)
                  liste_tempo_mask=glob.glob(masks_to_find)

                  print('liste_tempo_image', len(liste_tempo_image))
                  print('liste_tempo_mask', len(liste_tempo_mask))

                  image_to_find_full_list=image_to_find_full_list+liste_tempo_image
                  masks_to_find_full_list=masks_to_find_full_list+liste_tempo_mask
                  
        elif (( method_name == 'only_b0_mean_N4' and 'all' not in contrast_name )):    

                  images_to_find=folder_ex_vivo+'all_64/'+contrast_name+'/'+letter_name+'*_only_b0_mean_N4.nii.gz'
                  masks_to_find=folder_ex_vivo+'all_64/'+contrast_name+'/mask_'+letter_name+'*_dwi.nii.gz'

                  print(folder_ex_vivo+'all_64/'+contrast_name+'/'+letter_name+'*_only_b0_mean_N4.nii.gz')
                  print(folder_ex_vivo+'all_64/'+contrast_name+'/mask_'+letter_name+'*_dwi.nii.gz')

                  liste_tempo_image=glob.glob(images_to_find)
                  liste_tempo_mask=glob.glob(masks_to_find)

                  print('liste_tempo_image', len(liste_tempo_image))
                  print('liste_tempo_mask', len(liste_tempo_mask))

                  image_to_find_full_list=image_to_find_full_list+liste_tempo_image
                  masks_to_find_full_list=masks_to_find_full_list+liste_tempo_mask
            
        elif ((method_name == 'only_dw_mean_N4' and 'all' not in contrast_name )):  

                  images_to_find=folder_ex_vivo+'all_64/'+contrast_name+'/'+letter_name+'*_only_dw_mean_N4.nii.gz'
                  masks_to_find=folder_ex_vivo+'all_64/'+contrast_name+'/mask_'+letter_name+'*_dwi.nii.gz' 

                  print(folder_ex_vivo+'all_64/'+contrast_name+'/'+letter_name+'*_only_dw_mean_N4.nii.gz')
                  print(folder_ex_vivo+'all_64/'+contrast_name+'/mask_'+letter_name+'*_dwi.nii.gz')

                  liste_tempo_image=glob.glob(images_to_find)
                  liste_tempo_mask=glob.glob(masks_to_find)

                  print('liste_tempo_image', len(liste_tempo_image))
                  print('liste_tempo_mask', len(liste_tempo_mask))

                  image_to_find_full_list=image_to_find_full_list+liste_tempo_image
                  masks_to_find_full_list=masks_to_find_full_list+liste_tempo_mask

        elif (contrast_name == 'allcontrasts' ):              
            
              for idx2 in range (0,len(list_contrast2)):
                  
                  contrast_name2=list_contrast2[idx2]
                  letter_name2=list_letter2[idx2]
                  print(idx2, contrast_name2, letter_name2 )

                  if (method_name == 'only_dw_mean_N4'):

                     images_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/'+letter_name2+'*_only_dw_mean_N4.nii.gz'
                     masks_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/mask_'+letter_name2+'*_dwi.nii.gz' 
   
                     liste_tempo_image=glob.glob(images_to_find)
                     liste_tempo_mask=glob.glob(masks_to_find)

                     print('liste_tempo_image', len(liste_tempo_image))
                     print('liste_tempo_mask', len(liste_tempo_mask))

                     image_to_find_full_list=image_to_find_full_list+liste_tempo_image
                     masks_to_find_full_list=masks_to_find_full_list+liste_tempo_mask                   

                  elif (method_name == 'only_b0_mean_N4'):

                     images_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/'+letter_name2+'*_only_b0_mean_N4.nii.gz'
                     masks_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/mask_'+letter_name2+'*_dwi.nii.gz' 
   
                     liste_tempo_image=glob.glob(images_to_find)
                     liste_tempo_mask=glob.glob(masks_to_find)

                     print('liste_tempo_image', len(liste_tempo_image))
                     print('liste_tempo_mask', len(liste_tempo_mask))

                     image_to_find_full_list=image_to_find_full_list+liste_tempo_image
                     masks_to_find_full_list=masks_to_find_full_list+liste_tempo_mask    

                  elif (method_name == 'only_dw_mean'):

                     images_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/'+letter_name2+'*_only_dw_mean.nii.gz'
                     masks_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/mask_'+letter_name2+'*_dwi.nii.gz' 
   
                     liste_tempo_image=glob.glob(images_to_find)
                     liste_tempo_mask=glob.glob(masks_to_find)

                     print('liste_tempo_image', len(liste_tempo_image))
                     print('liste_tempo_mask', len(liste_tempo_mask))

                     image_to_find_full_list=image_to_find_full_list+liste_tempo_image
                     masks_to_find_full_list=masks_to_find_full_list+liste_tempo_mask                   

                  elif (method_name == 'only_b0_mean'):

                     images_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/'+letter_name2+'*_only_b0_mean.nii.gz'
                     masks_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/mask_'+letter_name2+'*_dwi.nii.gz' 
   
                     liste_tempo_image=glob.glob(images_to_find)
                     liste_tempo_mask=glob.glob(masks_to_find)

                     print('liste_tempo_image', len(liste_tempo_image))
                     print('liste_tempo_mask', len(liste_tempo_mask))

                     image_to_find_full_list=image_to_find_full_list+liste_tempo_image
                     masks_to_find_full_list=masks_to_find_full_list+liste_tempo_mask   

        elif ( contrast_name == 'allimages' ):    
            pass 
            # la il faut prendre à la fois le b0 et les dw        

                
        image_images_1 =image_to_find_full_list
        mask_images_1 = masks_to_find_full_list
        
        print('image_images_1', len(image_images_1))
        print('mask_images_1', len(mask_images_1))

        for p in range(0, len(image_images_1)):
           lala_i=str.replace(image_images_1[p], '/home/valeryozenne/mount/Imagerie/DICOM_DATA/2022-12-20_ExVivoBrain','')
           lala_m=str.replace(mask_images_1[p], '/home/valeryozenne/mount/Imagerie/DICOM_DATA/2022-12-20_ExVivoBrain','')
           print(p,lala_i, lala_m )

        # ici on exclut le numero 109
        substring="138"
     
        image_images_1_ok = list(filter(lambda x: not re.search(substring, x), image_images_1))
        mask_images_1_ok = list(filter(lambda x: not re.search(substring, x), mask_images_1))
       
        print(len(image_images_1_ok))
        print(len(mask_images_1_ok))

        print((image_images_1_ok))
        print((mask_images_1_ok))        
        
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
        if ('all' in contrast_name):
            batch_size = 4
        else:
            batch_size = 2

        print("batch_size: ", batch_size)
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
        
        filename_history= folder_ex_vivo+'modelall_64/'+ 'history_'+contrast_name+'_'+method_name + str_time_new+str(epochs)+ '_steps_per_epoch_' + str(steps_per_epoch)+'.npy'
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
        fname= folder_ex_vivo+'modelall_64/'+ 'fig_loss_'+contrast_name+'_'+method_name + str_time_new+str(epochs)+ '_steps_per_epoch_' + str(steps_per_epoch)+'.png'
        plt.savefig(fname, dpi=100)  


