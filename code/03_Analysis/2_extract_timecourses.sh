#!/bin/bash

#
# SPiCiCAP framework - Analysis
# July 2020
#
# Extract subject-specific timecourses for K = 40 (fine-grained analysis)
#
# Requirements: FSL
#
#

#
# ========= PARAMETERS ========= 
#

# List of subjects
declare -a sub=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06" "sub-07" "sub-08" "sub-09" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19")
sess="sess-rest"

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

ICAPFOLDER="iCAPs_results/PAM50_cropped_19sub_Alpha_5_950DOT05/K_40_Dist_cosine_Folds_20/binarized/"

#
# ========= ANALYSIS ========= 
#

# For each subject
for s in "${sub[@]}"; do

	tput setaf 2; echo "Extract mean TC for " $s "-" $sess
	tput sgr0;

	cd $DIREC$s"/TA_results/PAM50_cropped/TotalActivation/"
	for i in $(seq -f "%04g" 00 39); do
      		tput setaf 2; echo "iCAP " $i
        	tput sgr0;
		fslmeants -i Activity_inducing.nii -o $s"_icap00"$i".txt" -m $DIREC$ICAPFOLDER"icap"$i"_bin.nii.gz"
	done
done
