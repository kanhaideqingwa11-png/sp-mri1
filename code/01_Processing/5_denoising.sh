#!/bin/bash

#
# SPiCiCAP framework - Preprocessing
# July 2020
#
# Noise regression (motion, pnm, etc.)
#
# Requirements: FSL
#
#

# List of subjects
declare -a sub=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06" "sub-07" "sub-08" "sub-09" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19")

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

# For each subject
for s in "${sub[@]}"; do
		cd $DIREC$s"/func/"

		tput setaf 2; echo "Noise regression started for " $s	

                echo "Generate motion outliers..."
                tput sgr0
		
                # Generate EV for outliers
                if [ ! -f outliers.png ]; then
                        fsl_motion_outliers -i mfmri.nii.gz -o outliers.txt —m ../Segmentation/mask_sc.nii.gz -p outliers.png --dvars --nomoco
                fi

		# Copy header information from moco functional to moco parameters
		fslcpgeom mfmri.nii.gz Moco/mat_groups/motion_x.nii.gz
                fslcpgeom mfmri.nii.gz Moco/mat_groups/motion_y.nii.gz

                tput setaf 2; echo "Prepare nuisance regressors file..."
                tput sgr0

		ls -1 `${FSLDIR}/bin/imglob -extensions ${DIREC}${s}/physio/${s}ev0*` > regressors_evlist.txt
                echo "$DIREC$s"/func/Moco/mat_groups/motion_x.nii.gz"" >> regressors_evlist.txt # Add motion parameters (x)
                echo "$DIREC$s"/func/Moco/mat_groups/motion_y.nii.gz"" >> regressors_evlist.txt # Add motion parameters (y) 

		# Generate fsf file from template
		#
		# NOTE: adapt path for template
		for i in "~/Code/template_noiseregression.fsf"; do
			# Include outliers as regressors if needed
			if [ -f $DIREC$s"/func/outliers.txt" ]; then

			sed -e 's@PNMPATH@'$DIREC$s"/func/regressors_evlist.txt"'@g' \
			    	-e 's@OUTDIR@'"noise_regression"'@g' \
                           	-e 's@DATAPATH@'$DIREC$s"/func/mfmri.nii.gz"'@g' \
                            	-e 's@FILT@'"0"'@g' \
				-e 's@OUTLYN@'"1"'@g' \
                            	-e 's@NPTS@'"$(fslnvols $DIREC$s"/func/mfmri.nii.gz")"'@g' \
			    	-e 's@OUTLPATH@'$DIREC$s"/func/outliers.txt"'@g'  <$i> design_noiseregression.fsf
			else
			sed -e 's@PNMPATH@'$DIREC$s"/func/Regressors/regressors_evlist.txt"'@g' \
                                -e 's@OUTDIR@'"noise_regression"'@g' \
                                -e 's@DATAPATH@'$DIREC$s"/func/mfmri.nii.gz"'@g' \
                                -e 's@FILT@'"0"'@g' \
                                -e 's@OUTLYN@'"0"'@g' \
                                -e 's@NPTS@'"$(fslnvols $DIREC$s"/func/mfmri.nii.gz")"'@g'  <$i> design_noiseregression.fsf
			fi
 		done

		# Run the analysis using the fsf file
 		fsl5.0-feat design_noiseregression.fsf
 	
		# Copy geometry to residuals
		cp noise_regression.feat/stats/res4d.nii.gz mfmri_denoised.nii.gz
		fslcpgeom mfmri.nii.gz mfmri_denoised.nii.gz

		tput setaf 2; echo "Done!" 
        	tput sgr0;				 			
done

