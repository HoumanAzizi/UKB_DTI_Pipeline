#!/bin/bash

## Create lists for all subjects with similar 3 initial ID digits
mkdir squashfs_lists
mkdir output_DWI_sqfs
for ii in {100..602}
do
	ls ./outputs_DWI/sub-${ii}* -d > squashfs_lists/fs_list_${ii}.txt
done


# Go through each list file in ./squashfs_lists/
for file_name in ./squashfs_lists/*
do
	# Get the first 3 digits of IDs from file name
	ii=$(basename "$file_name" | cut -d'_' -f3 | cut -d'.' -f1)

	# Create a squashfs file for these subjects
	squash_file="output_DWI_sqfs/subs-${ii}.squashfs"

	# Read the list, move each file to tmp_dir, add it to the correct squashfs file, and remove the data
	# Note: after this, data will be only available inside squashfs files
	while IFS= read -r line
	do
		tmp_dir="tmp_dir_$ii"
		mkdir "$tmp_dir"

		mv ${line} ${tmp_dir}

		mksquashfs ${tmp_dir} ${squash_file}

		rm -r "$tmp_dir"
	done < ${file_name}
done

