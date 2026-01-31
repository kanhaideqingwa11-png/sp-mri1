#!/bin/bash

#
# SPiCiCAP framework - Analysis
# July 2020
#
# Script to find position of iCAPs in atlas & spinal levels 
#
# Requirements: Spinal Cord Toolbox 3.2.7, FSL
#
#

#
# ========= PARAMETERS ========= 
#

# Path of the folder containing all data
DIREC="/PATH/TO/MODIFY/"

# Path of the folder containing clustering results (i.e., iCAPs to localize)
ICAPFOLDER="iCAPs_results/PAM50_cropped_19sub_Alpha_5_950DOT05"

# Select number of iCAPs
K="40"

# Define Z threshold for iCAP maps
ZTHRESH=5


#
# ========= ANALYSIS ========= 
#

# Binarize iCAP maps
tput setaf 2; echo "Binarize iCAPs..."
tput sgr0;     

cd $DIREC$ICAPFOLDER"/K_"$K"_Dist_cosine_Folds_20/"

mkdir -p binarized
cd binarized

# Loop through all atlas file
cp ../iCAPs_z.nii .
fslsplit iCAPs_z.nii icap -t
rm iCAPs_z.nii

ICAPSFILES=./icap????.nii.gz

for f in $ICAPSFILES; do
	fbname=$(basename "$f" | cut -d. -f1)
        if [ ! -f $fbname"_bin.nii.gz" ]; then
                fslmaths $f -thr $ZTHRESH -bin $fbname"_bin"
        fi
done

# Remove unbinarized
rm icap00??.nii.gz

# Binarize atlas
tput setaf 2; echo "Binarize atlas..."
tput sgr0;     

cd $DIREC"PAM50_t2_common/atlas"

mkdir -p binarized
cd binarized

# Loop through all atlas files
ATLASFILES=$DIREC/PAM50_t2_common/atlas/PAM50_atlas_??.nii.gz
for f in $ATLASFILES; do
	fbname=$(basename "$f" | cut -d. -f1)
        if [ ! -f $fbname"_bin.nii.gz" ]; then
                fslmaths $f -thr 0.5 -bin $fbname"_bin"
        fi
done

# Binarize spinal levels
tput setaf 2; echo "Binarize spinal levels..."
tput sgr0;

cd $DIREC"PAM50_t2_common/spinal_levels"

mkdir -p binarized
cd binarized

# Loop through all level files
LEVELFILES=$DIREC/PAM50_t2_common/spinal_levels/spinal_level_??.nii.gz
for f in $LEVELFILES; do
        fbname=$(basename "$f" | cut -d. -f1)
        if [ ! -f $fbname"_bin.nii.gz" ]; then
               fslmaths $f -thr 0.01 -bin $fbname"_bin"
        fi
done

# First, find in which atlas part the iCAPs are
ICAPBIN=$DIREC$ICAPFOLDER"/K_"$K"_Dist_cosine_Folds_20/binarized"
ICAPFILESBIN=$ICAPBIN/icap????_bin.nii.gz
LEVELFILESBIN=$DIREC/PAM50_t2_common/spinal_levels/binarized/spinal_level_??_bin.nii.gz
ATLASFILESBIN=$DIREC/PAM50_t2_common/atlas/binarized/PAM50_atlas_??_bin.nii.gz

cd $DIREC$ICAPFOLDER"/K_"$K"_Dist_cosine_Folds_20/"
mkdir -p inters_levels
mkdir -p inters_atlas

ind=1
tput setaf 2; echo "Prepare first column (icaps)..."
tput sgr0;  
echo "icap" > col01.txt
echo "total" > col02.txt
for icap in $ICAPFILESBIN; do
        # Prepare first column with iCAP number 
        echo "$ind" >> col01.txt

        # Then we want to know the total number of voxels in each icap
        res=`fslstats $icap -V | cut -d ' ' -f 1`
        echo "$res" >> col02.txt
        let ind++
done


# Column of spinal levels from 3 to 23
tput setaf 2; echo "Prepare spinal levels columns..."
tput sgr0;
l=3
for level in $LEVELFILESBIN; do
        tput setaf 2; echo "Level $(($l-2))"
        tput sgr0;
        s=`printf %02d $l`;
        echo "level $(($l-2))" > col$s.txt # First element of column is spinal level (starting from 01)
        for icap in $ICAPFILESBIN; do # Then we loop through iCAP maps
                # First, compute intersection with levels & atlas
                # Then, look at number of voxels left
	        icapbname=$(basename "$icap" | cut -d. -f1)
		levelbname=$(basename "$level" | cut -d. -f1)

                if [ ! -f inters_levels/$icapbname"_"$levelbname".nii.gz" ]; then
                        fslmaths $icap -mul $level inters_levels/$icapbname"_"$levelbname
                fi

                res=`fslstats "inters_levels/"$icapbname"_"$levelbname -V | cut -d ' ' -f 1`
                echo "$res" >> col$s.txt
        done
        let l++
done

# Column of atlas regions from 23 to last one
a=23
tput setaf 2; echo "Prepare atlas columns..."
tput sgr0;
for atlas in $ATLASFILESBIN; do
        tput setaf 2; echo "Atlas $(($a-23))"
        tput sgr0;
        echo "atlas $(($a-23))" > col$a.txt # First element of column is atlas (starting from 00)
        for icap in $ICAPFILESBIN; do # Then we loop through iCAP maps
                # First, compute intersection with levels & atlas
                # Then, look at number of voxels left
                icapbname=$(basename "$icap" | cut -d. -f1)
                atlasbname=$(basename "$atlas" | cut -d. -f1)

                if [ ! -f inters_atlas/$icapbname"_"$atlasbname".nii.gz" ]; then
                        fslmaths $icap -mul $atlas inters_atlas/$icapbname"_"$atlasbname
                fi
                res=`fslstats "inters_atlas/"$icapbname"_"$atlasbname -V | cut -d ' ' -f 1`
                echo "$res" >> col$a.txt
        done
        let a++
done

paste col??.txt > icap_localization.txt
