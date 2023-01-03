#!/bin/bash


# usefull link : https://opensource.com/article/19/10/programming-bash-loops


function CheckStrides() {
    
    NDIM=$(mrinfo $1 -ndim)
    STRIDES=$(mrinfo $1 -strides)

    echo $NDIM" ->  "$STRIDES
    if [[ ${NDIM} -eq 3 ]]; then
    #echo 'ici 3'
    if [ "${STRIDES}" != "1 2 3" ];  then
    echo "ERROR: $1 strides wrong $STRIDES."
    exit
    fi
    elif [[ ${NDIM} -eq 4 ]]; then 
    #echo 'ici 4'
    if [ "${STRIDES}" != "1 2 3 4" ];  then
    echo "ERROR: $1 strides wrong $STRIDES."
    exit
    fi
    elif [[ ${NDIM} -eq 5 ]]; then    
    #echo 'ici 5'
    if [ "${STRIDES}" != "1 2 3 4 5" ];  then
    echo "ERROR: $1 strides wrong $STRIDES."
    exit
    fi
    fi

}



function CheckImageSize() {  


  return 0
}



function getHalfFov() {

LANGUAGE=$(locale  | grep "LANG=")
#echo ${LANGUAGE}
#if [ "${LANGUAGE}" == "LANG=fr_FR.UTF-8" ] 
#then
#echo 'france awk comma'
#elif [ "${LANGUAGE}" == "LANG=C.UTF-8" ] 
#then
#echo 'english awk comma'
#fi

#SPACING=$(mrinfo $1 -spacing)
DIMENSION=$(mrinfo $1 -size)

if [ "${LANGUAGE}" == "LANG=fr_FR.UTF-8" ] 
then
SPACING_X=$(echo $2 | sed 's/\./,/g')
SPACING_Y=$(echo $2 | sed 's/\./,/g')
SPACING_Z=$(echo $2 | sed 's/\./,/g')
else
SPACING_X=$2
SPACING_Y=$2
SPACING_Z=$2

fi


#echo spacing ${SPACING_X} ${SPACING_Y} ${SPACING_Z} 

DIM_X=$(echo ${DIMENSION} | awk '{print $1}') 
DIM_Y=$(echo ${DIMENSION} | awk '{print $2}') 
DIM_Z=$(echo ${DIMENSION} | awk '{print $3}')

#echo dimensions ${DIM_X} ${DIM_Y} ${DIM_Z} 

FOVX=$(echo $DIM_X $SPACING_X | awk '{printf "%4.3f\n",$1*$2}')
FOVY=$(echo $DIM_Y $SPACING_Y | awk '{printf "%4.3f\n",$1*$2}')
FOVZ=$(echo $DIM_Z $SPACING_Z | awk '{printf "%4.3f\n",$1*$2}')

#echo fov ${FOVX} ${FOVY} ${FOVZ} 

if [ "${LANGUAGE}" == "LANG=fr_FR.UTF-8" ] 
then

DEMI_FOVX=$(echo $DIM_X $SPACING_X | awk '{printf "%4.3f\n",$1*$2/2-$2/2}'| sed 's/,/\./g')
DEMI_FOVY=$(echo $DIM_Y $SPACING_Y | awk '{printf "%4.3f\n",$1*$2/2-$2/2}'| sed 's/,/\./g')
DEMI_FOVZ=$(echo $DIM_Z $SPACING_Z | awk '{printf "%4.3f\n",$1*$2/2-$2/2}'| sed 's/,/\./g')
else
DEMI_FOVX=$(echo $DIM_X $SPACING_X | awk '{printf "%4.3f\n",$1*$2/2-$2/2}')
DEMI_FOVY=$(echo $DIM_Y $SPACING_Y | awk '{printf "%4.3f\n",$1*$2/2-$2/2}')
DEMI_FOVZ=$(echo $DIM_Z $SPACING_Z | awk '{printf "%4.3f\n",$1*$2/2-$2/2}')
fi


echo $DEMI_FOVX $DEMI_FOVY $DEMI_FOVZ


}


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


function CheckFolder() {

    if [[ ! -d $1 ]]
    then
    echo "ERROR: $1 does not exist."

    exit
 
    fi
}

function CreateFolderIfNotExist() {

    if [[ ! -d $1 ]]
    then
    echo "Warning: $1 does not exist."

    mkdir $1
 
    fi
}


err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}


#https://stackoverflow.com/questions/10582763/how-to-return-an-array-in-bash-without-using-globals

create_array() {
    local -n arr=$1             # use nameref for indirection
    arr=(one "two three" four)
}


use_array() {
    local my_array
    GetUserAndCreateArray my_array       # call function to populate the array
    #echo "inside use_array"
    #declare -p my_array         # test the array
    #echo ${my_array[0]}
    #echo ${my_array[1]}
    #echo ${my_array[2]}
    #echo ${my_array[3]}
    #return my_array
}


function GetUserAndCreateArray() {


if [ $USER = "valeryozenne" ]
then
VALERY=/home/$USER/mount/Valery/
IMAGERIE=/home/$USER/mount/Imagerie/
DICOM=/home/$USER/mount/Dicom/
ANTXNET=/home/Partage/Dev/ANTsXNet/
MINC=/home/Partage/Dev/minc-toolkit-extras/
elif  [ $USER = "valery" ]
then
VALERY=/home/$USER/Reseau/Valery/
IMAGERIE=/home/$USER/Reseau/Imagerie/
DICOM=/home/$USER/Reseau/Dicom/
MINC=/home/$USER/Dev/minc-toolkit-extras/
elif  [ $USER = "vozenne" ]
then
VALERY=/home/$USER/Reseau/Valery/
IMAGERIE=/home/$USER/Reseau/Imagerie/
DICOM=/home/$USER/Reseau/Dicom/
ANTXNET=/home/$USER/Dev/ANTsXNet/
MINC=/home/$USER/Dev/minc-toolkit-extras/
elif  [ $USER = "imagerie" ]
then
VALERY=/home/$USER/Reseau/Valery/
IMAGERIE=/home/$USER/Reseau/Imagerie/
DICOM=/home/$USER/Reseau/Dicom/
ANTXNET=/home/$USER/Dev/ANTsXNet/
MINC=/home/$USER/Dev/minc-toolkit-extras/
else
figlet problem 
exit -1
fi 

local -n arr=$1  
arr=(${VALERY} ${IMAGERIE} ${DICOM} ${ANTXNET} ${MINC})

echo '---------------------------'
echo ${VALERY}
echo ${IMAGERIE}
echo ${DICOM}
echo ${ANTXNET}
echo ${MINC}

}




main() {
  ARG1=$1
  ARG2=$2
  #
  echo "Running '$RUNNING'..."
  echo "script() - all args:  $@"
  echo "script() -     ARG1:  $ARG1"
  echo "script() -     ARG2:  $ARG2"
  #
  #foo
  #bar
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  echo '----------------------------------------------------'
  echo 'Depencies.sh on: passe par la  , le main est appele, tout va bien'
  echo '----------------------------------------------------'
  main "$@"
else
  echo '----------------------------------------------------'
  echo 'Depencies.sh: on passe ici , le main n est pas appele'   
  echo '----------------------------------------------------'
fi

