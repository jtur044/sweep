function [main, sub_events] = find_sweeper_in_events (events, which_sweep)

% FIND_SWEEP_IN_TIMELINE Find the sweep from 'timeline.json'
%
%   [main_event, sub_events] = find_sweep_in_timline (timeline, which_sweep)
%
% where 
%       main_event   is the over-arching event 
%       sub_events   is a list of sub-events 
%


    if (ischar(events) | isstring(events))
        events = load_commented_json (events);
    end


    %% find the start and end events 
    [start_event, n1] = find_start_marker (events, which_sweep, 1);
    [end_event, n2]   = find_end_marker (events, which_sweep, n1);

    %% grab all events in between
    main.start = start_event;
    main.end   = end_event;
    
    %% we want all sub_events (event_marker)
    count = 1;    
    for k = (n1+1):(n2-1)
        this_event = events{k};

        if (~strcmpi(this_event.type, 'event_marker'))
            continue;
        end

        %% only want extneded events I think

        %if  (strcmpi(this_event.event_category, which_category))
            if (count == 1)
                sub_events = this_event;
            else
                sub_events(count) = this_event;
            end
            count=count+1;
        %end
    end
end
    
function [each_event, k] = find_start_marker (events, which_sweep, n)


    for k = n:length (events)
        each_event = events{k};       
        if (isfield(each_event, 'trial_type') & (strcmpi(each_event.type, 'start_marker')))
            if ((strcmpi(each_event.trial_type, 'sweeper_disks')) & ...
                    (strcmpi(each_event.trial_id, which_sweep)))              
                return
            end
        end
    
    end

    error ('Couldnt find START event.');

end


function [each_event, k] = find_end_marker (events, which_sweep, n)
    
    each_event = [];

    for k = n:length (events)
        each_event = events{k};  

        if (strcmpi(each_event.type,'end_marker'))
                if (strcmpi(each_event.trial_type, 'sweeper_disks'))  
                    
                    %% kludgy check
                    check_num = str2num(sscanf(which_sweep,'trial-%s'))-1;                
                    if (str2num(each_event.trial_index) == check_num)    
                        return
                    end
                end
        end
    end

    error ('Couldnt find END event.');

end