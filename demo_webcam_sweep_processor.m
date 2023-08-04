% DEMO_WEBCAM_SWEEP_PROCESSOR 
%



maindir = "./DATA/JEAN_BATTEN_SCHOOL/24May2023";

which_dir = { 'rerun_aahm_24_05_2023_sweep_three' };

% run_webcam_sweep_processor (maindir, which_dir, 'OpenFace', 'dryrun', false);
run_webcam_sweep_processor (maindir, which_dir, 'VideoSplitter', 'videofile', 'video.mp4',     'timeline', 'timeline.json', 'dryrun', false);
run_webcam_sweep_processor (maindir, which_dir, 'VideoSplitter', 'videofile', 'PLM_video.mp4', 'timeline', 'timeline.gaze.json', 'speed_factor', 0.5, 'dryrun', false);


% run OpenFace 




