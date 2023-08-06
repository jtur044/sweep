
% main_dir = "/Volumes/okn/DATA/BROOKS/TEST"
main_dir = "./DATA/BROOKS/TEST"


% STEP 1 - run OpenFace

% batch_sweep_webcam_processor (main_dir, "OpenFace", "dryrun", true);

% STEP 2 - run EyeTracker 

% batch_sweep_webcam_processor (main_dir, "EyeTracker", "dryrun", false);

% STEP 3 - run Updater 

% batch_sweep_webcam_processor (main_dir, "Updater", "dryrun", false);

% STEP 4 - run Okndetector 


% STEP 5 - Data viewer  

figure (1); clf;

subplot (2,1,1);
show_webcam_sweep_data  (fullfile(main_dir, 'TESTOKN1_OD1', 'result/eyetrack/clip-1-right_down-sweep_disks/results.updated.csv'), 'right_down', 'eye_pupil_tracker_od'); 

subplot (2,1,2);
show_webcam_sweep_data  (fullfile(main_dir, 'TESTOKN1_OD1', 'result/eyetrack/clip-3-right_up-sweep_disks/results.updated.csv'), 'right_up', 'eye_pupil_tracker_od'); 


% configfile = './DATA/BROOKS.PROCESSED/kj_4_18_23/config/eyetracker.webcam-brooks.json';
% inputfile  = './DATA/BROOKS.PROCESSED/kj_4_18_23/result/eyetracker/results.csv';
% outputfile = './DATA/BROOKS.PROCESSED/kj_4_18_23/result/eyetracker/results.updated.csv';
% run_updater (configfile, inputfile, outputfile)