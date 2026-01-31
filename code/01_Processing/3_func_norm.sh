#!/bin/bash
#
# SPiCiCAP framework - Preprocessing
# July 2020
#
# Registration of functional images to PAM50 template
#
# Requirements: Spinal Cord Toolbox 3.2.7
#
#

# List of subjects
declare -a sub=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06" "sub-07" "sub-08" "sub-09" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19")

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

# For each subject
for s in "${sub[@]}"; do
		cd $DIREC$s"/func/"

		tput setaf 2; echo "Functional normalization started for "$s
                tput sgr0;

		mkdir -p Normalization
		cd Normalization

		#
		# NOTE: spinal cord segmentation has been done manually
		#

		# Register fmri to t2 
		sct_register_multimodal -i ../mfmri_mean.nii.gz \
               -d ../../anat/t2.nii.gz \
               -iseg ../Segmentation/mask_sc.nii.gz -dseg ../../anat/t2_seg.nii.gz -param step=1,type=seg,algo=slicereg,metric=MeanSquares:step=2,type=seg,algo=affine,metric=MeanSquares,gradStep=0.2:step=3,type=im,algo=syn,metric=CC,iter=5,shrink=2

		# Rename warping fields for clarity		
		mv warp_mfmri_mean2t2.nii.gz warp_fmri2anat.nii.gz
		mv warp_t22mfmri_mean.nii.gz warp_anat2fmri.nii.gz
		
		# Concatenate transforms fmri->anat & anat->template
        	sct_concat_transfo -w warp_fmri2anat.nii.gz,../../anat/warp_anat2template.nii.gz -o warp_fmri2template.nii.gz -d $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz
        	sct_concat_transfo -w ../../anat/warp_template2anat.nii.gz,warp_anat2fmri.nii.gz -o warp_template2fmri.nii.gz -d ../mfmri_mean.nii.gz

		tput setaf 2; echo "Done!"
                tput sgr0;		

done
