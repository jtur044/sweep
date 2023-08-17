
% main_dir = "/Volumes/okn/DATA/BROOKS/TEST"
% main_dir = "./DATA/BROOKS/TEST"

main_dir = "/Volumes/BACKUP/DATA/BROOKS.WORKING/TEST";
%main_dir = "/Volumes/BACKUP/DATA/BROOKS.WORKING/TEST2";


% STEP 1 - run OpenFace

% batch_sweep_webcam_processor (main_dir, "OpenFace", "dryrun", true);

% STEP 2 - run EyeTracker 

%batch_sweep_webcam_processor (main_dir, "EyeTracker", "dryrun", false);

% STEP 3 - run Updater 

% batch_sweep_webcam_processor (main_dir, "Updater", "dryrun", false);

% STEP 4 - run Okndetector 

% batch_sweep_webcam_processor (main_dir, "Okndetector", "dryrun", false);

% STEP 5 - run SignalUpdater add activity fields 

% batch_sweep_webcam_processor (main_dir, "SignalUpdater", "dryrun", false);

% STEP 6 - run SweepAnalyzer  (per individual sweep information)

batch_sweep_webcam_processor (main_dir, "SweepAnalyzer", "dryrun", false);

% STEP 7 - Data viewer   (individual sweeps)

batch_sweep_webcam_processor (main_dir, "SweepVisualizer", "dryrun", false);

% STEP 8 - Sweep Viewer

batch_sweep_webcam_reporter (main_dir);