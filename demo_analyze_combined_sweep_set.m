function finalTbl = demo_analyze_combined_sweep_set


close all;

maindir = './DATA';


%% Christo 

VA_ETDRS = 0.0;
sweep_set = 'Aug2/cfra_02_08_2023_sweep_left';
%sweep_set = 'Aug2/cfra_02_08_2023_sweep_right';

%% Jason Multiple 

%VA_ETDRS = 0.47;
%sweep_set = '22Mar2023/jtur_22_03_2023_five_sweep_len_from_4_to_0_two';
%sweep_set = '22Mar2023/jtur_22_03_2023_five_sweep_len_from_4_to_0';

%{

VA_ETDRS = -0.08;
sweep_set = '16Mar2023/sgui_16_03_2023_sweep_5_times_no_len';

%}




%% Shadi Sweep Set 1
%{

VA_ETDRS = 0.5;
sweep_set = '12Mar2023/sela_12_03_2023_okn_sweep_five_times_lens_two';

VA_ETDRS = -0.04;
sweep_set = '12Mar2023/sela_12_03_2023_okn_sweep_five_times_no_lens_two';

%}

%{

%% Sarah-Jane DAY 2


VA_ETDRS = 0.47;
sweep_set = '16Mar2023/sgui_16_03_2023_sweep_5_times_power_2_25';

VA_ETDRS = -0.08;
sweep_set = '16Mar2023/sgui_16_03_2023_sweep_5_times_no_len';


%}



%% Sarah-Jane DAY 1

%{

VA_ETDRS = 0.47;
sweep_set = '14March2023/sgui_14_march_2023_with_lens2_25';

VA_ETDRS = -0.08;
sweep_set = '16Mar2023/sgui_14_march_2023_without_lens_2';

%}



%% Informational 

info.max_logMAR  = 1.0;
info.min_logMAR  = 0.0;
info.logmar_step = 0.1;
info.win_length  = 2;
info.ratio       = 0.1/2;
info.FontSize    = 18;

info.lower_threshold = 0.25;
info.upper_threshold = 0.75;

% VA_ETDRS = 0;

%% standard trial directory 

trial_dir = 'trials';

%% specific to the protocol used  - descending trial and then ascending trial.

sweep_trials = { { 'trial-2_right_down',  'trial-4_right_up' }, ... 
                 { 'trial-6_right_down',  'trial-8_right_up' }, ... 
                 { 'trial-10_right_down', 'trial-12_right_up' }, ... 
                 { 'trial-14_right_down', 'trial-16_right_up' }, ... 
                 { 'trial-18_right_down', 'trial-20_right_up' }};

close all;

N = length (sweep_trials);
for k = 1:N 

    %% everything was OK

    each_bisweep_dir = fullfile (maindir, sweep_set, trial_dir);     
    each_bisweep_trial = sweep_trials {k};

    %if (check_required_dir (each_bisweep_dir))
        
        figure (k); clf;

        %% get closest name 
        pass_one_dir = get_closest_dir(each_bisweep_dir, each_bisweep_trial{1});
        pass_two_dir = get_closest_dir(each_bisweep_dir, each_bisweep_trial{2});
        
        descend_datafile = fullfile (pass_one_dir, 'result/signal.csv');
        ascend_datafile  = fullfile (pass_two_dir, 'result/signal.csv'); %% descend 

        descendTbl = readtable (descend_datafile);
        ascendTbl  = readtable (ascend_datafile);
        
        ret_info(k) = analyze_bidrectional_sweep (descendTbl, ascendTbl, info);
        show_bidirectional_sweep (descendTbl, ascendTbl, VA_ETDRS, info)

    %end 

end

% ret_info.ascending
% ret_info


%% columns 
meanVA      = [ ret_info.meanVA ];       meanVA = meanVA(:);
ascendData  = [ ret_info.ascending ];    
descendData = [ ret_info.descending ];   

ascendVA    = [ ascendData.VA ];  ascendVA = ascendVA (:);
descendVA   = [ descendData.VA ]; descendVA = descendVA (:);
pickupTime  = [ ascendData.t ];  pickupTime = pickupTime (:);
dropoffTime = [ descendData.t ]; dropoffTime = dropoffTime (:);


finalTbl = table (meanVA, ascendVA, descendVA, pickupTime, dropoffTime);
%finalTbl.isValid = (descendVA < ascendVA);
%isValid = finalTbl.isValid;

fprintf ('mean   = %4.2f\n', mean(finalTbl.meanVA));
fprintf ('95%% CI = %4.2f]\n', 1.96*std(finalTbl.meanVA));



%finalTbl

end

%% Show bi-directional sweep 

