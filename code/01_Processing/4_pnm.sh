#!/bin/bash
#
# SPiCiCAP framework - Preprocessing
# July 2020
#
# Preparation of physiological noise regressors
#
# Requirements: FSL
#
#

#
# Detection of cardiac peaks should always be checked manually (see PNM user guide)
#
#

# List of subjects
declare -a sub=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06" "sub-07" "sub-08" "sub-09" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19")

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

tput setaf 6; 
echo -n "Enter the index of the step to perform (1 = Prepare recordings, 2 = Generate EVs): "
tput sgr0;
read ind

# For each subject
for s in "${sub[@]}"; do
		cd $DIREC$s"/physio/"
			# 1 - PREPARE PHYSIOLOGICAL RECORDINGS
			if [ "$ind" == "1" ]; then
				tput setaf 2; echo "Prepare physiological recordings in " $s
				tput sgr0; 
				$FSLDIR/bin/fslFixText $s".txt" $s"_input.txt"
				$FSLDIR/bin/pnm_stage1 -i $s"_input.txt" -o $s -s 100 --tr=2.5 --smoothcard=0.3 --smoothresp=0.1 --resp=1 --cardiac=2 --trigger=3
				
			# 2 - GENERATE EVS
			elif [ "$ind" == "2" ]; then
				tput setaf 2; echo "EVs generation in " $s
				tput sgr0; 
				$FSLDIR/bin/pnm_evs -i $DIREC$s"/func/mfmri.nii.gz" -c $s"_card.txt" -r $s"_resp.txt" -o $s --tr=2.5 --oc=4 --or=4 --multc=2 --multr=2 --csfmask=$DIREC$s"/func/Segmentation/mask_csf.nii.gz" --sliceorder=up --slicedir=z

					ls -1 `${FSLDIR}/bin/imglob -extensions ${DIREC}${s}/physio/${s}ev0*` > $s"_evlist.txt"
			
			else
				tput setaf 1; 
				echo "Index not valid (should be 1 or 2)"
				tput sgr0; 
			fi
		
		tput setaf 2; echo "Done!" 
                tput sgr0;
done

