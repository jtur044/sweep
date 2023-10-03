function [y0, t0] = show_invisible_sweep_data  (filename, which_sweep,  timeline, dirn, varargin) % configfile, dataTbl, tracker_name, varargin)

% SHOW_INVISIBLE_SWEEP_DATA Show data from eyetracker/results.csvtracker result matrix
%
%   show_invisible_sweep_data  (filename, tracker_name, varargin)
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
p.parse(varargin{:});
res = p.Results;

%% get a CONFIG object or a file 
%[branchdir, ~,~] = fileparts (filename);
%config = recursive_load (branchdir, res.setupfile);

%% read DataTable 
try
    if (isstring(filename) | ischar(filename))
        dataTbl = readtable (filename);
    end
catch ME 
    error (sprintf('Couldnt locate file ... ', filename));
end


%% get the appropriate profile / tracker 
%input   = findfield (config.Graph.Profiles, 'name', res.UseProfile);
%tracker = findfield (config.Trackers, 'name', tracker_name);
%subTable = dataTbl(dataTbl.TrackerId == tracker.TrackerId, :);


%% show graphs    

input.mean_shift = true;
input.t = 't';

[t0, y0] = show_signal (dataTbl, input, "showTimePoint", res.showTimePoint, "Color", res.Color); % , input, res.X, res.Y);

% if  (~isempty(res.showTimePoint) && ~isempty(res.text))
%    text(t,yp0,res.txt)
% end


%% if activity information is available then show that 
if (ismember("activity", dataTbl.Properties.VariableNames) & (res.showActivity))
   yyaxis right;
   plot (dataTbl.t, dataTbl.activity, ':');
   ylim([-0.1 1.1])
   %ylabel ('Activity');
end




%(dataTable, profile,

%% Show a timeline 


startTime = min(dataTbl.(input.t));
endTime   = max(dataTbl.(input.t));
xlim ([ startTime endTime ]);

%timeline = recursive_load (res.branchdir, 'timeline.json');
if (~isempty(timeline))
     % k0 = show_events (timeline);

    %% actual timelined ticks 
     show_logmar_ticks (timeline, which_sweep, dirn);

end


%if (profile.overlay)
%   showOKN (data, profile, 0, 0);
%end
     
grid on;

%if (res.displayMask)
    %yyaxis right;
    %g = show_mask (dataTbl, input, res.X, -140);
    
    % ylim([-1, 1]);
    % y

%legend([ h(1) g(2) g(1) ],'Signal','Tracking','Lost'); % ,'Rest');

%set(gca,'FontSize',20);
%ylim([-150 150]);

%yaxis left;
%end

end


function ev = show_events (timeline)


    count = 1;
    event_counter = 1;

    for k = 1:length (timeline)

        each_timeline_item = timeline{k};

        %% THIS IS AN ANIMATION  
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

function show_logmar_ticks (timeline, which, dirn)


%% add down-sweep information  
[sweep_event, sub_events] = find_sweep (timeline, which, 1);        

switch (dirn)

    case { -1 }
        [xdata, xlabels] = get_down_sweep_ticks (sweep_event, sub_events, "regularized", true);

    case { +1 }
        [xdata, xlabels] = get_up_sweep_ticks (sweep_event, sub_events, "regularized", true);

    otherwise
        error ('Unknown');

end

xtick_data   = xdata;
xtick_labels = xlabels; 

%%% add up-sweep information 
%[sweep_event, sub_events] = find_sweep (timeline, "right_up", 1);
%[xdata, xlabels] = get_up_sweep_ticks (sweep_event, sub_events);

%xtick_data   = [ xtick_data xdata ];
%xtick_labels = [ xtick_labels xlabels ]; 
   
%disp ('timeline');
xticks (xtick_data);
xticklabels (xtick_labels);
%xlabel ('logMAR');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% GET SWEEP TICKS 
%
%  Requires additional code to account for the 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function get_first_timestamp (sweep_event, sub_events)

    % find the first appropriate timestamp 
   if (strcmpi(sweep_event.event.trial_type, 'sweep_disks'))

       % standard is to take the first event 
       start_timestamp = sub_events(1).event.timestamp.pts_time;        
       return

   elseif strcmpi(sweep_event.event.trial_type, 'sweeper_disks'))

       % take the first 'sweep'         
       n = length (sub_events);
       for k = 1:n
           this_event = sub_events(k).event.event; 
           if (strcmpi(this_event.event,'sweep') && (this_event.sweep_counter == 0))
                start_timestamp = this_event.event.timestamp.pts_time;
                return
           end
       end
   end

