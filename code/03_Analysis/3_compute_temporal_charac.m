%
% SPiCiCAP framework - Analysis
% July 2020
%
% Script to extract temporal characteristics
% (based on iCAP toolbox)
%
% Requirements: Matlab
%
%
% ========= OUTPUTS ==========
% 
% tempChar - structure containing the following fields:
%
% ----- Thresholded time courses and overall characteristics
%       (nSubjects x 1 cell objects)
%
%       .TC_AI_norm_thresh - normalized and thresholded time courses
%       .TC_active - activity information, 1 if positive activity, -1
%           if negative, 0 if none
%       .coactiveiCAPs_total - 1 x nTP_subject with number of active 
%           iCAPs per TP
%
% ----- Temporal characteristics of activity blocks in time courses
%       (niCAPs x nSub matrices)
%
%           .duration_total_counts_ai - number of active time points per 
%               icap per subject
%           .duration_total_pos_counts_ai - number of positively active
%               time points per icap per subject
%           .duration_total_neg_counts_ai - number of negatively active
%               time points per icap per subject
% 
%           .duration_total_perc_ai - total duration of iCAP in percentage 
%               of the whole scan duration
%           .duration_total_pos_perc_ai - total positive duration of iCAP 
%               in percentage of the whole scan duration
%           .duration_total_neg_perc_ai - total negative duration of iCAP  
%               in percentage of the whole scan duration
% 
%           .duration_avg_counts_ai - average duration of activity blocks 
%               (number of time points)
%           .duration_avg_pos_counts_ai - average duration of positive 
%               activity blocks (number of time points)
%           .duration_avg_neg_counts_ai - average duration of negative 
%               activity blocks (number of time points)
%
% -----  Co-activation characteristics of iCAPs time courses
%         (niCAPs x niCAPs x nSub)
%           .coupling_jacc_ai - coupling duration (percentage of
%               total duration of both iCAPs)
%           .coupling_sameSign_jacc_ai - same-signed coupling
%               duration (percentage of total duration of both iCAPs)
%           .coupling_diffSign_jacc_ai - differently-signed
%               coupling duration (percentage of tota duration of both 
%               iCAPs)
%

%% Parameters
n_iCAPs = 40;
subNames = {'sub-01' 'sub-02' 'sub-03' 'sub-04' 'sub-05' 'sub-06' 'sub-07' 'sub-08' 'sub-09' 'sub-10' 'sub-11' 'sub-12' 'sub-13' 'sub-14' 'sub-15' 'sub-16' 'sub-17' 'sub-18' 'sub-19'};
nsub = length(subNames);

% Path to subjects data
subPath = '/PATH/TO/MODIFY/';

% Path to save
savePath = '/PATH/TO/MODIFY/';

% Threshold above which a z-scored iCAPs time course will be considered
% "active" - according to Karahanoglu et al, NatComm 2015 and Zoller et
% al., IEEE TMI 2018 we select the default z-score of |1|
thresh = 1;

%% Load AI time courses
% Timecourses were obtained using 2_extract_timecourses.sh (ROI-based
% averaging, using binarized iCAPs as masks)
TC_AI = cell(nsub,1);
TC_AI_norm = cell(nsub,1);
TC_AI_norm_thresh = cell(nsub,1);
TC_active = cell(nsub,1);

coactiveiCAPs_total = cell(nsub,1);

for sub = 1:nsub
    TC_AI{sub} = zeros(n_iCAPs,360);
    for icap = 1:n_iCAPs
            if icap < 11
                tmp = textread([subPath subNames{sub} '/TA_results/PAM50_cropped/TotalActivation/' subNames{sub} '_icap00000' num2str(icap-1) '.txt']);
            else
            	tmp = textread([subPath subNames{sub} '/TA_results/PAM50_cropped/TotalActivation/' subNames{sub} '_icap0000' num2str(icap-1) '.txt']);
            end
            TC_AI{sub}(icap,:) = tmp(:,1);
    end
    TC_AI_norm{sub} = reshape(zscore(TC_AI{sub}(:)),size(TC_AI{sub},1),size(TC_AI{sub},2));
    TC_AI_norm_thresh{sub} = TC_AI_norm{sub};
    TC_AI_norm_thresh{sub}(abs(TC_AI_norm{sub})<thresh) = 0;
    TC_active{sub} = TC_AI_norm_thresh{sub};
    TC_active{sub}(TC_active{sub}>0)=1;
    TC_active{sub}(TC_active{sub}<0)=-1;
    coactiveiCAPs_total{sub} = sum(TC_active{sub}~=0);
    TC_AI_norm_thresh{sub} = reshape(TC_AI_norm_thresh{sub},size(TC_AI{sub},1),size(TC_AI{sub},2));
