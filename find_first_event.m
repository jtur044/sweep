function sub_event = find_first_event(sub_events, which_type)

% FIND_FIRST_EVENT Find the sweep from 'timeline.json'
%
%   sub_event = find_sweep_in_timline (timeline, which_sweep)
%
% where 
%       main_event   is the over-arching event 
%       sub_events   is a list of sub-events 
%

    for k = 1:length(sub_events)
        if (strcmpi (sub_events(k).event_category,which_type))             
            sub_event = sub_events (k);
            return
        end
    end

end
