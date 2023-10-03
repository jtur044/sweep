
% main_dir = "/Volumes/okn/DATA/BROOKS/TEST"
% main_dir = "./DATA/2Aug2023/TEST"
% main_dir = "/Volumes/BACKUP/DATA/BROOKS.WORKING/TEST";
% main_dir = "/Volumes/BACKUP/DATA/BROOKS.WORKING/TEST2";

%sweep_dir = './DATA/2Aug2023/jton_02_08_2023_sweep_left';
%run_sweep_invisible_analysis (sweep_dir);

% main_dir = './DATA/24Sep2023';   %% Example DIR 
main_dir = './DATA/12Sep2023';   %% Example DIR 
% main_dir = './DATA/7Sep2023';   %% Example DIR 
% main_dir = './DATA/5Sep2023';   %% Example DIR 
% main_dir = './DATA/12July2023';   %% Example DIR 
% main_dir = './DATA/4Aug2023';   %% Example DIR 
% main_dir = './DATA/4July2023';   %% Example DIR 
% main_dir = './DATA/30Aug2023';   %% Example DIR 
% main_dir = './DATA/2Aug2023';   %% Example DIR 
% main_dir = './DATA/25Aug2023';  %% Example DIR 
% main_dir = './DATA/11Aug2023';  %% Example DIR 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% manifest created by "find . -maxdepth 1 -type d > manifest.txt"

manifestfile = fullfile(main_dir,'manifest.txt');

if (~exist(manifestfile,'file'))
    fprintf ('generating manifest file ... %s\n', manifestfile);
    oldcd = cd (main_dir);
    !find . -maxdepth 1 -type d > manifest.txt
    cd(oldcd);
end

dirz = importdata (fullfile(main_dir,'manifest.txt'));

fprintf ('processing ... %s\n', main_dir);


M = length (dirz);
for k = 1:M 

    eachdir = dirz{k};
    if (strcmpi(eachdir(1), '#'))
        continue;
    end

    
    if (strcmpi(eachdir, { '.', '..'}))
        continue;
    end

    each_sweep_dir = fullfile (main_dir,eachdir);
    if (contains(eachdir,'sweep') & isfolder(each_sweep_dir))    
        fprintf ('found ... %s\n', eachdir);
        run_sweep_invisible_analysis (each_sweep_dir);
    end
end

%% Information 


%{

% STEP 1 - run SweepAnalyzer  (per individual sweep information)
%
% Calculate the VA for the individual SWEEPS 
%

batch_sweep_invisible_processor (main_dir, "SweepAnalyzer", "dryrun", false);

% STEP 4 - Data viewer   (individual sweeps)

batch_sweep_processor (main_dir, "SweepVisualizer", "dryrun", false);

% STEP 5 - Sweep Viewer

batch_sweep_reporter (main_dir);


%}