end

%% Compute AI temporal characteristics
duration_total_counts_ai = zeros(n_iCAPs,nsub);
duration_total_pos_counts_ai = zeros(n_iCAPs,nsub);
duration_total_neg_counts_ai = zeros(n_iCAPs,nsub);
duration_total_perc_ai = zeros(n_iCAPs,nsub);
duration_total_pos_perc_ai = zeros(n_iCAPs,nsub);
duration_total_neg_perc_ai = zeros(n_iCAPs,nsub);

duration_avg_counts_ai = zeros(n_iCAPs,nsub);
duration_avg_pos_counts_ai  = zeros(n_iCAPs,nsub);
duration_avg_neg_counts_ai = zeros(n_iCAPs,nsub);

coupling_ai= cell(nsub,1);
coupling_posPos_counts_ai= cell(nsub,1);
coupling_posNeg_counts_ai= cell(nsub,1);
coupling_negPos_counts_ai= cell(nsub,1);
coupling_negNeg_counts_ai= cell(nsub,1);

coupling_jacc_ai = zeros(n_iCAPs,n_iCAPs,nsub);
coupling_sameSign_jacc_ai = zeros(n_iCAPs,n_iCAPs,nsub);
coupling_diffSign_jacc_ai = zeros(n_iCAPs,n_iCAPs,nsub);


for iS = 1:nsub
    for iC = 1:n_iCAPs
        % Compute the active components
        activeComp=bwconncomp(TC_AI_norm_thresh{iS}(iC,:));
        activeComp=splitPosNegComps(activeComp,TC_AI_norm_thresh{iS}(iC,:));
        
        % Get signs of components
        activeComp=getCompSign(activeComp,TC_AI_norm_thresh{iS}(iC,:));
        
        duration_total_counts_ai(iC,iS)=nnz(TC_AI_norm_thresh{iS}(iC,:));
        duration_total_pos_counts_ai(iC,iS)=nnz(TC_AI_norm_thresh{iS}(iC,:)>0);
        duration_total_neg_counts_ai(iC,iS)=nnz(TC_AI_norm_thresh{iS}(iC,:)<0);

        duration_avg_counts_ai(iC,iS) = duration_total_counts_ai(iC,iS)/activeComp.NumObjects;
        duration_avg_pos_counts_ai(iC,iS) = duration_total_pos_counts_ai(iC,iS)/nnz(activeComp.compSign>0);
        duration_avg_neg_counts_ai(iC,iS) = duration_total_neg_counts_ai(iC,iS)/nnz(activeComp.compSign<0);

        % compute duration in percentage of total scan time
        duration_total_perc_ai(iC,iS)=duration_total_counts_ai(iC,iS)/size(TC_AI_norm_thresh{iS},2)*100;
        duration_total_pos_perc_ai(iC,iS)=duration_total_pos_counts_ai(iC,iS)/size(TC_AI_norm_thresh{iS},2)*100;
        duration_total_neg_perc_ai(iC,iS)=duration_total_neg_counts_ai(iC,iS)/size(TC_AI_norm_thresh{iS},2)*100;

        for iC2 = 1:n_iCAPs
            % time points of co-activation of iCAP iC and iCAP iC2
            coupling_ai{iS}(iC,iC2,:)=TC_AI_norm_thresh{iS}(iC,:) & ...
            TC_AI_norm_thresh{iS}(iC2,:);

            % percentage of co-activation with iCAP iC2, with respect to
            % total activation of iCAP iC
           coupling_jacc_ai(iC,iC2,iS)=nnz(coupling_ai{iS}(iC,iC2,:))/...
                nnz(TC_AI_norm_thresh{iS}(iC,:)~=0 | TC_AI_norm_thresh{iS}(iC2,:)~=0);

            % signed co-activation
            coupling_posPos_counts_ai{iS}(iC,iC2,:)=TC_AI_norm_thresh{iS}(iC,:)>0 & ...
                TC_AI_norm_thresh{iS}(iC2,:)>0;
            coupling_posNeg_counts_ai{iS}(iC,iC2,:)=TC_AI_norm_thresh{iS}(iC,:)>0 & ...
                TC_AI_norm_thresh{iS}(iC2,:)<0;
            coupling_negPos_counts_ai{iS}(iC,iC2,:)=TC_AI_norm_thresh{iS}(iC,:)<0 & ...
                TC_AI_norm_thresh{iS}(iC2,:)>0;
            coupling_negNeg_counts_ai{iS}(iC,iC2,:)=TC_AI_norm_thresh{iS}(iC,:)<0 & ...
                TC_AI_norm_thresh{iS}(iC2,:)<0;

            % percentage of signed co-activation with iCAP iC2, with
            % respect to total positive or negative activation of both
            % iCAPs
            coupling_sameSign_jacc_ai(iC,iC2,iS)=(nnz(coupling_posPos_counts_ai{iS}(iC,iC2,:))+...
                nnz(coupling_negNeg_counts_ai{iS}(iC,iC2,:)))/...
                nnz(TC_AI_norm_thresh{iS}(iC,:)~=0 | TC_AI_norm_thresh{iS}(iC2,:)~=0);
            coupling_diffSign_jacc_ai(iC,iC2,iS)=(nnz(coupling_posNeg_counts_ai{iS}(iC,iC2,:))+...
                nnz(coupling_negPos_counts_ai{iS}(iC,iC2,:)))/...
                nnz(TC_AI_norm_thresh{iS}(iC,:)~=0 | TC_AI_norm_thresh{iS}(iC2,:)~=0);
         
        end
    end
