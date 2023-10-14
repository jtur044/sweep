function show_sweeper_logmar_ticks (sweeper, varargin)

% SHOW_SWEEPER_LOGMAR_TICKS Show SWEEPER locgmar ticks
%
% function show_sweeper_logmar_ticks (sub_events, varargin)
%
% where 
%       sweeper 
%               sweep_event is the main_event 
%               sub_event   is the sub events 
%

p = inputParser ();
p.addOptional ('which_timestamp',  'sensor_timestamp');
p.addOptional ('offset_timestamp', 0);
p.parse (varargin{:});
res = p.Results;

%% use the start marker to set the offset 
offset_timestamp = sweeper.sweep_event.start.(res.which_timestamp);

%% extract ONLY "sweep" sub_event timestamps 
[xdata_sweep, xlabels_sweep] = find_sweeper_info_per_category (sweeper.sub_events, "sweep", res.which_timestamp);

if (sweeper.sweep_direction == -1)
    xlabels_sweep = cellfun (@(x) str2num(x)+0.1, xlabels_sweep);
else
    xlabels_sweep = cellfun (@(x) str2num(x), xlabels_sweep);    
end

%% extract ONLY "exit" sub_event timestamps 
[xdata_exit, xlabels_exit] = find_sweeper_info_per_category (sweeper.sub_events, "exit", res.which_timestamp);

if (sweeper.sweep_direction == 1)
    xlabels_exit = cellfun (@(x) str2num(x)+0.1, xlabels_exit);
else
    xlabels_exit = cellfun (@(x) str2num(x), xlabels_exit);    
end

xdata   = [ xdata_sweep xdata_exit ] - offset_timestamp; 
xlabels = [ xlabels_sweep xlabels_exit ]; 

%% information 
xticks(xdata)
xticklabels(xlabels);

return
