function [each_timeline_item, events] = find_sweep_in_timeline (timeline, which_sweep, varargin)

% FIND_SWEEP_IN_TIMELINE Find the sweep from 'timeline.json'
%
%   [main_event, sub_events] = find_sweep_in_timline (timeline, which_sweep)
%
% where 
%       main_event   is the over-arching event 
%       sub_events   is a list of sub-events 
%


    if (ischar(timeline) | isstring(timeline))
        timeline = load_commented_json (timeline);
    end



    events = [];
    each_timeline_item = [];


    sweep_counter = 1;
    for k = 1:length (timeline)

        each_timeline_item = timeline{k};

        %each_timeline_item;

        %% find sweep overall event 
        if ((isfield(each_timeline_item, 'start')) & (any(strcmpi(each_timeline_item.start.event.trial_type, { 'sweep_disks', 'sweeper_disks' }))))

            
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
                events = find_events_in (timeline, start_time, end_time, "sweep");  
                return
            end
        end
    end


    error (sprintf('Didnt find %s', which_sweep));

end





function events = find_events_in (timeline, start_time, end_time, event_category)


       counter = 1;

       for k = 1:length (timeline)

           each_timeline_item = timeline{k};
           if ((isfield(each_timeline_item, 'event')) & (strcmpi(each_timeline_item.event.event.event_category, event_category)))
               
               event_time = each_timeline_item.event.timestamp.pts_time;               
               if ((start_time < event_time) && (event_time < end_time))
                    events(counter) = each_timeline_item;
                    counter = counter + 1;
               end
           end
       end

end