#!/bin/bash

# Get the input for current subject
subject=${1}

# Load apptainer for singularity
module load apptainer/1.1.8

# Separate different sections of the input string
IFS=',' read -r subject_id subject_folder subject_squash <<< ${subject}

# Define singularity image (containing ANTs and FSL) and squash file for the current subject
IMG=./containers_scilus_1.4.0.sif
SQUASH="--overlay /lustre03/project/rpp-aevans-ab/neurohub/ukb/new/Derived/tractoflow_out/${subject_squash}:ro"

# Define and create subject's input and output folder paths
subject_folder_path="/tractoflow_results/${subject_folder}"
mkdir /home/houmanaz/scratch/WM_Regionwise_Pipeline/outputs_DWI/${subject_folder}
outputdir_sing="/outputs_DWI/${subject_folder}"

# Start singularity and run process_DTI.sh file
singularity exec -B /home/houmanaz/scratch/WM_Regionwise_Pipeline/outputs_DWI/:/outputs_DWI/ ${SQUASH} ${IMG} /outputs_DWI/process_DTI.sh ${subject_folder_path} ${outputdir_sing}