end

%% Saving in tempChar structure
tempChar.TC_AI_norm_thresh = TC_AI_norm_thresh;
tempChar.TC_active = TC_active;
tempChar.coactiveiCAPs_total = coactiveiCAPs_total;

tempChar.duration_total_counts_ai = duration_total_counts_ai;
tempChar.duration_total_pos_counts_ai = duration_total_pos_counts_ai;
tempChar.duration_total_neg_counts_ai = duration_total_neg_counts_ai;

tempChar.duration_total_perc_ai = duration_total_perc_ai;
tempChar.duration_total_pos_perc_ai = duration_total_pos_perc_ai; 
tempChar.duration_total_neg_perc_ai = duration_total_neg_perc_ai;

tempChar.duration_avg_counts_ai = duration_avg_counts_ai;
tempChar.duration_avg_pos_counts_ai = duration_avg_pos_counts_ai;
tempChar.duration_avg_neg_counts_ai = duration_avg_neg_counts_ai;

tempChar.coupling_jacc_ai = coupling_jacc_ai;
tempChar.coupling_sameSign_jacc_ai = coupling_sameSign_jacc_ai;
tempChar.coupling_diffSign_jacc_ai = coupling_diffSign_jacc_ai;

save([savePath 'tempChar.mat'],'tempChar')

%% Functions for temporal characteristics (from iCAP toolbox)
function activeComp = splitPosNegComps(activeComp,TC)
    for iA=1:activeComp.NumObjects
        % split connected components that include a sign change
        sign_comp=sign(TC(activeComp.PixelIdxList{iA}));
        sign_diff=find(diff(sign_comp));
        if ~isempty(sign_diff)
            activeComp.NumObjects=activeComp.NumObjects+length(sign_diff);
            sign_diff=[sign_diff,length(activeComp.PixelIdxList{iA})];
            % add additional components
            for iN=1:length(sign_diff)-1
                activeComp.PixelIdxList{end+1}=activeComp.PixelIdxList{iA}(sign_diff(iN)+1:sign_diff(iN+1));
            end
            % update existing component (only keep the first connected
            % component)
            activeComp.PixelIdxList{iA}=activeComp.PixelIdxList{iA}(1:sign_diff(1));
        end
    end
end

function activeComp=getCompSign(activeComp,TC)
    activeComp.compSign=[];
    for iA=1:activeComp.NumObjects
        % split connected components that include a sign change
        sign_comp=sign(TC(activeComp.PixelIdxList{iA}));
        sign_diff=find(diff(sign_comp));
        if ~isempty(sign_diff)
            activeComp=splitPosNegComps(activeComp,TC);
            activeComp=getCompSign(activeComp,TC);
            continue;
        else
            activeComp.compSign(iA)=sign_comp(1);
        end
    end
end
     
