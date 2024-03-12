%---------------------------------------------------------------------------------------------------%
% Extract Contrast Values for each subject 
% Bambi Langzeit: fMRI Odd-one-out task 
% Raphaela Schöpfer
%---------------------------------------------------------------------------------------------------%

clc;
clear all;

% Define subjects and directories
subjects = {'sub-95', 'sub-176', 'sub-226', 'sub-236','sub-307', 'sub-317','sub-352','sub-353', 'sub-364','sub-378', 'sub-379', 'sub-380', 'sub-384', 'sub-386', 'sub-387', 'sub-388', 'sub-391','sub-392','sub-395','sub-397', 'sub-398', 'sub-399', 'sub-406', 'sub-407', 'sub-409', 'sub-410', 'sub-411', 'sub-413', 'sub-415'};
basePath = '/media/T7Shield/Raphaela/Data/source_data';
maskFilePath = '/media/T7Shield/Raphaela/Data/mask/35_2.nii'; % mask file
conditions = {'Schwer', 'Leicht', 'Rest', 'Schwer_Leicht_Combined'}; % 4 different conditions
conImages = {'con_0004.nii', 'con_0005.nii', 'con_0006.nii', 'con_0007.nii'}; % Corresponding contrast images

% Load mask
V_mask = spm_vol(maskFilePath);
mask = spm_read_vols(V_mask);
maskIndices = find(mask > 0);

% Initialize results
results = [];

% Loop over subjects
for iSub = 1:length(subjects)
    subjPath = fullfile(basePath, subjects{iSub}, 'session_B', 'stats'); % Path to contrasts
    
    % Loop over conditions
    for iCond = 1:length(conditions)
        % Construct path to the contrast image
        conFilePath = fullfile(subjPath, conImages{iCond});
        
        if ~exist(conFilePath, 'file')
            warning(['Contrast file not found: ', conFilePath]);
            continue; % Skip this file if not found
        end
        
        % Load contrast image
        V_con = spm_vol(conFilePath);
        con_img = spm_read_vols(V_con);
        
        % Extract values from the mask
        con_values_within_mask = con_img(maskIndices);
        meanConValue = mean(con_values_within_mask, 'omitnan'); % Compute mean
        
        % Append results
        results = [results; {subjects{iSub}, conditions{iCond}, meanConValue}];
    end
end

% Convert results to table and save
resultsTable = cell2table(results, 'VariableNames', {'Subject', 'Condition', 'MeanConValue'});
outputFileName = fullfile(basePath, 'Con_values_table.xlsx');
writetable(resultsTable, outputFileName);

fprintf('Contrast values extraction completed.\n');
