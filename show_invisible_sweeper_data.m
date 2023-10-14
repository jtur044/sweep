function [y0, t0] = show_invisible_sweeper_data  (filename, varargin) % configfile, dataTbl, tracker_name, varargin)

% SHOW_INVISIBLE_SWEEP_DATA Show data from eyetracker/results.csvtracker result matrix
%
%   show_invisible_sweep_data  (filename, tracker_name, varargin)
%
% where 
%       configfile   is the configuration file  
%       dataTbl      is the data table 
%       tracker_name is the Tracker Id   
%
% Optional:
%
%       offset is time where   
%
%
% EXAMPLE 
%
%  %% Tracker names "eye_pupil_tracker_os" & "eye_pupil_tracker_od"  
%  %
%  % Subequent to : run_updater.m
%
%  figure (1); clf;
%  show_invisible_signal_data  ('./DATA/BROOKS.PROCESSED/kj_4_18_23/result/eyetracker/results.updated.csv', 'eye_pupil_tracker_os'); 
%
%  figure (2); clf;
%  show_invisble_sweep_data  ('./DATA/BROOKS.PROCESSED/kj_4_18_23/result/eyetracker/results.updated.csv', 'eye_pupil_tracker_od'); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD RESULT 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser ();
%p.addOptional ('setupfile', 'config/eyetracker.webcam-brooks.json');
p.addOptional ('displayMask', true);
%p.addOptional ('UseProfile', 'signal_displacement');
p.addOptional ('showActivity', false);
p.addOptional ('showTimePoint', []);
p.addOptional ('text', []);
p.addOptional('Color',[ 0 0 0 1 ]);

%p.addOptional ('timeline', []);
p.addOptional ('X', 0);
p.addOptional ('Y', 0);
p.addOptional ('offset', 0);

p.parse(varargin{:});
res = p.Results;

%% read into DataTbl  
try
    if (isstring(filename) | ischar(filename))
        dataTbl = readtable (filename);
    end
catch ME 
    error (sprintf('Couldnt locate file ... ', filename));
end

%% show the basic signal (t variable)

input.mean_shift = true;
input.t = 't';

[t0, y0] = show_signal (dataTbl, input, "showTimePoint", res.showTimePoint, "Color", res.Color); % , input, res.X, res.Y);


%% show the offset 

if (res.offset > 0)       
    h = line([res.offset res.offset],[-100 100]);
    set(h,'LineWidth',2);
    set(h,'LineStyle','--');    
end


%% if activity information is available then show that 
if (ismember("activity", dataTbl.Properties.VariableNames) & (res.showActivity))
   yyaxis right;
   plot (dataTbl.t, dataTbl.activity, ':');
   ylim([-0.1 1.1])
   %ylabel ('Activity');
end




end




