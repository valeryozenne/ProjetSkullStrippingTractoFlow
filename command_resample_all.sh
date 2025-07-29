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

LIST_SAMPLE[0]=11
LIST_SAMPLE[1]=11
LIST_SAMPLE[2]=11
LIST_SAMPLE[3]=7

LIST_DATA[0]=before/
LIST_DATA[1]=after/
LIST_DATA[2]=with/
LIST_DATA[3]=long/

LIST_NAME[0]=c
LIST_NAME[1]=a
LIST_NAME[2]=b
LIST_NAME[3]=l

FORCE=0
MAKE_TEMPLATE_INITIAL=1
MAKE_TEMPLATE_ALIGNED=0
MAKE_TEMPLATE_FINAL=0
FORCE_TEMPLATE_CREATION=1

# on réachantillone à 64
CreateFolderIfNotExist all_128/
CreateFolderIfNotExist all_64/

for DATA_INDEX in 3
do

DATA=${LIST_DATA[${DATA_INDEX}]}
FOLDER_INPUT_DATA=all/${DATA}
CheckFolder ${FOLDER_INPUT_DATA}

FOLDER_OUTPUT_DATA=all_128/${DATA}
CreateFolderIfNotExist ${FOLDER_OUTPUT_DATA}
FOLDER_RESAMPLE_DATA=all_64/${DATA}
CreateFolderIfNotExist ${FOLDER_RESAMPLE_DATA}

rm all_64/${DATA}/liste_de_fichier_pour_ants_64.csv
rm all_64/${DATA}/liste_de_fichier_pour_ants_64_b0_mean.csv
rm all_64/${DATA}/liste_de_fichier_pour_ants_64_dw_mean.csv

rm all_64/${DATA}/liste_de_fichier_pour_ants_raw.csv
rm all_64/${DATA}/liste_de_fichier_pour_ants_raw_b0_mean.csv
rm all_64/${DATA}/liste_de_fichier_pour_ants_raw_dw_mean.csv


NUMBER_OF_SAMPLES=${LIST_SAMPLE[${DATA_INDEX}]}
LETTER=${LIST_NAME[${DATA_INDEX}]}
echo $NUMBER_OF_SAMPLES $LETTER


LISTE_DOSSIER=$(ls ${FOLDER_INPUT_DATA}/)

for NUM_DOSSIER in ${LISTE_DOSSIER}
do
echo $NUM_DOSSIER
FOLDER_INPUT_DATA_NUM=${FOLDER_INPUT_DATA}/${NUM_DOSSIER}/
FOLDER_OUTPUT_DATA_NUM=${FOLDER_OUTPUT_DATA}/${NUM_DOSSIER}/
CheckFolder ${FOLDER_INPUT_DATA_NUM}
CreateFolderIfNotExist ${FOLDER_OUTPUT_DATA_NUM}

FOLDER_INPUT_DWI=${FOLDER_INPUT_DATA_NUM}/DWI/
FOLDER_OUTPUT_DWI=${FOLDER_OUTPUT_DATA_NUM}/DWI/
CreateFolderIfNotExist ${FOLDER_OUTPUT_DWI}

IMG_INPUT=${FOLDER_INPUT_DATA_NUM}/${LETTER}*_dwi.nii.gz
MASK_INPUT=${FOLDER_INPUT_DATA_NUM}/${LETTER}*_mask.nii.gz
echo ${IMG_INPUT}
CheckFile ${IMG_INPUT}
echo ${MASK_INPUT}
CheckFile ${MASK_INPUT}

NOM_DE_BASE=$(echo ${IMG_INPUT} | rev | cut -d "/" -f 1 | rev)
MASK_DE_BASE=$(echo ${IMG_INPUT} | rev | cut -d "/" -f 1 | rev)
 
