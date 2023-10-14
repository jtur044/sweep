function [xdata, xlabel] = find_sweeper_info_per_category (sub_events, category, which_timestamp)

% FIND_SWEEPER_INFO_PER_CATEGORY Find events per category 
% 
%   xdata = find_sweeper_timestamps_per_category (sweeper, category, which_timestamp)
%
% where 
%       sweeper         has entry | sweep | exit fields 
%       category        is entry | sweep | exit 
%       which_timestamp is sensor_timestamp 
%

count = 1; xdata = []; xlabel = [];
for k = 1:length (sub_events)
        this_sub_event = sub_events(k);
        
        if (strcmpi(this_sub_event.type, 'event_marker'))
            
            if (strcmpi(this_sub_event.event_category, category))
               
                %% show the line 
                xdata(count)  = this_sub_event.(which_timestamp);              
                xlabel{count} = this_sub_event.logmar_level;
                count = count + 1;
            end
        end
end

