#!/bin/bash
#
# SPiCiCAP framework - Preprocessing
# July 2020
#
# This script performs automatic SC segmentation, vertebrae labeling and normalization to the PAM50 template
#
# Requirements: Spinal Cord Toolbox 3.2.7
#
#

# List of subjects
declare -a sub=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06" "sub-07" "sub-08" "sub-09" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19" "sub-20" "sub-21" "sub-22")

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

# For each subject
for s in "${sub[@]}"; do
	cd $DIREC$s"/analysis/anat/"

	tput setaf 2; echo "Segmentation started in "$s
        tput sgr0;

	# Segmentation (deep learning based method) with viewer initialization
	sct_deepseg_sc -i t2.nii.gz -c t2 -centerline viewer

	tput setaf 2; echo "Done!"
        tput sgr0;

	# Vertebral labeling (manual initialization of labeling by clicking at disc C2-C3)
	sct_label_vertebrae -i t2.nii.gz -s t2_seg.nii.gz -c t2 -initc2
	# Create labels at specific vertebral levels
        sct_label_utils -i t2_seg_labeled.nii.gz -vert-body 4,7

	#
	# NOTE: segmentation and labeling should be visually evaluated!
	#

 	tput setaf 2; echo "Normalization started in "$s
        tput sgr0;

	# Normalization to PAM50 template	
	sct_register_to_template -i t2.nii.gz -s t2_seg.nii.gz -l labels.nii.gz -c t2 -param step=0,type=label,dof=Tx_Ty_Tz_Sz:step=1,type=seg,algo=centermassrot,metric=MeanSquares,iter=10,smooth=2,gradStep=0.5,slicewise=0,smoothWarpXY=2,pca_eigenratio_th=1.6:step=2,type=seg,algo=bsplinesyn,metric=MeanSquares,iter=3,smooth=1,slicewise=0,gradStep=0.5,smoothWarpXY=2,pca_eigenratio_th=1.6:step=3,type=im,metric=CC

	tput setaf 2; echo "Done!"
        tput sgr0;
done
