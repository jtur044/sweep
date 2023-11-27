function xlim_data = show_sweeper_events (sweeper, varargin)

% SHOW_SWEEPER_EVENTS Show events in the sweeper
%
% function show_sweeper_events (sub_events, varargin)
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
end_timestamp   = sweeper.sweep_event.end.(res.which_timestamp);

%% extract ONLY "sweep" sub_event timestamps 
%this_sweep = sweeper.sweep_steps;
[xdata_sweep, ~]  = find_sweeper_info_per_category (sweeper.sub_events, "sweep", res.which_timestamp);

%% extract ONLY "exit" sub_event timestamps 
[xdata_exit, ~] = find_sweeper_info_per_category (sweeper.sub_events, "exit", res.which_timestamp);
xdata = [ xdata_sweep xdata_exit ] - offset_timestamp;

%% information
I = ones(1, length(xdata));
line ([xdata ; xdata ],[-10*I ; 10*I], 'LineStyle', '-', 'Color', [ 0.5 0.5 0.5]);

%% start patch 
r = bbox2points ([ 0 -10 xdata(1) 20 ]);
patch(r(:,1), r(:,2), 'b', 'faceAlpha',0.1);

%% end patch 
w = end_timestamp-xdata_exit(end);
r = bbox2points ([ xdata(end) -10 w 20 ]);
patch(r(:,1), r(:,2), 'b', 'faceAlpha',0.1);

xlim_data = [ 0 xdata(end)+w ];
hold on;
return