function [closest_dir, ret] = get_closest_dir (each_bisweep_dir, pass_words)
    ret = true;
    closest_dir = fullfile (each_bisweep_dir, [ pass_words '*' ]);
    result = dir (closest_dir);
    if (isempty (result))
       fprintf ('could not find .... %s\n', closest_dir);
       ret = false;
       return
    end
          
    if (length(result) > 1)
       fprintf ('too many matches .... %s\n', closest_dir);
       error ('Inconsistency.');
    end

    ret = true;
    closest_dir = fullfile (each_bisweep_dir, result.name);    
    return
end 

%% get closest file 

function ret = check_required_dir (each_bisweep_dir, sweep_trials)
    ret = true;
    for k = 1:length (sweep_trials)
        each_required_dir = fullfile (each_bisweep_dir, [ sweep_trials{k} '*' ]);
        dir(each_required_dir);
        if (~exist (each_required_dir, 'dir'))
            fprintf ('could not find .... %s\n', each_required_dir);
            ret = false;
            return
        end
    end    
end 



function ret_info = analyze_bidrectional_sweep (descendTbl, ascendTbl, info)
   

%% general setup  

VA          = @(t, xstart, dirn, ratio) xstart+dirn*ratio*t;
ratio       = info.logmar_step/info.win_length;
n_points    = (info.max_logMAR - info.min_logMAR)/0.1 + 1;
time_points = (0:(n_points+1))*info.win_length;

%% read descending sweep - look for activity "drop off"

lower = info.lower_threshold;
upper = info.upper_threshold;

dataTbl  = descendTbl;
t = dataTbl.t;
[r, q] = get_sweep_activity (dataTbl, info.win_length);
[k, i] = find_activity (r, q, 'drop-off', 'lower_threshold', lower, 'upper_threshold', upper);
ret_info.descending.VA = t2logMAR (t(k), -1, info);
ret_info.descending.t  = t(k); 
ret_info.descending.k  = k; 
ret_info.descending.activity = [ t r q ];


%% read ascending sweep - look for activity "pick up"

dataTbl  = ascendTbl;
t = dataTbl.t;
[r, q] = get_sweep_activity (dataTbl, info.win_length);
[k, i] = find_activity (r, q, 'pick-up', 'lower_threshold', lower, 'upper_threshold', upper);

ret_info.ascending.VA = VA (t(k), info.min_logMAR, +1, ratio)
ret_info.ascending.t  = t(k); 
ret_info.ascending.k  = k; 
ret_info.ascending.activity = [ t r q ];

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
ratio       = info.logmar_step/info.win_length;
n_points    = (info.max_logMAR - info.min_logMAR)/0.1 + 1;
time_points = (0:(n_points+1))*info.win_length;


%% analyze the tables 

% descendTbl  = readtable (f1);
% ascendTbl   = readtable (f2);

ret_info   = analyze_bidrectional_sweep (descendTbl, ascendTbl, info);

% determine mean VA 
fprintf ('final VA = %4.2f\n', ret_info.meanVA);

subplot (2,1,1); 
show_sweep ( descendTbl, ret_info.descending, info, -1)
sig = findobj(gca, 'Tag', 'dataline');
act = findobj(gca, 'Tag', 'activity');
legend ([sig act ], { 'signal', 'activity' });


subplot (2,1,2); 
show_sweep ( ascendTbl, ret_info.ascending, info, +1)

meanVA = sprintf('mean. VA = %4.2f logMAR', ret_info.meanVA);
strETDRS = sprintf('VA (ETDRS) = %4.2f logMAR', VA_ETDRS);
textbox ({ meanVA, strETDRS }, 'FontSize', info.FontSize, 'HorizontalAlignment', 'left');


%% ADDITIONAL INFORMATION 
% subplot (2,1,1);
% subplot (2,1,2);


end



function show_sweep ( dataTbl, ret_info, info, dirn)


%% general setup  

VA          = @(t, xstart, dirn, ratio) xstart+dirn*ratio*t;
ratio       = info.logmar_step/info.win_length;
n_points    = (info.max_logMAR - info.min_logMAR)/0.1 + 1;
time_points = (0:(n_points+1))*info.win_length;

profile.mean_shift  = true;
[y_info, H]         = show_signal (dataTbl, profile);
ylabel ('Normalized Displacement');
grid on;

xticks(time_points);
xlim([ min(time_points) max(time_points) ]);
ylim([ -0.1 0.3 ]);
set(gca, 'FontSize', info.FontSize);


k    = ret_info.k;
t_VA = ret_info.t;
VA   = ret_info.VA;


%% show a blob at point 

if (~isempty(k))

    scatter (t_VA,  y_info(k), 'sizeData', 100, 'MarkerFaceColor','k', 'MarkerEdgeColor','k');
    line ([ t_VA t_VA ], [ -1 1 ], 'LineWidth', 1.5, 'Color','k');
    h = text(t_VA, 0.25, sprintf(' VA_↓ = %4.2f logMAR', VA));
    set(h, 'FontSize', info.FontSize);
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
