#!/bin/bash

#
# SPiCiCAP framework - Preprocessing
# July 2020
#
# Smoothing along the cord with a 2x2x6mm FWHM Gaussian kernel
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

		tput setaf 2; echo "Smoothing started in " $s
                tput sgr0;
                
		cd Processing
		
		mkdir -p Smoothing
		cd Smoothing

		# First, isolate slice init 
		if [ ! -f slice_init.nii.gz ]; then
			fslroi ../../mfmri_denoised slice_init 0 -1 0 -1 0 1 0 -1
		fi
	
                dim=$(fslsize ../../mfmri_denoised.nii.gz)
                arrdim=($dim)
                z=${arrdim[5]}
                maxz=$(( z-1 ))
	
                # Then, isolate slice last
                if [ ! -f slice_last.nii.gz ]; then
                        fslroi ../../mfmri_denoised slice_last 0 -1 0 -1 $maxz 1
                fi


		# And for mask as well
                if [ ! -f ../../Segmentation/mask_init.nii.gz ]; then
                        fslroi ../../Segmentation/mask_sc.nii.gz ../../Segmentation/mask_init 0 -1 0 -1 0 1 0 -1
                fi
		
                if [ ! -f ../../Segmentation/mask_last.nii.gz ]; then
                        fslroi ../../Segmentation/mask_sc.nii.gz ../../Segmentation/mask_last 0 -1 0 -1 $maxz 1
                fi

		#rm residuals_native_padded.nii.gz

		if [ ! -f mfmri_denoised_padded.nii.gz ]; then
			fslmerge -z mfmri_denoised_padded ../../mfmri_denoised slice_last slice_last slice_last slice_last slice_last
			fslmerge -z mfmri_denoised_padded slice_init slice_init slice_init slice_init slice_init mfmri_denoised_padded
		fi

                if [ ! -f mask_padded.nii.gz ]; then
                        fslmerge -z mask_padded ../../Segmentation/mask_sc ../../Segmentation/mask_last ../../Segmentation/mask_last ../../Segmentation/mask_last ../../Segmentation/mask_last ../../Segmentation/mask_last
                        fslmerge -z mask_padded ../../Segmentation/mask_init ../../Segmentation/mask_init ../../Segmentation/mask_init ../../Segmentation/mask_init ../../Segmentation/mask_init mask_padded
                fi

                # Create temporary folder
                rm -r tmp
		mkdir -p tmp

                # Copy input data to tmp folder & split
                cp mfmri_denoised_padded.nii.gz tmp
                cd tmp
                sct_image -i mfmri_denoised_padded.nii.gz -split t -o mfmri_denoised_padded.nii.gz
		rm mfmri_denoised_padded.nii.gz

                files_to_smooth="$PWD"/*
                for b in $files_to_smooth; do # Loop through all files
                        sct_smooth_spinalcord -i $b -s ../mask_padded.nii.gz
                        rm $b
                done
		
		# Concat, put back in initial folder and delete temporary folder
                fslmerge -tr s_mfmri_denoised_padded_2x2x6 mfmri_denoised_padded*_smooth.nii.gz 2.5
                mv s_mfmri_denoised_padded_2x2x6.nii.gz ..
                cd ..

		sct_crop_image -i s_mfmri_denoised_padded_2x2x6.nii.gz -start 5 -end -5 -dim 2 -o s_mfmri_denoised_2x2x6.nii.gz
		mv s_mfmri_denoised_2x2x6.nii.gz ../../s_mfmri_denoised_2x2x6.nii.gz
		
		cd ../..

                # Copy header info
                fslcpgeom mfmri_denoised.nii.gz s_mfmri_denoised_2x2x6.nii.gz

		tput setaf 2; echo "Done!"
                tput sgr0;

done



