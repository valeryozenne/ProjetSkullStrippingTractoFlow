#!/bin/bash


function logCmd() {
  cmd="$@"
  echo "BEGIN >>>>>>>>>>>>>>>>>>>>"
  echo $cmd
  # Preserve quoted parameters by running "$@" instead of $cmd
  ( "$@" )

  cmdExit=$?

  if [[ $cmdExit -gt 0 ]];
    then
      echo "ERROR: command exited with nonzero status $cmdExit"
      echo "Command: $cmd"
      echo
      if [[ ! $DEBUG_MODE -gt 0 ]];
        then
          exit 1
        fi
    fi

  echo "END   <<<<<<<<<<<<<<<<<<<<"
  echo
  echo

  return $cmdExit
}

function CheckFile() {

    if [[ ! -f $1 ]]
    then
    echo "ERROR: $1 does not exist."

    exit
 
    fi
}
  
  echo "nous utilisons la fonction extract_metrics_from_tensor" 
  echo "Nombres de paramètres : $#"
  echo "INPUT" : $1
  echo "OUTPUT : $2"  
  echo "TMP : $3"  
  echo "TEST: $4"
  echo "OTSU : $5"  
  echo "THRESHOLD: $6"
  
 
  INPUT=$1
  OUTPUT_N4=$2  
  TMP=$3
  OUTPUT_N4_FIRST=$(echo ${OUTPUT_N4}| sed "s/_N4.nii.gz/_first_N4.nii.gz/g")
  TEST=$4
  OTSU=$5
  PARAMETERA=$6
  PARAMETERB=$6
  TIME=$(date +%H_%M_%S)
   

  echo ${OUTPUT_N4_FIRST}
  
  if [ ${TEST} = "Y" ];
  then
  CONVERGENCE_1=2x2x2x2
  CONVERGENCE_2=4x4x4x4
  else
  CONVERGENCE_1=100x100x100x100
  CONVERGENCE_2=200x200x200x200
 fi



MASK_OTSU_RESAMPLED_FIRST=${TMP}/mask_otsu_first.nii.gz
MASK_OTSU_RESAMPLED_SECOND=${TMP}/mask_otsu_second.nii.gz

if [ ${OTSU} = "OTSU" ];
then
logCmd ThresholdImage 3 ${INPUT} ${MASK_OTSU_RESAMPLED_FIRST}  Otsu ${PARAMETERA}
else
logCmd ThresholdImage 3 ${INPUT} ${MASK_OTSU_RESAMPLED_FIRST}  ${PARAMETERB} Inf 1 0
fi

logCmd ThresholdImage 3 ${MASK_OTSU_RESAMPLED_FIRST} ${MASK_OTSU_RESAMPLED_FIRST} 1 Inf 1 0
logCmd ImageMath 3 ${MASK_OTSU_RESAMPLED_FIRST} GetLargestComponent ${MASK_OTSU_RESAMPLED_FIRST}


logCmd N4BiasFieldCorrection  -d 3  -i ${INPUT}  -o ${OUTPUT_N4_FIRST}  -s 4 -b [80,3] -c [${CONVERGENCE_1},1e-6] -x ${MASK_OTSU_RESAMPLED_FIRST}  -v

if [ ${OTSU} = "OTSU" ];
then
logCmd ThresholdImage 3 ${OUTPUT_N4_FIRST} ${MASK_OTSU_RESAMPLED_SECOND}  Otsu ${PARAMETERA}
else
logCmd ThresholdImage 3 ${OUTPUT_N4_FIRST} ${MASK_OTSU_RESAMPLED_SECOND}  ${PARAMETERB} Inf 1 0
fi

logCmd ThresholdImage 3 ${MASK_OTSU_RESAMPLED_SECOND} ${MASK_OTSU_RESAMPLED_SECOND} 1 Inf 1 0
logCmd ImageMath 3 ${MASK_OTSU_RESAMPLED_SECOND} GetLargestComponent ${MASK_OTSU_RESAMPLED_SECOND}


logCmd N4BiasFieldCorrection  -d 3  -i ${OUTPUT_N4_FIRST}  -o ${OUTPUT_N4}  -s 2 -b [80,3] -c [${CONVERGENCE_2},1e-6] -x ${MASK_OTSU_RESAMPLED_SECOND} -v

