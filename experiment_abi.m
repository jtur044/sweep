
close all;


% main_dir = "/Volumes/okn/DATA/BROOKS/TEST"
% main_dir = "./DATA/2Aug2023/TEST"
% main_dir = "/Volumes/BACKUP/DATA/BROOKS.WORKING/TEST";
% main_dir = "/Volumes/BACKUP/DATA/BROOKS.WORKING/TEST2";

%sweep_dir = './DATA/2Aug2023/jton_02_08_2023_sweep_left';
%run_sweep_invisible_analysis (sweep_dir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% "SWEEPER PROTOCOL"
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main_dir = './DATA/27Nov2023';   
% main_dir = './DATA/24Nov2023';   
% main_dir = './DATA/23Nov2023';   
% main_dir = './DATA/13Nov2023';   

%main_dir = './DATA/8Nov2023';   
%main_dir = './DATA/6Nov2023';   

%main_dir = './DATA/7Nov2023';  %% Example DIR [HAS A PROTOCOL ERRORS]
%main_dir = './DATA/3Nov2023';  %% Example DIR [HAS A PROTOCOL ERRORS]
%main_dir = './DATA/2Nov2023';   %% Example DIR [HAS A PROTOCOL ERRORS]

%main_dir = './DATA/26Oct2023';  %% Example DIR [HAS A PROTOCOL ERRORS]
%main_dir = './DATA/25Oct2023';  %% Example DIR [HAS A PROTOCOL ERRORS]
%main_dir = './DATA/24Oct2023';  %% Example DIR [HAS A PROTOCOL ERRORS]

%main_dir = './DATA/17Oct2023';  %% Example DIR [HAS A PROTOCOL ERRORS]
%main_dir = './DATA/16Oct2023';  %% Example DIR [HAS A PROTOCOL ERRORS]
%main_dir = './DATA/14Oct2023';  %% Example DIR [HAS A PROTOCOL ERRORS]
%main_dir = './DATA/10Oct2023';  %% Example DIR [HAS A PROTOCOL ERRORS]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% "SWEEP"
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%main_dir = './DATA/28Jul2023';   %% Example DIR 

% main_dir = './DATA/4Aug2023';   %% Example DIR 
% main_dir = './DATA/24Sep2023';   %% Example DIR 
% main_dir = './DATA/12Sep2023';   %% Example DIR 
% main_dir = './DATA/7Sep2023';   %% Example DIR 
%main_dir = './DATA/5Sep2023';   %% Example DIR 
%main_dir = './DATA/12Jul2023';   %% Example DIR 
% main_dir = './DATA/4July2023';   %% Example DIR 
% main_dir = './DATA/30Aug2023';   %% Example DIR 
% main_dir = './DATA/2Aug2023';   %% Example DIR 
%main_dir = './DATA/25Aug2023';  %% Example DIR 
% main_dir = './DATA/11Aug2023';  %% Example DIR 


% VA for :

clear textprogressbar;

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


    if (ismember(eachdir, { '.', '..'}))
        continue;
    end

    each_sweep_dir = fullfile (main_dir,eachdir);

    if (contains(eachdir, { 'sweeper' }) & isfolder(each_sweep_dir))    
        fprintf ('found ... %s [sweeper]\n', eachdir);
        run_sweeper_invisible_analysis (each_sweep_dir);
    elseif (contains(eachdir, { 'sweep' }) & isfolder(each_sweep_dir))    
        fprintf ('found ... %s\n', eachdir);
        run_sweep_invisible_analysis (each_sweep_dir);
    else
        %% default is now sweeper
        fprintf ('ignore ... %s\n', eachdir);
        % run_sweeper_invisible_analysis (each_sweep_dir);
    end
end

