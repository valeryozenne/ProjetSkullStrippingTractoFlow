#!/bin/bash


. dependencies.sh

# TODO a refaire en améliorant le MASK_INPUT du cas homme

# get user information
declare -a array_with_user_information 
GetUserAndCreateArray array_with_user_information

VALERY=${array_with_user_information[0]}
IMAGERIE=${array_with_user_information[1]}
DICOM=${array_with_user_information[2]}
ANTSXNET=${array_with_user_information[3]}
MINC=${array_with_user_information[4]}

LIST_SAMPLE[0]=9
LIST_SAMPLE[1]=9

LIST_DATA[0]=Gado/
LIST_DATA[1]=Sans_Gado/

LIST_NAME[0]=b
LIST_NAME[1]=c

FORCE=0

# on réachantillone à 64
CreateFolderIfNotExist data_64/

for DATA_INDEX in 0 1
do


DATA=${LIST_DATA[${DATA_INDEX}]}
FOLDER_INPUT_DATA=data/${DATA}
CheckFolder ${FOLDER_INPUT_DATA}

FOLDER_OUTPUT_DATA=data_64/${DATA}
CreateFolderIfNotExist ${FOLDER_OUTPUT_DATA}

rm data_64/${DATA}/liste_de_fichier_pour_ants_64.csv

NUMBER_OF_SAMPLES=${LIST_SAMPLE[${DATA_INDEX}]}
LETTER=${LIST_NAME[${DATA_INDEX}]}
echo $NUMBER_OF_SAMPLES $LETTER

for NUM in {1..9}
do
echo $NUM
FOLDER_INPUT_DATA_NUM=${FOLDER_INPUT_DATA}/${NUM}/
FOLDER_OUTPUT_DATA_NUM=${FOLDER_OUTPUT_DATA}/${NUM}/
CheckFolder ${FOLDER_INPUT_DATA_NUM}
CreateFolderIfNotExist ${FOLDER_OUTPUT_DATA_NUM}

FOLDER_INPUT_DWI=${FOLDER_INPUT_DATA_NUM}/DWI/
FOLDER_OUTPUT_DWI=${FOLDER_OUTPUT_DATA_NUM}/DWI/
CreateFolderIfNotExist ${FOLDER_OUTPUT_DWI}

IMG_INPUT=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi.nii.gz
IMG_INPUT_DENOISED=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised.nii.gz
MASK_INPUT=${FOLDER_INPUT_DWI}/mask_${LETTER}10${NUM}_dwi.nii.gz

CheckFile ${IMG_INPUT}
CheckFile ${MASK_INPUT} 
echo ${IMG_INPUT}
mrinfo ${IMG_INPUT} -size

if [[ ! -f ${IMG_INPUT_DENOISED} ]] || [[ "${FORCE}" = 1 ]] ; then
dwidenoise ${IMG_INPUT} ${IMG_INPUT_DENOISED}
fi

IMG_INPUT_DENOISED_ONLY_B0=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0.nii.gz
IMG_INPUT_DENOISED_ONLY_DW=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_dw.nii.gz

IMG_INPUT_DENOISED_ONLY_B0_MEAN=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0_mean.nii.gz
IMG_INPUT_DENOISED_ONLY_DW_MEAN=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_dw_mean.nii.gz

IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0_mean_N4.nii.gz
IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_dw_mean_N4.nii.gz

# à copier plus tard
IMG_OUTPUT_DENOISED_ONLY_B0_MEAN=${FOLDER_OUTPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0_mean.nii.gz
IMG_OUTPUT_DENOISED_ONLY_DW_MEAN=${FOLDER_OUTPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_dw_mean.nii.gz

IMG_OUTPUT_DENOISED_ONLY_B0_MEAN_N4=${FOLDER_OUTPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0_mean_N4.nii.gz
IMG_OUTPUT_DENOISED_ONLY_DW_MEAN_N4=${FOLDER_OUTPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_dw_mean_N4.nii.gz


if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_B0} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrconvert ${IMG_INPUT_DENOISED} -coord 3 0:1:4 ${IMG_INPUT_DENOISED_ONLY_B0} --force
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_DW} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrconvert ${IMG_INPUT_DENOISED} -coord 3 5:1:end ${IMG_INPUT_DENOISED_ONLY_DW} --force
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_B0_MEAN} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrmath ${IMG_INPUT_DENOISED_ONLY_B0}  mean ${IMG_INPUT_DENOISED_ONLY_B0_MEAN} -axis 3 --force
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_DW_MEAN} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrmath ${IMG_INPUT_DENOISED_ONLY_DW}  mean ${IMG_INPUT_DENOISED_ONLY_DW_MEAN} -axis 3 --force
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ./compute_double_N4.sh ${IMG_INPUT_DENOISED_ONLY_B0_MEAN} ${IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4} /tmp/ 'N' 'OTSU' 4 1
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ./compute_double_N4.sh ${IMG_INPUT_DENOISED_ONLY_DW_MEAN} ${IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4} /tmp/ 'N' 'OTSU' 4 1
fi


