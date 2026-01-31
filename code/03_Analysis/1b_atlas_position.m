%
% SPiCiCAP framework - Analysis
% July 2020
%
% Script to find position of iCAPs in atlas & spinal levels 
%
% Requirements: Matlab
%
% ========= INPUT ==========
%   icap_localization_Z?.xlsx   File created by atlas_location.sh      
%                               Manually saved from .txt to .xlsx
%

clear all
close all

%% Load data
n_iCAPs = 40;
[data hdr] = xlsread(['/PATH/TO/MODIFY/icap_localization_K' num2str(n_iCAPs) '_Z5.xlsx']);

%% Order iCAPs based on rostrocaudal position
data_levels = data(:,6:11); % Take only columns of interest (C4 to T1) for all iCAPs

mean_rostrocaudal_location = zeros(n_iCAPs,1);
for icap = 1:n_iCAPs
    tmp_distrib = [];
    for level = 1:size(data_levels,2)
        tmp_distrib = [tmp_distrib; level*ones(data_levels(icap,level),1)]; % We create a vector with one value per voxel, corresponding to location
    end
    mean_rostrocaudal_location(icap) = mean(tmp_distrib);
    clear tmp*
end

[rostrocaudal_sorted,idx_rostrocaudal] = sort(mean_rostrocaudal_location);

% We can also define in which spinal level iCAPs are
max_level = zeros(n_iCAPs,1); % One variable to store position
for icap = 1:n_iCAPs
    max_level(icap) = max(find(data_levels(icap,:) == max(data_levels(icap,:))));
end

[level_sorted,idx_level] = sort(max_level,'descend');
max_level_sorted = max_level(idx_rostrocaudal)';

%% Analysis of axial properties
% We can define which region is match with each iCAP spatial map
axial_max_region = zeros(n_iCAPs,1); % One variable to store position
axial_max_region_names = cell(n_iCAPs,1); % One variable to store name of region
col_cord = 23:58;
for icap = 1:n_iCAPs
    axial_max_region(icap) = max(find(data(icap,col_cord) == max(data(icap,col_cord))));
    axial_max_region_names{icap} = hdr(col_cord(max(find(data(icap,col_cord) == max(data(icap,col_cord))))));
end

axial_max_region = axial_max_region-1; % TO BE CONSISTENT WITH ATLAS NOTATION (STARTS FROM 0)
[axial_sorted,idx_axial] = sort(axial_max_region);
axial_max_region_sorted = axial_max_region(idx_axial);

% But we also want to re-order rostro-caudally within each axial region
idx_axial_rostrocaudal = [];
allpossibleregions = unique(axial_max_region);
for i1 = 1:length(allpossibleregions)
    idxthisregion = find(axial_max_region == allpossibleregions(i1));
    for i2 = 1:length(idxthisregion)
        tmp_idx(i2) = find(idx_rostrocaudal==idx_axial(idxthisregion(i2)));
    end
    [tmp_sort tmp_newi] = sort(tmp_idx);
    current_idx = idx_axial(find(axial_max_region_sorted == allpossibleregions(i1)));
    new_idx = current_idx(tmp_newi); 
    idx_axial_rostrocaudal = [idx_axial_rostrocaudal new_idx'];
    clear tmp_idx tmp_newi tmp_sort
end

% A way to look at repartition is to plot the histogram
figure('Name','Repartition of iCAPs in atlas regions')
histogram(axial_max_region)

%% Let's try to sort by pathways & intermediate zone
col_dcml = [0:3 12 13 34 35];
col_cst = [4 5 30 31];
col_in = [32 33];

icap_dcml = [];
for i = 1:length(col_dcml)
    icap_dcml = [icap_dcml; find(axial_max_region == col_dcml(i))];
end

icap_cst = [];
for i = 1:length(col_cst)
    icap_cst = [icap_cst; find(axial_max_region == col_cst(i))];
end

icap_in = [];
for i = 1:length(col_in)
    icap_in = [icap_in; find(axial_max_region == col_in(i))];
end

% But we also want to re-order rostro-caudally within each pathway
for i = 1:length(icap_dcml)
    idx_in_rc_dcml(i) = find(idx_rostrocaudal==icap_dcml(i));
end
[tmp_sort newi] = sort(idx_in_rc_dcml);
icap_dcml = icap_dcml(newi)';

for i = 1:length(icap_cst)
    idx_in_rc_cst(i) = find(idx_rostrocaudal==icap_cst(i));
end
[tmp_sort newi] = sort(idx_in_rc_cst);
icap_cst = icap_cst(newi)';

for i = 1:length(icap_in)
    idx_in_rc_in(i) = find(idx_rostrocaudal==icap_in(i));
end
[tmp_sort newi] = sort(idx_in_rc_in);
icap_in = icap_in(newi)';

idx_pathways = [icap_cst,icap_dcml,icap_in];

%% Plot summary of repartition (normalized per iCAP) - ATLAS
data_atlas = data(:,23:58);
data_atlas_sum = sum(data_atlas,2);

data_atlas_norm = zeros(size(data_atlas));
for icap = 1:n_iCAPs
    data_atlas_norm(icap,:) = data_atlas(icap,:) ./ data_atlas_sum(icap);
end
data_atlas_norm(:,:) = data_atlas_norm(idx_rostrocaudal,:);
figure('Name', 'Repartition per iCAP - Atlas')
imagesc(data_atlas_norm)


%% Plot summary of repartition (normalized per iCAP) - SPINAL LEVELS
data_levels_sum = sum(data_levels,2);

data_levels_norm = zeros(size(data_levels));
for icap = 1:n_iCAPs
    data_levels_norm(icap,:) = data_levels(icap,:) ./ data_levels_sum(icap);
end
data_levels_norm(:,:) = data_levels_norm(idx_rostrocaudal,:);
figure('Name', 'Repartition per iCAP - Spinal level')
imagesc(data_levels_norm)
