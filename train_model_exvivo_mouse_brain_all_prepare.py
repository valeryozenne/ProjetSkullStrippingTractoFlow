import ants
#import antspynet
import re
import os
#os.environ["CUDA_VISIBLE_DEVICES"] = "1"
import glob

import random
import math


#import tensorflow as tf
#import tensorflow.keras as keras
#import tensorflow.keras.backend as K

#K.clear_session()
#gpus = tf.config.experimental.list_physical_devices("GPU")
#if len(gpus) > 0:
#    tf.config.experimental.set_memory_growth(gpus[0], True)


base_directory = '/home/valeryozenne/mount/Imagerie/DICOM_DATA/2022-12-20_ExVivoBrain/'

folder_dicom_data='/home/valeryozenne/mount/Imagerie/DICOM_DATA/'
folder_ex_vivo=folder_dicom_data+'2022-12-20_ExVivoBrain/'


#from batch_generator import batch_generator

#template = ants.image_read(base_directory + 'S_template3.nii.gz')
#template_brain_mask = ants.image_read(base_directory + 'S_templateBrainMask.nii.gz')

list_contrast2=['before', 'after', 'with', 'long']
list_letter2=['c', 'a', 'b', 'l']

list_contrast=['before', 'after', 'with', 'long', 'allcontrasts', 'allimages' ]
list_letter=['c', 'a', 'b', 'l', 'x', 'x']
list_method=['only_dw_mean_N4',  'only_b0_mean_N4']


list_contrast=[ 'after' ]
list_letter=['a']
list_method=[ 'only_b0_mean_N4']

epochs=1
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
        
        letter_name=list_letter[idx_contrast]

        print("---------------------------------------------------------------------------------")   
        print('idx_contrast: ',  contrast_name,  ' method_name: ', method_name)
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


        elif (contrast_name == 'allcontrasts'  ):
              
            
              for idx2 in range (0,len(list_contrast2)):
                  
                  contrast_name2=list_contrast2[idx2]
                  letter_name2=list_letter2[idx2]
                  print(idx2, contrast_name2, letter_name2 )

                  if (method_name == 'only_dw_mean_N4'):

                     images_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/'+letter_name2+'*_only_dw_mean_N4.nii.gz'
                     masks_to_find=folder_ex_vivo+'all_64/'+contrast_name2+'/mask_'+letter_name2+'*_dwi.nii.gz' 
                     print(images_to_find)
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

        for p in range(0, len(image_images_1_ok)):
           lala_i=str.replace(image_images_1_ok[p], '/home/valeryozenne/mount/Imagerie/DICOM_DATA/2022-12-20_ExVivoBrain','')
           lala_m=str.replace(mask_images_1_ok[p], '/home/valeryozenne/mount/Imagerie/DICOM_DATA/2022-12-20_ExVivoBrain','')
           print(p,lala_i, lala_m )
        