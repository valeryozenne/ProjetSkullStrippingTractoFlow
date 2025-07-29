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

list_contrast[0]='before'
list_contrast[1]='after'
list_contrast[2]='with'
list_contrast[3]='long'


SPECIAL='_allcontrasts'

list_letter[0]='c'
list_letter[1]='a'
list_letter[2]='b'
list_letter[3]='l'
list_letter[4]='x'

list_method[0]='only_b0_mean'
list_method[1]='only_dw_mean'
list_method[2]='only_b0_mean_N4'
list_method[3]='only_dw_mean_N4'

FORCE=1
FOLDER_EXVIVO=${IMAGERIE}/DICOM_DATA/2022-12-20_ExVivoBrain/

for idx_contrast in 0 1 2 3 
do 

CONTRAST=${list_contrast[${idx_contrast}]}
LETTER=${list_letter[${idx_contrast}]}

for idx_method in 2 3
do 

METHOD=${list_method[${idx_method}]}

for NUM in 138
do
echo ${NUM}

if [[ ${METHOD} == 'only_b0_mean' ]] && [[ ${METHOD} != *"N4"* ]]; then
NAME=only_b0_mean
INPUT=all_64/${CONTRAST}/${LETTER}${NUM}_dwi_denoised_only_b0_mean.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_all64_initial/tous/MYtemplate0.nii.gz
MASK=all_64/${CONTRAST}/mask_${LETTER}${NUM}_dwi.nii.gz
elif [[ ${METHOD} == 'only_dw_mean' ]] && [[ ${METHOD} != *"N4"* ]]; then
NAME=only_dw_mean
INPUT=all_64/${CONTRAST}/${LETTER}${NUM}_dwi_denoised_only_dw_mean.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_all64_initial/tous/MYtemplate0.nii.gz
MASK=all_64/${CONTRAST}/mask_${LETTER}${NUM}_dwi.nii.gz
elif [[ ${METHOD} == 'only_b0_mean_N4' ]] && [[ ${METHOD} == *"N4"* ]]; then
NAME=only_b0_mean_N4
INPUT=all_64/${CONTRAST}/${LETTER}${NUM}_dwi_denoised_only_b0_mean_N4.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_all64_initial/tous/MYtemplate0.nii.gz
MASK=all_64/${CONTRAST}/mask_${LETTER}${NUM}_dwi.nii.gz
elif [[ ${METHOD} == 'only_dw_mean_N4' ]] && [[ ${METHOD} == *"N4"* ]]; then
NAME=only_dw_mean_N4
INPUT=all_64/${CONTRAST}/${LETTER}${NUM}_dwi_denoised_only_dw_mean_N4.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_all64_initial/tous/MYtemplate0.nii.gz
MASK=all_64/${CONTRAST}/mask_${LETTER}${NUM}_dwi.nii.gz
fi

if [[ ${SPECIAL} == '_allcontrasts' ]]; then
MODEL=${FOLDER_EXVIVO}/modelall_64/mouseExVivoBrainExtraction${SPECIAL}_${NAME}_server_july2025.h5
else
MODEL=${FOLDER_EXVIVO}/modelall_64/mouseExVivoBrainExtraction_${CONTRAST}_${NAME}_server_july2025.h5
fi

OUTPUT_MASK=Prediction_real/outputMouseExVivoBraintProbabilityMask_${CONTRAST}_${NAME}.nii.gz
OUTPUT_FINAL_MASK=Prediction_real/outputMouseExVivoBraintFinalMask_${CONTRAST}_${NAME}.nii.gz


CheckFile ${MASK}
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


logCmd LabelOverlapMeasures 3 ${OUTPUT_FINAL_MASK}  ${MASK}
CreateFolderIfNotExist Figures_all/
if [[ ! -f Figures_new/figure_brain_m${NUM}_segmentation_${CONTRAST}_${NAME}_S${SAMPLE}_0000.png ]] || [[ ${FORCE} -eq 1 ]] ;  then
logCmd mrview ${INPUT} -size 1800,600 -fov 30 -config MRViewOrthoAsRow 1   -overlay.load ${OUTPUT_FINAL_MASK} -overlay.opacity 0.25  -overlay.threshold_min 0.5 -overlay.interpolation 0 -overlay.colourmap 4 \
              -noannotations -mode 2 -capture.folder Figures_all/ \
             -capture.prefix figure_brain_m${NUM}_segmentation_${CONTRAST}_${NAME}_S${SAMPLE}${SPECIAL}_ \
              -capture.grab  -noannotations  --force  -exit
fi

done # boucle sur les NUM

done # boucle sur les modèles

done # boucle sur les contrastes
