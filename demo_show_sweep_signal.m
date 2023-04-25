function demo_show_sweep_signal


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% OLDER 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{ 
%% Jason
t1 = 'trials';
g1 = './DATA/6Feb2023/jtur_06_02_23_sweep_okn_test_3/';

%% Andrew
t1 = 'trials';
g1 = fullfile('./DATA/8Feb2023/Andrew_sweep1/', t1);

%% Jichao
t1 = 'trials';
g1 = fullfile('./DATA/9Feb2023/jcha_09_02_2023_sweep/', t1);

%}

%{
%% Rebecca
t1 = 'retrial002';
g1 = fullfile('./DATA/9Feb2023/rfin_09_02_2023_sweep_power_2_5', t1);
VA_ETDRS = 0.71;
figure(3); clf;
show_directional_sweep (g1, VA_ETDRS);
%}


%% Jason
%{

t1 = 'trials';
g1 = fullfile('./DATA/24Feb2023/jtur_24_02_23_sweep_ipad', t1);
VA_ETDRS = 0.95;

info.max_logMAR  = 1.0;
info.min_logMAR  = -0.2;
info.logmar_step = 0.1;
info.win_length  = 2;
info.ratio       = 0.1/2;

figure(3); clf;
show_directional_sweep (g1, VA_ETDRS, info);

%}


%% Mohammad
t1 = 'trials';
g1 = fullfile('./DATA/24Feb2023/mnor_24_02_23_sweep_ipad', t1);
VA_ETDRS = 0.46;

info.max_logMAR  = 1.0;
info.min_logMAR  = 0.2;
info.logmar_step = 0.1;
info.win_length  = 2;
info.ratio       = 0.1/2;

figure(3); clf;
show_directional_sweep (g1, VA_ETDRS, info);


%% Rebecca
%g1 ='./DATA/9Feb2023/rfin_09_02_2023_sweep_power_2_5/';
%g1 ='./DATA/9Feb2023/rfin_09_02_2023_sweep_no_len';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% UPDATED 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{

t1 = 'trials';

%% Zaw
g1 ='./DATA/10Feb2023/zlin_10_02_23_sweep_ratio2_0_two';
VA_ETDRS = 0.48;

figure(1); clf;
show_directional_sweep (g1, VA_ETDRS);
title ('zlin');

%} 

%{

%% Jason (OK sweep)
g1 = './DATA/12Feb2023/jtur_12_02_2023_sweep';
VA_ETDRS = 0.95;
figure(1); clf;
show_directional_sweep (g1, VA_ETDRS);
title ('jtur');

%% Jason (OK sweep)
g1 = './DATA/10Feb2023/jtur_10_02_2023_sweep';
VA_ETDRS = 0.95;
figure(2); clf;
show_directional_sweep (g1, VA_ETDRS);
title ('jtur');

%% Jason (OK sweep)
g1 = './DATA/10Feb2023/jtur_10_02_2023_sweep_ratio_2_0_two';
VA_ETDRS = 0.95;
figure(2); clf;
show_directional_sweep (g1, VA_ETDRS);
title ('jtur');

%% Jannes
g1 = './DATA/10Feb2023/jbru_10_02_2023_sweep_power_1_0';
VA_ETDRS = 0.42;
figure(3); clf;
show_directional_sweep (g1, VA_ETDRS);
title ('jbru');


%% Sherie (glasses)
g1 = './DATA/10Feb2023/szha_10_02_2023_sweep_power_minus_1_5';
VA_ETDRS = 0.66;
figure(4); clf;
show_directional_sweep (g1, VA_ETDRS);
title ('szha (induced)');

%% Sherie (no glasses)
g1 = './DATA/10Feb2023/szha_10_02_2023_sweep_no_len_two';
VA_ETDRS = 1.12;
figure(4); clf;
show_directional_sweep (g1, VA_ETDRS);
title ('szha (unaided)');

%% Kate 
g1 = './DATA/10Feb2023/knga_10_02_2023_sweep_power_1_0';
VA_ETDRS = 0.54;
figure(5); clf;
show_directional_sweep (g1, VA_ETDRS);
title ('knga');

%}


end 


function show_directional_sweep (g1, VA_ETDRS, info)

if (nargin ==2)
    limits = [ -0.2 1.0 ]
end


fs = 18; % font size


%% get file-names 

