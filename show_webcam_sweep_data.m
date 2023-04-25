function [data, events] = show_webcam_sweep_data  (filename, tracker_name, varargin) % configfile, dataTbl, tracker_name, varargin)

% SHOW_WEBCAM_SWEEP_DATA Show data from eyetracker/results.csvtracker result matrix
%
%   show_webcam_sweep_data  (filename, tracker_name, varargin)
%
% where 
%       configfile   is the configuration file  
%       dataTbl      is the data table 
%       tracker_name is the Tracker Id   
%
% EXAMPLE 
%
%  %% Tracker names "eye_pupil_tracker_os" & "eye_pupil_tracker_od"  
%  
%  figure (1); clf;
%  show_webcam_sweep_data  ('./DATA/BROOKS/kj_4_18_23/result/eyetracker/results.csv', 'eye_pupil_tracker_os'); 
%
%  figure (2); clf;
%  show_webcam_sweep_data  ('./DATA/BROOKS/kj_4_18_23/result/eyetracker/results.csv', 'eye_pupil_tracker_od'); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD RESULT 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser ();
p.addOptional ('setupfile', 'config/eyetracker.webcam-brooks.json');
p.addOptional ('displayMask', true);
p.addOptional ('UseProfile', 'default');
p.addOptional ('X', 0);
p.addOptional ('Y', 0);
p.parse(varargin{:});
res = p.Results;

%% get a CONFIG object or a file 
[branchdir, ~,~] = fileparts (filename);
config = recursive_load (branchdir, res.setupfile);

%% read DataTable 
try
    if (ischar(filename))
        dataTbl = readtable (filename);
    end
catch ME 
    error (sprintf('Couldnt locate file ... ', filename));
end

%% get the appropriate profile / tracker 
input   = findfield (config.Graph.Profiles, 'name', res.UseProfile);
tracker = findfield (config.Trackers, 'name', tracker_name);
subTable = dataTbl(dataTbl.TrackerId == tracker.TrackerId, :);


%% show graphs    
yyaxis left;
h = show_graph (subTable, input, res.X, res.Y);


if (res.displayMask)
    yyaxis right;
    g = show_mask (subTable, input, res.X, res.Y);
    ylim([-1, 1]);
end


legend([ h g ],'Signal','Track','Blink');

%if (profile.overlay)
%   showOKN (data, profile, 0, 0);
%end
     
end

function y = findfield(part, whichPart, whichVal)

    M = length (part);
    for k = 1:M
    
        if (strcmp(part{k}.(whichPart), whichVal))
            y = part{k};
        end
    end
    
end

