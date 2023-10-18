# UK Biobank DTI Procesing Pipeline

## Overview

## Preparation
In your working directory, create/add the following folder and files:
* `./outputs_DWI/` (folder)
    * `./outputs_DWI/Atlas.nii.gz` (e.g. mni_icbm152_t1_tal_nlin_asym_09c.nii.gz)
    * `./outputs_DWI/Atlas_Mask.nii.gz` (e.g. mni_icbm152_t1_tal_nlin_asym_09c_mask.nii.gz)
    * `./outputs_DWI/MASKS/` (folder)
        * Include all of your mask files (e.g. regions and tracts) as .nii.gz files inside this folder. Do not create a any subdirectories. Masks can be binary or have a range of intensities, but note that each intensity will be treated as a separate mask (any probabilistic masks need to be thresholded and binarized).
    * `/outputs_DWI/t1w/` (folder)
        * Includes T1w images of all subjects as .nii.gz files
    * `./outputs_DWI/Mask_Result_CSVs/`
        * Create this empty folder which will save all subjects' .csv result files for further wrangling later


## Script Descriptions
### process_DTI.sh
Gets 2 inputs:
* Input #1 (`${subject}`): subject's folder path (e.g. /tractoflow_results/sub-123456_ses-2)
* Input #2 (`${outputdir}`): output path for the current subject (e.g. /outputs_DWI/sub-123456_ses-2)

Then performs the following tasks:
1. Non-linearly registers subject T1w image to the atlas model image
2. Linearly registers subject B0 image to the subject T1w image
3. Applies the transformations (from steps 1 and 2) to each DTI metrics images
4. Calculates averages for each metric on each mask in the `./outputs_DWI/MASKS/` folder
5. Moves the final .csv result file to `./outputs_DWI/Mask_Result_CSVs/` folder