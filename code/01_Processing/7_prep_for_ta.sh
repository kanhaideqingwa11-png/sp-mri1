#!/bin/bash

#
# SPiCiCAP framework - Preprocessing
# July 2020
#
# Prepare data to run the Total Activation pipeline 
#
# Requirements: Spinal Cord Toolbox 3.2.7, FSL
#
#

# List of subjects
declare -a sub=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06" "sub-07" "sub-08" "sub-09" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19")

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

# For each subject
for s in "${sub[@]}"; do
	cd $DIREC$s"/func/"

			tput setaf 2; echo "Preparation started in " $s
               	 	tput sgr0;
                
			tput setaf 2; echo "...Creating folders & copy data"
                	tput sgr0;

                        mkdir TA
                        cd TA

			cp $DIREC$s"/func/s_mfmri_denoised_2x2x6.nii.gz" .
			
			cp $DIREC$s"/func/Segmentation/mask_sc.nii.gz" .
			gunzip mask_sc.nii.gz
	
			tput setaf 2; echo "...Split functional data"
                	tput sgr0;

			# First, split data
			fslsplit s_mfmri_denoised_2x2x6.nii.gz resvol -t
		
			tput setaf 2; echo "...Unzip"
        	        tput sgr0;

			for n in "$PWD"/resvol*.nii.gz; do # Loop through all files
                        	IFS='.' read -r volname string <<< "$n"
                        	gunzip "${volname##*/}".nii.gz
                	done
			
			tput setaf 2; echo "...Clean"
               	 	tput sgr0;
		
			rm resvol*.nii.gz

			tput setaf 2; echo "Done!"
                	tput sgr0;
		done

