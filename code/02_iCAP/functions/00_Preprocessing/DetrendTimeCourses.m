%% This function detrends the time courses to consider for total activation
%
% Inputs:
% - TC is a n_ret_voxels x n_time_points 2D matrix with the data to detrend
% - param is the structure containing relevant TA parameters; here, we
% require the 'TR' (TR of the data), 'DCT_TS' (cutoff frequency for the DCT
% basis), 'Covariates' (list of covariates to include in the
% detrending/regression process; set to [] if none wished), and 'NbrVoxels'
% (number of retained voxels for TA)
function [TCN] = DetrendTimeCourses(TC,param,fid)

    % TCN has n_vox x n_TP dimensions
    TCN = zeros(size(TC));

    for i=1:param.NbrVoxels;
        
        % Regresses out low frequency components + possible other
        % covariates
        TCN(i,:) = sol_dct(TC(i,:)',param.TR,param.DCT_TS,param.Covariates);
        
        % Normalization
	TCN(i,:) = TCN(i,:)./std(TCN(i,:));
    end

    WriteInformation(fid,['Detrending and normalizing the data with DCT = ',...
        num2str(param.DCT_TS),' [s] and ',num2str(size(param.Covariates,2)),...
        ' covariate(s)']);

end
