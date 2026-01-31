#!/bin/bash
#
# SPiCiCAP framework - Preprocessing
# July 2020
#
# This script performs motion correction and extracts slice-wise motion parameters
#
# Requirements: Spinal Cord Toolbox 3.2.7, FSL
#
#

# List of subjects
declare -a sub=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06" "sub-07" "sub-08" "sub-09" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19" "sub-20" "sub-21" "sub-22")

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

# For each subject
for s in "${sub[@]}"; do
   	cd $DIREC$s"/func/"

		# Slicewise motion correction
                tput setaf 2; echo "Moco started for "$s
                tput sgr0;
		
		# Create mask to constrain motion correction metrics		

		# Check if mask does not exist
		if [ ! -f Mask/mask_fmri.nii.gz ]; then
			mkdir -p Mask
			fslmaths fmri.nii.gz -Tmean fmri_mean.nii.gz
                	mv fmri_mean.nii.gz Mask
                	cd Mask
                	sct_get_centerline -i fmri_mean.nii.gz -c t2
                	sct_create_mask -i fmri_mean.nii.gz -p centerline,fmri_mean_centerline_optic.nii.gz -size 30mm -o mask_fmri.nii.gz
			cd ..
		fi

		mkdir -p Processing

                sct_fmri_moco -i fmri.nii.gz -m Mask/mask_fmri.nii.gz -g 1 -r 0 -param smooth=2 -ofolder Moco
		mv Moco/fmri_moco.nii.gz mfmri.nii.gz
		mv Moco/fmri_moco_mean.nii.gz mfmri_mean.nii.gz
		if [ -f mfmri.nii.gz ]; then
			mv fmri.nii.gz Processing/fmri.nii.gz
		fi	

		tput setaf 2; echo "Moco done!"
                tput sgr0;

		# Extract motion parameters (X and Y)
                tput setaf 2; echo "Extraction of motion parameters "$s" for condition "$sess
                tput sgr0;
		
		cd Moco
		# Clean
                rm fmri_*.nii

		cd mat_groups

		# Remove motion files in case old ones are present
		rm motion_x.txt
		rm motion_y.txt		
		
		rm motion_x.nii.gz
		rm motion_y.nii.gz

		# Get number of timepoints
		npts=$(fslnvols ../../mfmri.nii.gz)
		# Loop through timepoints and decompose warping fields into X, Y and Z components
		for t in $(seq -f "%04g" 0 $(($npts-1))); do 
			sct_image -i "mat.Z0000T"$t"Warp.nii.gz" -mcs
			fslmaths "mat.Z0000T"$t"Warp_X.nii.gz" -abs tmp_abs_x.nii.gz # Take absolute values of motion for each slice in x ...
	           	fslmaths "mat.Z0000T"$t"Warp_Y.nii.gz" -abs tmp_abs_y.nii.gz # ... and y
			
			# Then we want to save the mean value (volume-level) in a text file
			fslstats tmp_abs_x -m >> motion_x.txt
			fslstats tmp_abs_y -m >> motion_y.txt
		
			# Remove temporary files
			rm tmp*
		done

		# Merge x and y motion text files
		paste -d '\0' motion_x.txt motion_y.txt > motion_xy.txt
		
		# Group X and Y components (over time) to generate regressors
		fslmerge -tr motion_x mat.Z0000T*Warp_X.nii.gz 2.5
		fslmerge -tr motion_y mat.Z0000T*Warp_Y.nii.gz 2.5

		# Delete Z components
		rm mat.Z0000T*Warp_Z.nii.gz mat.Z0000T*Warp_X.nii.gz mat.Z0000T*Warp_Y.nii.gz
		
		tput setaf 2; echo "Extraction done!"
                tput sgr0;
done
