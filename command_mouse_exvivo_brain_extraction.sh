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

CreateFolderIfNotExist Prediction/
CreateFolderIfNotExist Figures/
CreateFolderIfNotExist Tables/

FORCE=0

#
SAMPLE=9

list_contrast[0]='Gado'
list_contrast[1]='Sans_Gado'

list_letter[0]='b'
list_letter[1]='c'

list_method[0]='only_b0'
list_method[1]='only_b0_mean'
list_method[2]='only_dw_mean'
list_method[3]='only_b0_N4'
list_method[4]='only_b0_mean_N4'
list_method[5]='only_dw_mean_N4'

FOLDER_EXVIVO=${IMAGERIE}/DICOM_DATA/2022-12-20_ExVivoBrain/


for idx_contrast in 0 1 
do 

CONTRAST=${list_contrast[${idx_contrast}]}
LETTER=${list_letter[${idx_contrast}]}

TRUTH=${FOLDER_EXVIVO}/data/${CONTRAST}/${SAMPLE}/DWI/mask_${LETTER}10${SAMPLE}_dwi.nii.gz
CheckFile ${TRUTH}

for idx_method in 0 1 2 3 4 5
do 

METHOD=${list_method[${idx_method}]}

if [[ ${METHOD} == 'only_b0' ]] && [[ ${METHOD} != *"N4"* ]]; then
NAME=only_b0
INPUT=${FOLDER_EXVIVO}/data/${CONTRAST}/${SAMPLE}/DWI/${LETTER}10${SAMPLE}_dwi_denoised_only_b0_0.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_b0/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_b0_mean' ]] && [[ ${METHOD} != *"N4"* ]]; then
NAME=only_b0_mean
INPUT=${FOLDER_EXVIVO}/data/${CONTRAST}/${SAMPLE}/DWI/${LETTER}10${SAMPLE}_dwi_denoised_${NAME}.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_b0_mean/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_dw_mean' ]] && [[ ${METHOD} != *"N4"* ]]; then
NAME=only_dw_mean
INPUT=${FOLDER_EXVIVO}/data/${CONTRAST}/${SAMPLE}/DWI/${LETTER}10${SAMPLE}_dwi_denoised_${NAME}.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_dw_mean/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_b0_N4' ]] && [[ ${METHOD} == *"N4"* ]]; then
NAME=only_b0_N4
INPUT=${FOLDER_EXVIVO}/data/${CONTRAST}/${SAMPLE}/DWI/${LETTER}10${SAMPLE}_dwi_denoised_only_b0_0_N4.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_b0/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_b0_mean_N4' ]] && [[ ${METHOD} == *"N4"* ]]; then
NAME=only_b0_mean_N4
INPUT=${FOLDER_EXVIVO}/data/${CONTRAST}/${SAMPLE}/DWI/${LETTER}10${SAMPLE}_dwi_denoised_${NAME}.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_b0_mean/MYtemplate0.nii.gz
elif [[ ${METHOD} == 'only_dw_mean_N4' ]] && [[ ${METHOD} == *"N4"* ]]; then
NAME=only_dw_mean_N4
INPUT=${FOLDER_EXVIVO}/data/${CONTRAST}/${SAMPLE}/DWI/${LETTER}10${SAMPLE}_dwi_denoised_${NAME}.nii.gz
TEMPLATE=${FOLDER_EXVIVO}/template_64/${CONTRAST}/only_dw_mean/MYtemplate0.nii.gz
fi

MODEL=${FOLDER_EXVIVO}/model_64/mouseExVivoBrainExtraction_${CONTRAST}_${NAME}_server_dec2022.h5
OUTPUT_MASK=Prediction/outputMouseExVivoBraintProbabilityMask_${CONTRAST}_${NAME}.nii.gz

CheckFile ${MODEL}
CheckFile ${TEMPLATE}
CheckFile ${INPUT}


if [[ ! -f ${OUTPUT_MASK} ]] || [[ ${FORCE} -eq 1 ]] ;  then
logCmd python3 doMouseExVivoBrainExtraction.py ${INPUT} ${OUTPUT_MASK} ${TEMPLATE} ${MODEL}
fi
# ajouter la capture avec mrview
#mrview ${INPUT} -overlay.load ${OUTPUT_MASK} -overlay.opacity 0.5 -overlay.load ${TRUTH} -overlay.opacity 0.5

if [[ ! -f Figures/figure_brain_segmentation_${CONTRAST}_${NAME}_0000.png ]] || [[ ${FORCE} -eq 1 ]] ;  then
logCmd mrview ${INPUT}   -overlay.load ${OUTPUT_MASK} -overlay.opacity 0.25 -overlay.colourmap 4 \
              -noannotations -mode 2 -capture.folder Figures/ \
              -capture.prefix figure_brain_segmentation_${CONTRAST}_${NAME}_ \
              -capture.grab  -noannotations  --force  -exit
fi

LABEL1=${OUTPUT_MASK}
LABEL2=${TRUTH}
CheckFile ${LABEL1}
CheckFile ${LABEL2}
#logCmd ImageMath 3 Tables/table_${CONTRAST}_${NAME}.txt DiceAndMinDistSum ${LABEL1} ${LABEL2}
#DICE_INI=$(cat ${LIST_NAME[$i]}_Table/test.txt | awk '{print $3}')

done 

done