end


function [xdata, xlabels] = get_down_sweep_ticks (sweep_event, sub_events, varargin)


    p = inputParser ();
    p.addOptional ('regularized', false);
    p.addOptional ('step_duration', 2);
    p.parse (varargin{:});
    res = p.Results;

    count = 1;

    %% very first time 


    start_timestamp = get_first_timestamp (sweep_event, sub_events);

 

    for k = 1:length (sub_events)

        if (strcmpi(sub_events(k).event.event.type, 'key_marker'))
            continue;
        end

        if (res.regularized)
            xdata(count)   = res.step_duration*(count-1);
        else
            xdata(count)   = sub_events(k).event.timestamp.pts_time - start_timestamp;        
        end

        this_logmar = str2num(sub_events(k).event.event.logmar_level);
        xlabels{count} = this_logmar + 0.1;    
        count = count + 1;
    end
    
    %% additional one for end
    if (res.regularized)
            xdata(count)   = res.step_duration*(count-1);
    else
            xdata(count) = sweep_event.end.timestamp.pts_time - start_timestamp;
    end
    xlabels{count} = this_logmar;


end

function [xdata, xlabels] = get_up_sweep_ticks (sweep_event, sub_events, varargin)

    p = inputParser ();
    p.addOptional ('regularized', false);
    p.addOptional ('step_duration', 2);
    p.parse (varargin{:});
    res = p.Results;


    count = 1;

    % start_timestamp = sweep_event.start.timestamp.pts_time;
    start_timestamp = get_first_timestamp (sweep_event, sub_events);


    for k = 1:length (sub_events)

        if (strcmpi(sub_events(k).event.event.type, 'key_marker'))
            continue;
        end

        if (res.regularized)
            xdata(count)   = res.step_duration*count;
        else
            xdata(count)   = sub_events(k).event.timestamp.pts_time - start_timestamp;        
        end

        this_logmar = str2num(sub_events(k).event.event.logmar_level);
        xlabels{count} = this_logmar;    
        count = count + 1;
    end

    %% additional one for end
    if (res.regularized)
            xdata(count)   = res.step_duration*count;
    else
            xdata(count) = sweep_event.end.timestamp.pts_time - start_timestamp;
    end

    xlabels{count} = this_logmar + 0.1;

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


%% This will find sweep_disks or sweeper_disks events 

function [each_timeline_item, events] = find_sweep (timeline, which_sweep, sweep_number)

    events = [];
    each_timeline_item = [];


    sweep_counter = 1;
    for k = 1:length (timeline)

        each_timeline_item = timeline{k};

        %each_timeline_item;

        %% find sweep overall event 
        if (isfield(each_timeline_item, 'start') && (strcmpi(each_timeline_item.start.event.trial_type, { "sweep_disks", "sweeper_disks" })))

            
            %% check which type of sweep  
            if (strcmpi (each_timeline_item.start.event.trial_id, which_sweep)) 

                %% ... its a sweep event - is it the enumerated one 
                %if (sweep_number ~= sweep_counter)
                %    sweep_counter = sweep_counter + 1;
                %    continue;
                %end
                
                %% OK weve got the right event record it 
                start_time = each_timeline_item.start.timestamp.pts_time;
                end_time   = each_timeline_item.end.timestamp.pts_time;
                events = find_events_in (timeline, start_time, end_time);
                return
            end
        end
    end


    error (sprintf('Didnt find %s %s', which_sweep, sweep_number));

end




%% GETPROFILE 

function each_profile = getprofile (setups, which_profile)
    each_profile = [];
    profiles = setups.Graph.Profiles;
    N = length (profiles);
    for k=1:N

        each_profile = profiles{k};

        if (strcmpi(each_profile.name, which_profile))
            return
        end
    end

    error ('Profile not found', which_profile);

    %if (isfield(profiles, which_profile))
    %    y = profiles.(which_profile);        
    %end    
end
