function demo_quick_sweep_set


close all;

maindir = './DATA';


%% Jason Sweep x v4 

sweep_set = {  '28Mar2023/jtur28_03_2023_odd_even_log_0', ... 
               '28Mar2023/jtur28_03_2023_odd_even_log_1', ...
               '28Mar2023/jtur28_03_2023_odd_even_log_2', ...
               '28Mar2023/jtur28_03_2023_odd_even_log_3', ...
               '28Mar2023/jtur28_03_2023_odd_even_log_4' };


info.descending.max_logMAR = 1.0;
info.descending.min_logMAR = 0.2;
info.descending.ratio      = 0.2/2;
info.ascending.max_logMAR  = 0.9;
info.ascending.min_logMAR  = 0.1;
info.ascending.ratio       = 0.2/2;

info.xtra.logmar_step       = 0.2;
info.xtra.win_length        = 2;
info.xtra.max_logMAR        = 1.0;
info.xtra.min_logMAR        = 0.1;
info.xtra.ratio             = info.xtra.logmar_step/info.xtra.win_length;

%% algorithm information 
info.xtra.FontSize          = 18;
info.xtra.lower_threshold   = 0.25;
info.xtra.upper_threshold   = 0.75;

VA_ETDRS = 0;

%% standard trial directory 

trial_dir = 'trials';

%% specific to the protocol used  - descending trial and then ascending trial.

sweep_trials = { 'trial-2_right_even_down', 'trial-4_right_odd_up', 'trial-6_right_even_up', 'trial-8_right_odd_down' };

close all;

N = length (sweep_set);
for k = 1:N 

    %% everything was OK

    M = length (sweep_trials);
    for l=1:M
    
        each_sweep_dir = fullfile (maindir,sweep_set{k}, trial_dir, sweep_trials{l});     
        if (exist (each_sweep_dir, 'dir'))
            
            figure (k); clf;
            % show_bidirectional_sweep (each_bisweep_dir, VA_ETDRS, info)
    
            right_even_down_datafile = fullfile (each_sweep_dir, 'result/signal.csv');
            right_odd_up_datafile    = fullfile (each_sweep_dir, 'result/signal.csv'); 
            right_even_up_datafile   = fullfile (each_sweep_dir, 'result/signal.csv');
            right_odd_down_datafile  = fullfile (each_sweep_dir, 'result/signal.csv'); 
            
            descend_even_Tbl       = readtable (right_even_down_datafile);
            ascend_odd_Tbl         = readtable (right_odd_up_datafile);
            descend_odd_Tbl        = readtable (right_odd_down_datafile);
            ascend_even_Tbl        = readtable (right_even_up_datafile);
            
    
            % x2 sweep
    
            ret_info_1(k) = analyze_bidrectional_interlaced_sweep (descend_even_Tbl, ascend_odd_Tbl, info);
            show_bidirectional_sweep (descend_even_Tbl, ascend_odd_Tbl, VA_ETDRS, info)
    
            ret_info_2(k) = analyze_bidrectional_interlaced_sweep (descend_odd_Tbl, ascend_even_Tbl, info);
            show_bidirectional_sweep (descend_odd_Tbl, ascend_even_Tbl, VA_ETDRS, info)
    
        end 

    end

end

ret_info_1
ret_info_2


%% columns 
meanVA      = [ ret_info_1.meanVA ];       meanVA = meanVA(:);
ascendData  = [ ret_info_1.ascending ];    
descendData = [ ret_info_1.descending ];   



%ascendVA    = [ ascendData.VA ];  ascendVA = ascendVA (:);
%descendVA   = [ descendData.VA ]; descendVA = descendVA (:);
%pickupTime  = [ ascendData.t ];  pickupTime = pickupTime (:);
%dropoffTime = [ descendData.t ]; dropoffTime = dropoffTime (:);


%finalTbl = table (meanVA, ascendVA, descendVA, pickupTime, dropoffTime);
%finalTbl.isValid = (descendVA < ascendVA);
%isValid = finalTbl.isValid;

%fprintf ('mean   = %4.2f\n', mean(finalTbl.meanVA));
%fprintf ('95%% CI = %4.2f]\n', 1.96*std(finalTbl.meanVA));



finalTbl

end

%% Show bi-directional sweep 

function ret = check_required_dir (each_bisweep_dir, sweep_trials)
    ret = true;
    for k = 1:length (sweep_trials)
        each_required_dir = fullfile (each_bisweep_dir, sweep_trials{k});
        if (~exist (each_required_dir, 'dir'))
            fprintf ('could not find .... %s\n', each_required_dir);
            ret = false;
            return
        end
    end    
end 


function ret_info = analyze_bidrectional_interlaced_sweep (Tbl1, Tbl2, info, dirn)
   

% Tbl1 = descending 
% Tbl2 = ascending 

%% general setup  

VA          = @(t, xstart, dirn, ratio) xstart+dirn*ratio*t;
ratio       = info.xtra.logmar_step/info.xtra.win_length;

%% read descending sweep - look for activity "drop off"

lower = info.xtra.lower_threshold;
upper = info.xtra.upper_threshold;

%n_points    = (info.descending.max_logMAR - info.descending.min_logMAR)/0.1 + 1;
%time_points = (0:(n_points+1))*info.win_length;


t = Tbl1.t;
[r, q] = get_sweep_activity (Tbl1, info.xtra.win_length);
[k, i] = find_activity (r, q, 'drop-off', 'lower_threshold', lower, 'upper_threshold', upper);
ret_info.descending.VA = t2logMAR (t(k), -1, info.descending);
ret_info.descending.t  = t(k); 
ret_info.descending.k  = k; 
ret_info.descending.activity = [ t r q ];


