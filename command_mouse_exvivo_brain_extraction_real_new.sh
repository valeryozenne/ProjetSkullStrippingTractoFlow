#!/bin/bash

. dependencies.sh

# get user information
declare -a array_with_user_information 
GetUserAndCreateArray array_with_user_information

VALERY=${array_with_user_information[0]}
IMAGERIE=${array_with_user_information[1]}
DICOM=${array_with_user_information[2]}
ANTSXNET=${array_with_user_information[3]}
MINC=${array_with_user_information[4]}

CreateFolderIfNotExist Prediction_real/
CreateFolderIfNotExist Figures_real/

list_contrast[0]='Gado'
list_contrast[1]='Sans_Gado'

list_letter[0]='b'
list_letter[1]='m'

list_method[0]='only_b0'
list_method[1]='only_b0_mean'
list_method[2]='only_dw_mean'
list_method[3]='only_b0_N4'
list_method[4]='only_b0_mean_N4'
list_method[5]='only_dw_mean_N4'

FORCE=0
FOLDER_EXVIVO=${IMAGERIE}/DICOM_DATA/2022-12-20_ExVivoBrain/

for idx_contrast in 1 
do 

CONTRAST=${list_contrast[${idx_contrast}]}
LETTER=${list_letter[${idx_contrast}]}

for idx_method in 2 5 0 3
do 

METHOD=${list_method[${idx_method}]}

for NUM in {36..39}
do
echo ${NUM}

if [[ ${METHOD} == 'only_b0' ]] && [[ ${METHOD} != *"N4"* ]]; then
NAME=only_b0
INPUT=new_64/Sans_Gado/${NUM}//DWI/m${NUM}__dwi_denoised_only_b0.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_b0/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_b0_mean' ]] && [[ ${METHOD} != *"N4"* ]]; then
NAME=only_b0_mean
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_b0_mean/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_dw_mean' ]] && [[ ${METHOD} != *"N4"* ]]; then
NAME=only_dw_mean
INPUT=new_64/Sans_Gado/${NUM}//DWI/m${NUM}__dwi_denoised_only_dw_mean.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_dw_mean/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_b0_N4' ]] && [[ ${METHOD} == *"N4"* ]]; then
NAME=only_b0_N4
INPUT=new_64/Sans_Gado/${NUM}//DWI/m${NUM}__dwi_denoised_only_b0_N4.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_b0/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_b0_mean_N4' ]] && [[ ${METHOD} == *"N4"* ]]; then
NAME=only_b0_mean_N4
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_b0_mean/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_dw_mean_N4' ]] && [[ ${METHOD} == *"N4"* ]]; then
NAME=only_dw_mean_N4
INPUT=new_64/Sans_Gado/${NUM}//DWI//m${NUM}__dwi_denoised_only_dw_mean_N4.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_dw_mean/MYtemplate0.nii.gz
fi

MODEL=${FOLDER_EXVIVO}/model_64/mouseExVivoBrainExtraction_${CONTRAST}_${NAME}_server_jan2023.h5
OUTPUT_MASK=Prediction_real/outputMouseExVivoBraintProbabilityMask_${CONTRAST}_${NAME}.nii.gz
OUTPUT_FINAL_MASK=Prediction_real/outputMouseExVivoBraintFinalMask_${CONTRAST}_${NAME}.nii.gz

CheckFile ${MODEL}
CheckFile ${TEMPLATE}
CheckFile ${INPUT}


if [[ ! -f ${OUTPUT_MASK} ]] || [[ ${FORCE} -eq 1 ]] ;  then
logCmd python3 doMouseExVivoBrainExtraction.py ${INPUT} ${OUTPUT_MASK} ${TEMPLATE} ${MODEL}
fi

if [[ ! -f ${OUTPUT_FINAL_MASK} ]] || [[ ${FORCE} -eq 1 ]] ;  then
logCmd ThresholdImage 3 ${OUTPUT_MASK} ${OUTPUT_FINAL_MASK} 0.5 1 1 0
logCmd ImageMath 3 ${OUTPUT_FINAL_MASK} GetLargestComponent ${OUTPUT_FINAL_MASK}
fi

if [[ ! -f Figures_new/figure_brain_m${NUM}_segmentation_${CONTRAST}_${NAME}_S${SAMPLE}_0000.png ]] || [[ ${FORCE} -eq 1 ]] ;  then
logCmd mrview ${INPUT} -fov 30 -config MRViewOrthoAsRow 1   -overlay.load ${OUTPUT_FINAL_MASK} -overlay.opacity 0.25  -overlay.threshold_min 0.5 -overlay.interpolation 0 -overlay.colourmap 4 \
              -noannotations -mode 2 -capture.folder Figures_new/ \
              -capture.prefix figure_brain_m${NUM}_segmentation_${CONTRAST}_${NAME}_S${SAMPLE}_ \
              -capture.grab  -noannotations  --force  -exit
fi

done # boucle sur les NUM

done # boucle sur les modèles

done # boucle sur les contrastes