NOM_DENOISED_ONLY_B0=$(echo ${NOM_DE_BASE} | sed 's/.nii.gz/_denoised_only_b0.nii.gz/g' )
NOM_DENOISED_ONLY_DW=$(echo ${NOM_DE_BASE} | sed 's/.nii.gz/_denoised_only_dw.nii.gz/g' ) 
NOM_DENOISED_ONLY_B0_MEAN=$(echo ${NOM_DE_BASE} | sed 's/.nii.gz/_denoised_only_b0_mean.nii.gz/g' )
NOM_DENOISED_ONLY_DW_MEAN=$(echo ${NOM_DE_BASE} | sed 's/.nii.gz/_denoised_only_dw_mean.nii.gz/g' )
NOM_DENOISED_ONLY_B0_MEAN_N4=$(echo ${NOM_DE_BASE} | sed 's/.nii.gz/_denoised_only_b0_mean_N4.nii.gz/g' )
NOM_DENOISED_ONLY_DW_MEAN_N4=$(echo ${NOM_DE_BASE} | sed 's/.nii.gz/_denoised_only_dw_mean_N4.nii.gz/g' )

IMG_INPUT_DENOISED_ONLY_B0=${FOLDER_OUTPUT_DWI}/${NOM_DENOISED_ONLY_B0}
IMG_INPUT_DENOISED_ONLY_DW=${FOLDER_OUTPUT_DWI}/${NOM_DENOISED_ONLY_DW}
IMG_INPUT_DENOISED_ONLY_B0_MEAN=${FOLDER_OUTPUT_DWI}/${NOM_DENOISED_ONLY_B0_MEAN}
IMG_INPUT_DENOISED_ONLY_DW_MEAN=${FOLDER_OUTPUT_DWI}/${NOM_DENOISED_ONLY_DW_MEAN}


#echo ${IMG_INPUT_DENOISED_ONLY_B0}
#echo ${IMG_INPUT_DENOISED_ONLY_DW}
#echo ${IMG_INPUT_DENOISED_ONLY_B0_MEAN}
#echo ${IMG_INPUT_DENOISED_ONLY_DW_MEAN}

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_B0} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrconvert ${IMG_INPUT} -coord 3 0:1:4 ${IMG_INPUT_DENOISED_ONLY_B0} --force
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_DW} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrconvert ${IMG_INPUT} -coord 3 5:1:end ${IMG_INPUT_DENOISED_ONLY_DW} --force
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_B0_MEAN} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrmath ${IMG_INPUT_DENOISED_ONLY_B0}  mean ${IMG_INPUT_DENOISED_ONLY_B0_MEAN} -axis 3 --force
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_DW_MEAN} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd mrmath ${IMG_INPUT_DENOISED_ONLY_DW}  mean ${IMG_INPUT_DENOISED_ONLY_DW_MEAN} -axis 3 --force
fi

CheckFile ${IMG_INPUT_DENOISED_ONLY_B0}
CheckFile ${IMG_INPUT_DENOISED_ONLY_B0_MEAN}
CheckFile ${IMG_INPUT_DENOISED_ONLY_DW}
CheckFile ${IMG_INPUT_DENOISED_ONLY_DW_MEAN}


MASK_RESAMPLE=${FOLDER_RESAMPLE_DATA}/mask_${MASK_DE_BASE}