# on va aussi utiliser ces données:

if [[ ! -f ${IMG_OUTPUT_DENOISED_ONLY_B0_MEAN} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_DENOISED_ONLY_B0_MEAN} ${IMG_OUTPUT_DENOISED_ONLY_B0_MEAN} 64x64x64 1 0
fi

if [[ ! -f ${IMG_OUTPUT_DENOISED_ONLY_DW_MEAN} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_DENOISED_ONLY_DW_MEAN} ${IMG_OUTPUT_DENOISED_ONLY_DW_MEAN} 64x64x64 1 0
fi

if [[ ! -f ${IMG_OUTPUT_DENOISED_ONLY_B0_MEAN_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4} ${IMG_OUTPUT_DENOISED_ONLY_B0_MEAN_N4} 64x64x64 1 0
fi

if [[ ! -f ${IMG_OUTPUT_DENOISED_ONLY_DW_MEAN_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4} ${IMG_OUTPUT_DENOISED_ONLY_DW_MEAN_N4} 64x64x64 1 0
fi

# on extrait les 5 images b0
for bo_index in {0..4}
do

IMG_INPUT_B0=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0_${bo_index}.nii.gz
MASK_INPUT_B0=${FOLDER_INPUT_DWI}/mask_${LETTER}10${NUM}_dwi_${bo_index}.nii.gz
IMG_INPUT_B0_N4=${FOLDER_INPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0_${bo_index}_N4.nii.gz

IMG_OUTPUT_B0=${FOLDER_OUTPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0_${bo_index}.nii.gz
MASK_OUTPUT_B0=${FOLDER_OUTPUT_DWI}/mask_${LETTER}10${NUM}_dwi_${bo_index}.nii.gz
IMG_OUTPUT_B0_N4=${FOLDER_OUTPUT_DWI}/${LETTER}10${NUM}_dwi_denoised_only_b0_${bo_index}_N4.nii.gz


if [[ ! -f ${IMG_INPUT_B0} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrconvert ${IMG_INPUT_DENOISED_ONLY_B0} -coord 3 ${bo_index} -axes 0,1,2 ${IMG_INPUT_B0}
fi

if [[ ! -f ${IMG_INPUT_B0_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ./compute_double_N4.sh ${IMG_INPUT_B0} ${IMG_INPUT_B0_N4} /tmp/ 'N' 'OTSU' 4 1
fi

if [[ ! -f ${MASK_INPUT_B0} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd cp ${MASK_INPUT}  ${MASK_INPUT_B0}
fi

if [[ ! -f ${IMG_OUTPUT_B0} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_B0} ${IMG_OUTPUT_B0} 64x64x64 1 0
fi

if [[ ! -f ${IMG_OUTPUT_B0_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_B0_N4} ${IMG_OUTPUT_B0_N4} 64x64x64 1 0
fi

if [[ ! -f ${MASK_OUTPUT_B0} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${MASK_INPUT_B0} ${MASK_OUTPUT_B0} 64x64x64 1 1
fi

#mrstats ${IMG_OUTPUT_B0}
if [[ "${bo_index}" == 0 ]] ; then
echo ${IMG_OUTPUT_B0} >> data_64/${DATA}/liste_de_fichier_pour_ants_64.csv
fi

done # boucle b0

mrstats ${MASK_OUTPUT_B0}

done

#CreateFolderIfNotExist template_64/
#CreateFolderIfNotExist template_64/${DATA}/
#FICHIER_TEMPLATE=template_64/${DATA}/MY
#antsMultivariateTemplateConstruction2.sh -d 3 -i 0 -k 1 -w 1  -c 2 -j 3 -t SyN  -m CC -o ${FICHIER_TEMPLATE}  data_64/${DATA}/liste_de_fichier_pour_ants_64.csv


done
