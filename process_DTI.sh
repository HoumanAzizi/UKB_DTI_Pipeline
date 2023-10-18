#!/bin/bash

set -euo pipefail

subject=${1}
outputdir=${2}

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$(nproc)

# Define all the atlas locations
model=/outputs_DWI/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz
model_mask=/outputs_DWI/mni_icbm152_t1_tal_nlin_asym_09c_mask.nii.gz


# Find all the .nii.gz files within the MASKS directory and output their names to a CSV file
# NOTE: all the masks should be nii.gz and they should not be any subdirectory
MASK_FILES=(/outputs_DWI/MASKS/*.nii.gz)
printf '%s\n' "${MASK_FILES[@]##*/}" > ${outputdir}/MASK_Output_Order.csv

# Define current subject's T1w and B0 images location
t1=/outputs_DWI/t1w/$(basename ${subject})_T1w.nii.gz
b0=${subject}/Resample_B0/$(basename ${subject})__b0_resampled.nii.gz


# Non-linearly register subject T1w image to the atlas model image
# Note: for all registrations, check if it has already been done and skip it
if [[ ! -s ${outputdir}/$(basename ${t1} .nii.gz)_to_$(basename ${model} .nii.gz)_1Warp.nii.gz ]]; then
        antsRegistrationSyN.sh -d 3 \
            -m ${t1} \
            -f ${model} \
	    -x ${model_mask} \
            -o ${outputdir}/$(basename ${t1} .nii.gz)_to_$(basename ${model} .nii.gz)_
fi


# Linearly register subject B0 image to the subject T1w image
if [[ ! -s ${outputdir}/$(basename ${b0} .nii.gz)_to_$(basename ${t1} .nii.gz)_0GenericAffine.mat ]]; then
	antsRegistrationSyN.sh -d 3 \
		-m ${b0} \
		-f ${t1} \
		-t r \
    -o ${outputdir}/$(basename ${b0} .nii.gz)_to_$(basename ${t1} .nii.gz)_
fi

# Apply the transformations to each DTI metrics images
# Looping over each DTI metric map in subject-space
for file in ${subject}/DTI_Metrics/$(basename ${subject})__{fa,md,rd,ad,ga}.nii.gz; do
	if [[ ! -s ${outputdir}/$(basename ${file} .nii.gz)_on_$(basename ${model} .nii.gz).nii.gz ]]; then
		antsApplyTransforms -d 3 -i ${file} -r ${model} --verbose \
			-t ${outputdir}/$(basename ${t1} .nii.gz)_to_$(basename ${model} .nii.gz)_1Warp.nii.gz \
			-t ${outputdir}/$(basename ${t1} .nii.gz)_to_$(basename ${model} .nii.gz)_0GenericAffine.mat \
			-t ${outputdir}/$(basename ${b0} .nii.gz)_to_$(basename ${t1} .nii.gz)_0GenericAffine.mat \
			-o ${outputdir}/$(basename ${file} .nii.gz)_on_$(basename ${model} .nii.gz).nii.gz
	fi
done


# Calculate averages for each metric on each mask
# Looping over each DTI metric map in atlas-space
for file in ${outputdir}/$(basename ${subject})__{fa,md,rd,ad,ga}_on_*.nii.gz; do
	OUTPUT=""
	# Loop over each .nii.gz mask file and extract values
	for mask in ${MASK_FILES[@]}; do
        	MASK_STATS=$(fslstats -K ${mask} ${file} -m | tr -d '[:blank:]' | paste -s -d,)
        	OUTPUT+=$MASK_STATS","
    	done
	echo $(basename ${file}),${OUTPUT::-1}
done > ${outputdir}/$(basename ${subject}).csv

# Move final subject's results to a new folder for further analysis
mv ${outputdir}/$(basename ${subject}).csv /outputs_DWI/Mask_Result_CSVs/