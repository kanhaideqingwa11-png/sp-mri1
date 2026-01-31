%
% SPiCiCAP framework - Preprocessing
% July 2020
%
% Normalize TA results to cropped version of PAM50 template
%
% Requirements: MATLAB, iCAP toolbox (packages)
%
%

clc;clear all;close all;

% From iCAP toolbox
AddPaths()

PathData = '/PATH/TO/MODIFY/';
Subjects={'sub-01' 'sub-02' 'sub-03' 'sub-04' 'sub-05' 'sub-06' 'sub-07' 'sub-08' 'sub-09' 'sub-10' 'sub-11' 'sub-12' 'sub-13' 'sub-14' 'sub-15' 'sub-16' 'sub-17' 'sub-18' 'sub-19'};
thresh_title = 'Alpha_5_950DOT05';

subj_paths=fullfile(PathData,Subjects);

%% set paths
thresh_path=fullfile('TA_results','Native','Thresholding',thresh_title);
TA_path=fullfile('TA_results','Native','TotalActivation');

out_thresh_path=fullfile('TA_results','PAM50_cropped','Thresholding',thresh_title);
out_TA_path=fullfile('TA_results','PAM50_cropped','TotalActivation');

%% Run deformation of SignInnov and Activity_inducing
for iS=1:length(subj_paths)

	disp(['Subject ' Subjects{iS}])

    	fHdr=cbiReadNiftiHeader(fullfile(subj_paths{iS},out_thresh_path,'SignInnov.nii'));
    	SignInnov_4D=cbiReadNifti(fullfile(subj_paths{iS},out_thresh_path,'SignInnov.nii'));
    	mask_nonan_3D=cbiReadNifti(fullfile(subj_paths{iS},out_thresh_path,'mask_nonan.nii'));
    	mask_nonan_3D=~isnan(mask_nonan_3D)&mask_nonan_3D~=0;
    	mask_3D=cbiReadNifti(fullfile(subj_paths{iS},out_TA_path,'mask.nii'));
   	mask_3D=~isnan(mask_3D)&mask_3D~=0;
    	AI_4D=cbiReadNifti(fullfile(subj_paths{iS},out_TA_path,'Activity_inducing.nii'));
    
    
    	%% saving modified param and SignInnov (Thresholding)
    	load(fullfile(subj_paths{iS},thresh_path,'param.mat'));
    
    	param.mask=reshape(mask_3D,[],1);
    	param.Dimension(1)=size(mask_3D,1);
    	param.Dimension(2)=size(mask_3D,2);
    	param.Dimension(3)=size(mask_3D,3);
    
    	param.mask_nonan=reshape(mask_nonan_3D,[],1);
    
    	% these are fields that are specific for thresholding in subject space
    	% and won't be required further by the pipeline
    	param=rmfield(param,{'PC','mask_threshold1'});
    
    	% getting 2D innovations 
    	SignInnov=reshape(SignInnov_4D,[],size(SignInnov_4D,4));
    	SignInnov=SignInnov(param.mask_nonan,:)';
    
    	% masking normalized data
    	SignInnov_4D(~repmat(mask_nonan_3D,1,1,1,size(SignInnov_4D,4)))=nan;
    
    	% saving data
    	save(fullfile(subj_paths{iS},out_thresh_path,'param.mat'),'param','-v7.3');
    	save(fullfile(subj_paths{iS},out_thresh_path,'SignInnov.mat'),'SignInnov','-v7.3');
    
    	hdr=cbiReadNiftiHeader(fullfile(subj_paths{iS},out_thresh_path,'SignInnov.nii'));
   	cbiWriteNifti(fullfile(subj_paths{iS},out_thresh_path,'SignInnov.nii'),SignInnov_4D,hdr,'float32');
    
    	%% saving modified param (Total Activation)
    	load(fullfile(subj_paths{iS},TA_path,'param.mat'));
    
    	param.mask=reshape(mask_3D,[],1);
    	param.mask_3D=mask_3D;
    	param.Dimension(1)=size(mask_3D,1);
    	param.Dimension(2)=size(mask_3D,2);
    	param.Dimension(3)=size(mask_3D,3);
    	param.IND=find(mask_3D);
    	param.VoxelIdx=[];
    	[param.VoxelIdx(:,1),param.VoxelIdx(:,2),param.VoxelIdx(:,3)]=ind2sub(size(mask_3D),param.IND);
    	param.NbrVoxels=length(param.IND);
    
    	% these are fields that are specific for TA in subject space
    	% and won't be required further by the pipeline
    	param=rmfield(param,{'GM_map','fHeader','weight_x','weight_y','weight_z',...
        'LambdaTemp','LambdaTempFin','NoiseEstimateFin'});
    
    	% getting 2D innovations
    	Activity_inducing=reshape(AI_4D,[],size(AI_4D,4));
    	Activity_inducing=Activity_inducing(param.mask,:)';
    
    	% masking normalized data
    	AI_4D(~repmat(mask_3D,1,1,1,size(AI_4D,4)))=nan;
    
    	% saving data
    	save(fullfile(subj_paths{iS},out_TA_path,'param.mat'),'param','-v7.3');
    	save(fullfile(subj_paths{iS},out_TA_path,'Activity_inducing.mat'),'Activity_inducing','-v7.3');
    
    	hdr=cbiReadNiftiHeader(fullfile(subj_paths{iS},out_TA_path,'Activity_inducing.nii'));
    	cbiWriteNifti(fullfile(subj_paths{iS},out_TA_path,'Activity_inducing.nii'),AI_4D,hdr,'float32');
    end

