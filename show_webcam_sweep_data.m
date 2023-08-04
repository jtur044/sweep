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
%  %
%  % Subequent to : run_updater.m
%
%  figure (1); clf;
%  show_webcam_sweep_data  ('./DATA/BROOKS.PROCESSED/kj_4_18_23/result/eyetracker/results.updated.csv', 'eye_pupil_tracker_os'); 
%
%  figure (2); clf;
%  show_webcam_sweep_data  ('./DATA/BROOKS.PROCESSED/kj_4_18_23/result/eyetracker/results.updated.csv', 'eye_pupil_tracker_od'); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD RESULT 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser ();
p.addOptional ('setupfile', 'config/eyetracker.webcam-brooks.json');
p.addOptional ('displayMask', true);
p.addOptional ('UseProfile', 'updated_by_nosetip');
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
%yyaxis left;
h = show_graph (subTable, input, res.X, res.Y);



%% Show a timeline 

timeline = recursive_load (branchdir, 'timeline.json');
if (~isempty(timeline))
    k0 = show_events (timeline);
end



startTime = min(subTable.currentTime);
endTime   = max(subTable.currentTime);

xlim ([ startTime endTime ]);

%if (profile.overlay)
%   showOKN (data, profile, 0, 0);
%end
     
grid on;

if (res.displayMask)
    %yyaxis right;
    g = show_mask (subTable, input, res.X, -140);
    
    % ylim([-1, 1]);
    % y

legend([ h(1) g(2) g(1) k0(1) ],'Signal','Tracking','Lost','Rest');

set(gca,'FontSize',20);
ylim([-150 150]);

%yaxis left;
end

end


function ev = show_events (timeline)


    count = 1;
    event_counter = 1;

    for k = 1:length (timeline)

        each_timeline_item = timeline{k};

        %% START/END ITEMS 
        if (isfield(each_timeline_item, 'start') && (strcmpi(each_timeline_item.start.event.trial_type, "animation")))

            start_time = each_timeline_item.start.timestamp.pts_time;
            end_time   = each_timeline_item.end.timestamp.pts_time;


            ev(count) = show_event (start_time, end_time, 300, 'FaceColor', 'b', 'FaceAlpha',0.1);
            
            %h(count) = patch ();
            count = count + 1;
            

            % h(count) = line ([ start_time start_time ], [-100 100]);
            % count = count + 1;
            % h(count) = line ([ end_time end_time ], [-100 100]);

        end

    end

    %set(h, 'Color','k');


    %% add down-sweep information  
    [sweep_event, sub_events] = find_sweep (timeline, "right_down", 1);        
    [xdata, xlabels] = get_down_sweep_ticks (sweep_event, sub_events);

    xtick_data   = xdata;
    xtick_labels = xlabels; 

    %% add up-sweep information 
    [sweep_event, sub_events] = find_sweep (timeline, "right_up", 1);
    [xdata, xlabels] = get_up_sweep_ticks (sweep_event, sub_events);

    xtick_data   = [ xtick_data xdata ];
    xtick_labels = [ xtick_labels xlabels ]; 
   
    

%disp ('timeline');
xticks (xtick_data);
xticklabels (xtick_labels);
xlabel ('logMAR');

end


function [xdata, xlabels] = get_down_sweep_ticks (sweep_event, sub_events)
    
    for k = 1:length (sub_events)
        xdata(k)   = sub_events(k).event.timestamp.pts_time;

        this_logmar = str2num(sub_events(k).event.event.logmar_level);
        xlabels{k} = this_logmar + 0.1;    
    end
    
    %% additional one for end
    xdata(k+1)   = sweep_event.end.timestamp.pts_time;
    xlabels{k+1} = this_logmar;

end

function [xdata, xlabels] = get_up_sweep_ticks (sweep_event, sub_events)

    for k = 1:length (sub_events)
        xdata(k)   = sub_events(k).event.timestamp.pts_time;
        this_logmar = str2num(sub_events(k).event.event.logmar_level);
        xlabels{k} = this_logmar;    
    end

    %% additional one for end
    xdata(k+1) = sweep_event.end.timestamp.pts_time;
    xlabels{k+1} = this_logmar + 0.1;

end



function y = findfield(part, whichPart, whichVal)

    M = length (part);
    for k = 1:M
    
        if (strcmp(part{k}.(whichPart), whichVal))
            y = part{k};
        end
    end
    
end


function events = find_events_in (timeline, start_time, end_time)

       counter = 1;

       for k = 1:length (timeline)

           each_timeline_item = timeline{k};
           if (isfield(each_timeline_item, 'event'))
               event_time = each_timeline_item.event.timestamp.pts_time;               
               if ((start_time < event_time) && (event_time < end_time))
                    events(counter) = each_timeline_item;
                    counter = counter + 1;
               end
           end
       end

end



function [each_timeline_item, events] = find_sweep (timeline, which_sweep, sweep_number)

    events = [];
    each_timeline_item = [];


    sweep_counter = 1;
    for k = 1:length (timeline)

        each_timeline_item = timeline{k};

        %% find sweep overall event 
        if (isfield(each_timeline_item, 'start') && (strcmpi(each_timeline_item.start.event.trial_type, "sweep_disks")))

            
            %% check which type of sweep  
            if (strcmpi (each_timeline_item.start.event.trial_index, which_sweep)) 

                %% ... its a sweep event - is it the enumerated one 
                if (sweep_number ~= sweep_counter)
                    sweep_counter = sweep_counter + 1;
                    continue;
                end
                
                %% OK weve got the right event record it 
                start_time = each_timeline_item.start.timestamp.pts_time;
                end_time   = each_timeline_item.end.timestamp.pts_time;
                events = find_events_in (timeline, start_time, end_time);
                return
            end
        end
    end
end
