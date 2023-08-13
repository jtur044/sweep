function [each_timeline_item, events] = find_sweep (timeline, which_sweep, sweep_number)

% FIND_SWEEP return sweep and its sub-events 
%
%   [each_timeline_item, events] = find_sweep (timeline, which_sweep, sweep_number)
%
% where 
%
%       timeline            is the loaded "timeline.json"
%       which_sweep         is the name of the sweep "right_down" |
%       "right_up"
%       each_timeline_item  is the timeline event 
%       events              are the individual events in the seweep
%       sweep_number        is unknown?
%
%
%

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


    error (sprintf('Didnt find %s %s', which_sweep, sweep_number));

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