f1 = fullfile(g1, 'trial-2_disk-condition-1-1/result/signal.csv');
f2 = fullfile(g1, 'trial-4_disk-condition-13-1/result/signal.csv');
if (~exist (f2))
    f2 = fullfile(g1, 'trial-4_disk-condition-9-1/result/signal.csv');
end

%% general setup  

VA          = @(t, xstart, dirn, ratio) xstart+dirn*ratio*t;
ratio       = info.logmar_step/info.win_length;
n_points    = (info.max_logMAR - info.min_logMAR)/0.1 + 1;
time_points = (0:(n_points+1))*info.win_length;


%% SHOW THE DESCENDING SWEEP 

subplot (2,1,1);

dataTbl             = readtable (f1);
profile.mean_shift  = true;
[y_info, H]         = show_signal (dataTbl, profile);
ylabel ('Normalized Displacement');
grid on;

xticks(time_points);
xlim([ min(time_points) max(time_points) ]);
ylim([ -0.1 0.3 ]);
set(gca, 'FontSize', fs);

%% determine the drop-off activity point

t = dataTbl.t;
[r, q] = get_sweep_activity (dataTbl, info.win_length);
[k, i, e] = find_activity (r, q, 'drop-off');

scatter (t(k),  y_info(k), 'sizeData', 100, 'MarkerFaceColor','k', 'MarkerEdgeColor','k');
VA_descending = t2logMAR (t(k), -1, info);
VA_descending_in_time = t(k);

line ([ t(k) t(k) ], [ -1 1 ], 'LineWidth', 1.5, 'Color','k');
h = text(t(k), 0.25, sprintf(' VA_↓ = %4.2f logMAR', VA_descending));
set(h, 'FontSize', fs);

fprintf ('VA (descending) = %4.2f\n', VA_descending);
xaxis2logMAR (-1, info);


%% show the signal acitivity 

yyaxis right;
plot(t,r, 'k--');
ylim([-1 2]);
ylabel ('Activity');
set(gca, 'YColor', 'k');


%% SHOW THE ASCENDING SWEEP 


subplot (2,1,2);
dataTbl = readtable (f2);
profile.mean_shift = true;

x= dataTbl.x - mean(dataTbl.x, 'omitnan');
y_info = show_signal (dataTbl, profile);
grid on;

xlabel ('logMAR');
ylabel ('Normalized Displacement');
xticks(time_points);
xlim([ min(time_points) max(time_points) ]);
ylim([ -0.1 0.3 ]);

% set the Font 

set(gca, 'FontSize', fs);

t = dataTbl.t;
[r, q] = get_sweep_activity (dataTbl, info.win_length);

[k, i] = find_activity (r, q, 'pick-up');
scatter (t(k),  y_info(k), 'sizeData', 100, 'MarkerFaceColor','k', 'MarkerEdgeColor','k');
VA_ascending = VA (t(k), info.min_logMAR, +1, ratio);
VA_ascending_in_time = t(k);


line ([ t(k) t(k) ], [ -1 1 ], 'LineStyle', '-', 'LineWidth', 1.5, 'Color','k');
h = text(t(k), 0.25, sprintf(' VA_↑  = %4.2f logMAR', VA_ascending), 'HorizontalAlignment','left');
set(h, 'FontSize', fs);

fprintf ('VA (ascending) = %4.2f\n', VA_ascending);
xaxis2logMAR (+1, info);


%% show the signal activity 

VA_asc_in_1 = logMAR2t (VA_ascending, -1, info);
VA_des_in_2 = logMAR2t (VA_descending, +1, info);

yyaxis right;
g(2) = plot(t,r, 'k--');
ylim([-1 2]);
ylabel ('Activity');
set(gca, 'YColor', 'k');

%set(yaxis,'Color','k');


%% ADDITIONAL INFORMATION 


% determine mean VA 
VA_final = (VA_ascending + VA_descending)/2;
fprintf ('final VA = %4.2f\n', VA_final);
meanVA = sprintf('mean. VA = %4.2f logMAR', VA_final);
strETDRS = sprintf('VA (ETDRS) = %4.2f logMAR', VA_ETDRS);

subplot (2,1,1);
%textbox ({ meanVA, strETDRS }, 'FontSize', fs, 'HorizontalAlignment', 'right');

legend ([H(1) g(2) ], { 'signal', 'activity' });

subplot (2,1,2);
textbox ({ meanVA, strETDRS }, 'FontSize', fs, 'HorizontalAlignment', 'left');



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
