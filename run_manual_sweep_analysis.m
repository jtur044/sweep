function run_manual_sweep_analysis (participant_file, data_dir)

% RUN_MANUAL_SWEEP_ANALYSIS Combines manual assessments into a single file
% 
% This creates an "experiment_manual_data.csv" file.
%
% run_manual_sweep_analysis (participant_file, data_dir)
%
% where 
% 
%   participant_file is the participant_info file 
%   data_dir         is the data directory 
%
%
% EXAMPLE 
% 
% run_manual_sweep_analysis ('./DATA/EXPERIMENT/participant_info_lab.xlsx','./DATA');
%


inputTbl    = readtable(participant_file);
inputTbl.EVA = inputTbl.VA;

[mypath, basename, extname] = fileparts (participant_file);

%% OUTFILE IS DEFINED 
experiment_manual_file = fullerfile (mypath, basename, 'experiment_manual_data.csv');


%% DESCENDING 
inputManualDescending               = fullerfile (mypath, basename, 'manual','results','accessed_data_descending.xlsx');
inputManualDescendingManifest       = fullerfile (mypath, basename, 'manual','extra','data_2.json');
[resultManifestDescendingTbl, VA] = get_manual_summary (inputManualDescendingManifest, inputManualDescending);
resultManifestDescendingTbl.VA_descending = VA(:);
resultDescending = groupsummary (resultManifestDescendingTbl, 'main', 'mean', 'VA_descending');

%% ASCENDING 
inputManualAscending               = fullerfile (mypath, basename, 'manual','results','accessed_data_ascending.xlsx');
inputManualAscendingManifest       = fullerfile (mypath, basename, 'manual','extra','data_1.json');
[resultManifestAscendingTbl, VA]    = get_manual_summary (inputManualAscendingManifest, inputManualAscending);
resultManifestAscendingTbl.VA_ascending = VA(:);
resultAscending = groupsummary (resultManifestAscendingTbl, 'main', 'mean', 'VA_ascending');


%% determine a combined result  
combinedResult = innerjoin (resultDescending, resultAscending, 'Keys', { 'main' }, 'RightVariables', { 'mean_VA_ascending' });
combinedResult.mean_VA = 0.5*(combinedResult.mean_VA_descending + combinedResult.mean_VA_ascending);
finalResult = innerjoin(inputTbl, combinedResult, 'LeftKeys', { 'File' }, 'RightKeys',{'main'}, 'RightVariables', { 'mean_VA_descending', 'mean_VA_ascending', 'mean_VA' });

%% write it out to CSV 
writetable (finalResult, experiment_manual_file);
fprintf ('Writing ... %s\n', experiment_manual_file);

end


function [inputResultManifestTbl, meanVA] = get_manual_summary (inputManualManifest, inputManualDescending)

    
    %% load the manual annotatations  
    inputResultTbl        = readtable (inputManualDescending);
    
    %% sorted manifest information 
    inputResultManifest          = load_commented_json (inputManualManifest);
    inputResultManifestStruct    = cellfun (@(x) x, inputResultManifest);
    inputResultManifestTbl       = struct2table (inputResultManifestStruct);
    inputResultManifestTbl       = sortrows (inputResultManifestTbl, { 'main', 'pair' });
    
    M = size(inputResultManifestTbl, 1);
    for m =1:M
    
        each = inputResultManifestTbl(m,:);
        i = ismember(inputResultTbl.SweepID, each.id);
    
        if (~any(i))
            fprintf ('%d [not found].\n', each.id);
        else 
            thisResult = inputResultTbl(i,:);        
            %meanVA(m) =  mean([ thisResult.JLogmar thisResult.ZLogmar ]); 
            meanVA(m) =  thisResult.ZLogmar; 
        end
    
    end



end
