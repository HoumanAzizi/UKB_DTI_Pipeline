# UK Biobank DTI Procesing Pipeline

## Preparations
### Preparation for the Processing Pipeline
In your working directory, create/add the following folder and files:
* `./outputs_DWI/` (folder)
    * `./outputs_DWI/Atlas.nii.gz` (e.g. mni_icbm152_t1_tal_nlin_asym_09c.nii.gz)
    * `./outputs_DWI/Atlas_Mask.nii.gz` (e.g. mni_icbm152_t1_tal_nlin_asym_09c_mask.nii.gz)
    * `./outputs_DWI/MASKS/` (folder)
        * Include all of your mask files (e.g. regions and tracts) as .nii.gz files inside this folder. Do not create a any subdirectories.
        * Masks can be binary or have a range of intensities, but note that each intensity will be treated as a separate mask (any probabilistic masks need to be thresholded and binarized).
    * `/outputs_DWI/t1w/` (folder)
        * Includes T1w images of all subjects as .nii.gz files
    * `./outputs_DWI/Mask_Result_CSVs/` (folder)
        * Create this empty folder which will save all subjects' .csv result files for further wrangling later
    * `./outputs_DWI/process_DTI.sh`
        * Put the script in this folder. Note: `./outputs_DWI/` would be the folder visible in singularity
* `./dwi_qbatch.sh`
    * The main code to run for each subject
* `./joblist.txt`
    * To run the code in parallel using qbatch, you can create a joblist file with one line per subject in the following format
        ```
        ./dwi_qbatch.sh 1111111,sub-1111111_ses-2,tractoflow_100.squashfs 
        ./dwi_qbatch.sh 2222222,sub-2222222_ses-2,tractoflow_200.squashfs
        ./dwi_qbatch.sh 3333333,sub-3333333_ses-2,tractoflow_300.squashfs
        ./dwi_qbatch.sh 4444444,sub-4444444_ses-2,tractoflow_400.squashfs
        ./dwi_qbatch.sh 5555555,sub-5555555_ses-2,tractoflow_500.squashfs
        ```

### Preparation for Wrangling Pipeline Results
The pipeline produces one .csv file per subject which includes ROI-based averages for each DTI modality. 
The following code creates a single final .csv file including the results of all subjects. 
* `./WM_csv_wrangling/` (folder)
    * Create this folder to save as a separate folder for wrangling
* `./WM_csv_wrangling/CSVs/` (folder)
    * Move all subject .csv results here (from `./outputs_DWI/Mask_Result_CSVs/`)
* `./WM_csv_wrangling/MASK_Output_Order.csv`
    * Copy/Paste the mask order list from `./outputs_DWI/MASK_Output_Order.csv` to here
* `./WM_csv_wrangling/WM_Regionwise_CSV_Wrangling.R`
    * Put the wrangling code in this folder. This will be the code to run. 
---
## Requirements/Dependencies
* `apptainer/1.1.8` for singularity
* `ANTs` from container containers_scilus_1.4.0.sif
* `FSL` from container containers_scilus_1.4.0.sif
* `r/4.3.1` for data wrangling
    * Rquires `library(tidyr)` and `library(dplyr)`
---
## Execution in Bash
Using qbatch to parallelize jobs (each node to run 5 subjects back-to-back): 

    qbatch -b slurm -w 24:00:00 -c 5 --mem 5G --env copied ./joblist.txt

Wrangling the results:

    module load r/4.3.1
    Rscript WM_Regionwise_CSV_Wrangling.R

---
## Outputs
* `./outputs_DWI/Mask_Result_CSVs/*`: ROI-based multimodal results of each subject as .csv files
* `./outputs_DWI/MASK_Output_Order.csv`: a .csv file showing the order of masks results in the output files
* `./outputs_DWI/sub-*/`: one folder per subject containing all registrations done by process_DTI.sh
* `./WM_csv_wrangling/UKB_WM_Regionwise_Data.csv`: single final output file containing results of all subjects for analysis (created by WM_Regionwise_CSV_Wrangling.R)
---
## Script Descriptions
### dwi_qbatch.sh
Script helps to run jobs in parallel using qbatch and by calling process_DTI.sh in singularity. Note that this can be done separately in bash as well. 

Input of dwi_qbatch.sh should be in the following format:
* `Subject_ID,Subject_Folder_Name,Subject_Squashfs_File_Name`
    * e.g. 1234567,sub-1234567_ses-2,tractoflow_100.squashfs
    * You can then run the code as: `./dwi_qbatch.sh 1234567,sub-1234567_ses-2,tractoflow_100.squashfs`

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

### WM_Regionwise_CSV_Wrangling.R
Creates a single final .csv file including the ROI-based results of all subjects for all modalities and saves it as `./WM_csv_wrangling/UKB_WM_Regionwise_Data.csv`

### find_failed_jobs.sh (Extra Script)
This script finds all the failed subjects after initial run and generates a new joblist file for failed subjects to rerun. 

This will create a `./failed_joblist.txt` file which has a joblist for all failed subjects to rerun.

### outputs_to_squashfs.sh (Extra Script)
After getting the results, this script will save all subjects' registration files in squashfs for storage. 

The naming convention of squashfs files is based on the first 3 digits of subject ID. (e.g. `./output_DWI_sqfs/subs-123.squashfs` will include all subjects with IDs 123xxxx)

---

## Acknowledgement
Based on original implementation by **G.A. Devenyi**