#!/bin/bash

#
# SPiCiCAP framework - Preprocessing
# July 2020
#
# Normalize TA results to cropped version of PAM50 template
#
# Requirements: Spinal Cord Toolbox 3.2.7
#
#

#
# NOTE: After this step, it is still necessary to run 8b_norm_after_ta.m in order to update the .mat files
#

# List of subjects
declare -a sub=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06" "sub-07" "sub-08" "sub-09" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19")

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

icapfolder_old="Native"
icapfolder_new="PAM50_cropped"

thresh="5_95"

# For each subject & run
for s in "${sub[@]}"; do
 	cd $DIREC$s"/TA_results/" # Go inside each folder containing TA results

	tput setaf 2; echo "Normalization started in " $s
        tput sgr0;

        tput setaf 2; echo "...Significant innovations"
        tput sgr0;
			
	mkdir -p $icapfolder_new"/Thresholding/Alpha_"$thresh"0DOT05/"

	sct_apply_transfo -i $icapfolder_old"/Thresholding/Alpha_"$thresh"0DOT05/SignInnov.nii" -d $DIREC/PAM50_t2_common/template/PAM50_t2.nii.gz -w $DIREC$s"/func/Normalization/warp_fmri2template.nii.gz" -x linear -o $icapfolder_new"/Thresholding/Alpha_"$thresh"0DOT05/SignInnov.nii"

        tput setaf 2; echo "...Mask"
        tput sgr0;

	sct_apply_transfo -i $icapfolder_old"/Thresholding/Alpha_"$thresh"0DOT05/mask_nonan.nii" -d $DIREC/PAM50_t2_common/template/PAM50_t2.nii.gz -w $DIREC$s"/func/Normalization/warp_fmri2template.nii.gz" -x nn -o $icapfolder_new"/Thresholding/Alpha_"$thresh"0DOT05/mask_nonan.nii"

        tput setaf 2; echo "...Activity inducing"
	tput sgr0;

        mkdir -p $icapfolder_new"/TotalActivation/"

	cp $icapfolder_new"/Thresholding/Alpha_"$thresh"0DOT05/mask_nonan.nii" $icapfolder_new"/TotalActivation/mask.nii"
	sct_apply_transfo -i $icapfolder_old"/TotalActivation/Activity_inducing.nii" -d $DIREC/PAM50_t2_common/template/PAM50_t2.nii.gz -w $DIREC$s"/func/Normalization/warp_fmri2template.nii.gz" -x linear -o $icapfolder_new"/TotalActivation/Activity_inducing.nii"

        tput setaf 2; echo "Done!"
        tput sgr0;
done