# sans N4 resample
if [[ ! -f ${MASK_RESAMPLE} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${MASK_INPUT} ${MASK_RESAMPLE} 64x96x64 1 1
fi

IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4=${FOLDER_OUTPUT_DWI}/${NOM_DENOISED_ONLY_B0_MEAN_N4}
IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4=${FOLDER_OUTPUT_DWI}/${NOM_DENOISED_ONLY_DW_MEAN_N4}
echo ${IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4}
echo ${IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4}


if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ./compute_double_N4.sh ${IMG_INPUT_DENOISED_ONLY_B0_MEAN} ${IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4} /tmp/ 'N' 'OTSU' 4 1
fi

if [[ ! -f ${IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ./compute_double_N4.sh ${IMG_INPUT_DENOISED_ONLY_DW_MEAN} ${IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4} /tmp/ 'N' 'OTSU' 4 1
fi


IMG_RESAMPLE_DENOISED_ONLY_B0_MEAN=${FOLDER_RESAMPLE_DATA}/${NOM_DENOISED_ONLY_B0_MEAN}
IMG_RESAMPLE_DENOISED_ONLY_DW_MEAN=${FOLDER_RESAMPLE_DATA}/${NOM_DENOISED_ONLY_DW_MEAN}
IMG_RESAMPLE_DENOISED_ONLY_B0_MEAN_N4=${FOLDER_RESAMPLE_DATA}/${NOM_DENOISED_ONLY_B0_MEAN_N4}
IMG_RESAMPLE_DENOISED_ONLY_DW_MEAN_N4=${FOLDER_RESAMPLE_DATA}/${NOM_DENOISED_ONLY_DW_MEAN_N4}

# sans N4 resample
if [[ ! -f ${IMG_RESAMPLE_DENOISED_ONLY_B0_MEAN} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_DENOISED_ONLY_B0_MEAN} ${IMG_RESAMPLE_DENOISED_ONLY_B0_MEAN} 64x96x64 1 0
fi

if [[ ! -f ${IMG_RESAMPLE_DENOISED_ONLY_DW_MEAN} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_DENOISED_ONLY_DW_MEAN} ${IMG_RESAMPLE_DENOISED_ONLY_DW_MEAN} 64x96x64 1 0
fi

# avec N4 resample 

if [[ ! -f ${IMG_RESAMPLE_DENOISED_ONLY_B0_MEAN_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_DENOISED_ONLY_B0_MEAN_N4} ${IMG_RESAMPLE_DENOISED_ONLY_B0_MEAN_N4} 64x96x64 1 0
fi

if [[ ! -f ${IMG_RESAMPLE_DENOISED_ONLY_DW_MEAN_N4} ]] || [[ "${FORCE}" = 1 ]] ; then
logCmd ResampleImage 3 ${IMG_INPUT_DENOISED_ONLY_DW_MEAN_N4} ${IMG_RESAMPLE_DENOISED_ONLY_DW_MEAN_N4} 64x96x64 1 0
fi


done # boucle sur les acquisitions

done # boucle sur les dossiers de contrastes


echo ''
echo 'template'
echo ''

for CONTRAST in b0_ dw_
do
TEMPLATE_FOLDER=template_all64
TEMPLATE_ALIGNED_FOLDER=template_all64_aligned
TEMPLATE_INITIAL_FOLDER=template_all64_${CONTRAST}initial

CreateFolderIfNotExist ${TEMPLATE_INITIAL_FOLDER}/
CreateFolderIfNotExist ${TEMPLATE_INITIAL_FOLDER}/tous/

find all_64/* -name "*.nii.gz"  | grep -v "mask" | grep -v "mean.nii.gz"  | grep "${CONTRAST}" >  all_64/liste_de_tous_les_fichiers_${CONTRAST}pour_ants_64.csv

wc -l all_64/liste_de_tous_les_fichiers_${CONTRAST}pour_ants_64.csv

cat all_64/liste_de_tous_les_fichiers_${CONTRAST}pour_ants_64.csv

if [[ ${MAKE_TEMPLATE_INITIAL} -eq 1 ]] ; then

FICHIER_TEMPLATE=${TEMPLATE_INITIAL_FOLDER}/tous/MY
if [[ ! -f ${FICHIER_TEMPLATE}template0.nii.gz ]] || [[ "${FORCE_TEMPLATE_CREATION}" = 1 ]] ; then

antsMultivariateTemplateConstruction2.sh -d 3 -i 4 -k 1 -w 1  -c 2 -j 20 -t SyN  -m CC -o ${FICHIER_TEMPLATE}  all_64/liste_de_tous_les_fichiers_${CONTRAST}pour_ants_64.csv

fi

fi
done