%% read ascending sweep - look for activity "pick up"

%n_points    = (info.ascending.max_logMAR - info.ascending.min_logMAR)/0.1 + 1;
%time_points = (0:(n_points+1))*info.win_length;

t = Tbl2.t;
[r, q] = get_sweep_activity (Tbl2, info.xtra.win_length);
[k, i] = find_activity (r, q, 'pick-up', 'lower_threshold', lower, 'upper_threshold', upper);

ret_info.ascending.VA = VA (t(k), info.ascending.min_logMAR, +1, ratio)
ret_info.ascending.t  = t(k); 
ret_info.ascending.k  = k; 
ret_info.ascending.activity = [ t r q ];
%ret_info.ascending.n_points;
 

ret_info.meanVA = 0.5*(ret_info.ascending.VA + ret_info.descending.VA);

end


function show_bidirectional_sweep (descendTbl, ascendTbl, VA_ETDRS, info)

if (nargin ==2)
    limits = [ -0.2 1.0 ]
end

%% bi-directional sweep  

%fs = info.FontSize; % font size

%% general setup  

VA          = @(t, xstart, dirn, ratio) xstart+dirn*ratio*t;
ratio       = info.xtra.logmar_step/info.xtra.win_length;

% n_points    = (info.max_logMAR - info.min_logMAR)/0.1 + 1;
% time_points = (0:(n_points+1))*info.win_length;


%% analyze the tables 

% descendTbl  = readtable (f1);
% ascendTbl   = readtable (f2);
% ret_info   = analyze_bidrectional_sweep (descendTbl, ascendTbl, info);

ret_info = analyze_bidrectional_interlaced_sweep (descendTbl, ascendTbl, info);

% determine mean VA 
fprintf ('final VA = %4.2f\n', ret_info.meanVA);


subplot (2,1,1); 

n_points    = (info.xtra.max_logMAR - info.xtra.min_logMAR)/0.1 + 1;
time_points = (0:(n_points+1))*info.xtra.ratio;

show_sweep ( descendTbl, ret_info.descending, info.descending, -1, info.xtra)
sig = findobj(gca, 'Tag', 'dataline');
act = findobj(gca, 'Tag', 'activity');
legend ([sig act ], { 'signal', 'activity' });


subplot (2,1,2); 

n_points    = (info.ascending.max_logMAR - info.ascending.min_logMAR)/0.1 + 1;
time_points = (0:(n_points+1))*info.xtra.win_length;

show_sweep ( ascendTbl, ret_info.ascending, info.ascending, +1, info.xtra)

meanVA = sprintf('mean. VA = %4.2f logMAR', ret_info.meanVA);
strETDRS = sprintf('VA (ETDRS) = %4.2f logMAR', VA_ETDRS);
textbox ({ meanVA, strETDRS }, 'FontSize', info.xtra.FontSize, 'HorizontalAlignment', 'left');


%% ADDITIONAL INFORMATION 
% subplot (2,1,1);
% subplot (2,1,2);


end



function show_sweep ( dataTbl, ret_info, info, dirn, xtra)


%% general setup  

VA          = @(t, xstart, dirn, ratio) xstart+dirn*ratio*t;
ratio       = xtra.logmar_step/xtra.win_length;
n_points    = (info.max_logMAR - info.min_logMAR)/0.1 + 1;
time_points = (0:(n_points+1))*xtra.win_length;

profile.mean_shift  = true;
[y_info, H]         = show_signal (dataTbl, profile);
ylabel ('Normalized Displacement');
grid on;

xticks(time_points);
xlim([ min(time_points) max(time_points) ]);
ylim([ -0.1 0.3 ]);
set(gca, 'FontSize', xtra.FontSize);


k    = ret_info.k;
t_VA = ret_info.t;
VA   = ret_info.VA;


%% show a blob at point 

if (~isempty(k))

    scatter (t_VA,  y_info(k), 'sizeData', 100, 'MarkerFaceColor','k', 'MarkerEdgeColor','k');
    line ([ t_VA t_VA ], [ -1 1 ], 'LineWidth', 1.5, 'Color','k');
    h = text(t_VA, 0.25, sprintf(' VA_↓ = %4.2f logMAR', VA));
    set(h, 'FontSize', xtra.FontSize);
    fprintf ('VA (descending) = %4.2f\n', VA);

end


xaxis2logMAR (dirn, info);

%% show the signal acitivity signal

yyaxis right;
t_act = ret_info.activity(:,1);
r_act = ret_info.activity(:,2);
h = plot(t_act, r_act, 'k--');
set(h, 'Tag', 'activity');

ylim([-1 2]);
ylabel ('Activity');
set(gca, 'YColor', 'k');


end


function xaxis2logMAR (dirn, info)
    x0 = xticks;    
    logmar = t2logMAR (x0, dirn, info);
    xticklabels(compose('%4.1f', logmar).');
end

function x0 = logMAR2Time (logmar, x_start, dirn, ratio)
    x0 = (logmar - x_start)/(dirn*ratio);
end


function textbox (strInfo, varargin) 
    pos = gca; pos = pos.Position; 
    pos(1) = pos(1) + 0.0025;
    pos(2) = pos(2) - 0.01;    
    annotation('textbox', pos, 'String', strInfo, 'FitBoxToText', true, 'BackgroundColor','w', varargin{:})

end 
