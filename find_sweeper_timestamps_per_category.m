function xdata = find_sweeper_timestamps_per_category (sweeper, category, which_timestamp)

% FIND_SWEEPER_TIMESTAMPS_PER_CATEGORY Find events per category 
% 
%   xdata = find_sweeper_timestamps_per_category (sweeper, category, which_timestamp)
%
% where 
%       sweeper         has entry | sweep | exit fields 
%       category        is entry | sweep | exit 
%       which_timestamp is sensor_timestamp 
%

for k = 1:length (sweeper.sub_events)
        this_sub_event = sweeper.sub_events(k);
        
        if (strcmpi(this_sub_event.type, 'event_marker'))
            
            if (strcmpi(this_sub_event.event_category, category))
               
                %% show the line 
                xdata(count)  = this_sub_event.(which_timestamp);              
            end
        end
end

