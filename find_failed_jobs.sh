#!/bin/bash

# Using the final .csv files inside Mask_Result_CSVs folder, create a list of done subjects 
cd  ./outputs_DWI/
ls ./Mask_Result_CSVs/ | grep 'sub-.*\.csv$' | cut -d'.' -f1 > ../tmp.txt
cd ..

# From initial joblist.txt, get the joblist line of all finished subjects
touch done_jobs.txt
while read -r line
do
	grep "$line" joblist.txt >> done_jobs.txt
done < tmp.txt

# Get the joblist lines of all failed subjects
grep -vxFf done_jobs.txt joblist.txt > failed_joblist.txt

rm tmp.txt done_jobs.txt
