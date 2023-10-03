function finalTbl = run_sweep_pupilcore_analysis  (sweep_dir)

% RUN_SWEEP_PUPILCORE_ANALYSIS 
%
% run_sweep_pupilcore_analysis  (sweep_dir)
%
% where 
%       sweep_dir is the sweep directory (invisible)   
%

if (nargin ==0)
    sweep_dir = './DATA/Aug2/cfra_02_08_2023_sweep_left';
end

%% Informational 

[~,basename] = fileparts (sweep_dir);
d.basename      = basename;
d.timeline_file = fullfile(sweep_dir, 'timeline.json');
d.protocol_file = fullfile(sweep_dir, 'protocol.json');
d.trials_dir    = fullfile(sweep_dir, 'trials/trial*');
d.outputVAfile  = fullfile(sweep_dir, 'trials', 'VA.csv');
d.consensusVAdir  = fullfile(sweep_dir, 'results');
d.sweepVAdir      = fullfile(sweep_dir, 'results');
d.figuresdir      = fullfile(sweep_dir, 'results', 'figures');
createdirectory (d.figuresdir);


createdirectory (d.sweepVAdir);
createdirectory (d.consensusVAdir);

d.sweepVAfile       = fullfile(d.sweepVAdir, 'sweepVA.csv');
d.sweepsummaryfile  = fullfile(d.sweepVAdir, 'summary.json');

protocol = easy_sweep_protocol (d.protocol_file);
trial_keys = protocol.sweep.keys();

trial_keys = natsort(trial_keys);
 

activity = [];


trials = dir (d.trials_dir);
trial_names = { trials.name };

for m = 1:length (trial_keys)

    each_trial_key = trial_keys{m};
    
    %% we have a valid trial 
    i = contains (trial_names, strcat(each_trial_key,'_'));

    if (~any(i))
        error ("trial wasnt found");
    end

    if (sum(i) > 1)
        error ("repeating trials");
    end

    %% information 
    this_sweep_info = protocol.sweep(each_trial_key).info;
    this_trial = trials (i);
    this_trial_name = trial_names(i);

    %% information 

    signalfile = fullfile(this_trial.folder, this_trial.name, "result", "signal.csv");
    jsonfile   = fullfile(this_trial.folder, this_trial.name, "result", "result.json");
    resultfile = fullfile(this_trial.folder, this_trial.name, "result", "result.csv");

    if (((exist(jsonfile) > 0) & (~(exist(resultfile) > 0))))
        str_cmd = sprintf('oknconvert -i "%s"', jsonfile);
        system (str_cmd);
    end

    sigTbl    = readtable (signalfile);
    resultTbl = readtable (resultfile);
    
    % this will detect both "onset" and "dropoff" VA from activity
    
    info = get_sweep_metrics (sigTbl, resultTbl);
   
    %% seperated activity 



    % if we can detect whether this is a downward sweep or upward 

    k = this_sweep_info.ratio;

    output(m).name           = this_trial_name;
    output(m).id             = m;    
    output(m).pair_id         = floor((m-1)/2)+1;    
    output(m).k              = k;
    output(m).found_activity = info.found_activity;
    output(m).signalfile     = signalfile;
    output(m).resultcsvfile  = resultfile;
    output(m).timelinefile   = string(d.timeline_file);
    

    %% separated activity 
    L = size(info.sp.separated_activity, 1);
    activity = [  activity ; output(m).pair_id*ones(L,1) output(m).id*ones(L,1)  output(m).k*ones(L,1) info.sp.separated_activity info.ep.chain_activity ];


    switch (sign(k))

        case { -1 }
                output(m).VA = this_sweep_info.max_logMAR + 0.1 + k*info.dropoff_t;
                output(m).t  = info.dropoff_t;
    
        case { +1 }
                
                output(m).VA = this_sweep_info.min_logMAR + k*info.onset_t;
                output(m).t  = info.onset_t;

        otherwise 
            error ('No signed ratio set');
    end

    %% need to save these VA to an output file 
    %fprintf ('k = %4.2f, VA = %4.2f\n', k, info.VA);
    %info
end

fprintf ('writing ... %s\n', d.outputVAfile);
outTbl = struct2table(output);
writetable(outTbl, d.outputVAfile); 

%% generate consensus paired ACTIVITY SIGNAL 

activity = array2table (activity, "VariableNames", { 'pair_id','id', 'dirn', 't1', 'sp1', 't2', 'ep1' } );
%writetable (activity, 'activity.csv');


consensus_info  = get_consensus_VA (activity, this_sweep_info);

simple.meanVA     = consensus_info.meanVA;
simple.dropoff_t  = consensus_info.down.t;
simple.dropoff_VA = consensus_info.down.VA;
simple.onset_t    = consensus_info.up.t;
simple.onset_VA   = consensus_info.up.VA;


file1 = fullfile(d.consensusVAdir, 'simple_consensus_VA.json');
file2 = fullfile(d.consensusVAdir, 'simple_consensus_mat.mat');
file3 = fullfile(d.consensusVAdir, 'activity.csv');

fprintf ('writing ... %s\n', file1);
fprintf ('writing ... %s\n', file2);
%fprintf ('writing ... %s\n', file3);
savejson ([], simple, file1);
save(file2, 'consensus_info');
writetable(activity, file3);


%% we can compute "paired VA" as well 

overall = groupsummary (outTbl, "pair_id", @(x) mean (x, 'omitnan'), { "VA" });
fprintf ('writing ... %s\n', d.sweepVAfile);
writetable(overall, d.sweepVAfile); 


figure (2); clf;  %% down-sweep 
f = gcf; f.Position = [ -27 60 800 1000 ];
figure (3); clf;  %% up-sweep
f = gcf; f.Position = [ -27 60 800 1000 ];

pair_ids = unique(overall.pair_id);
K = length (pair_ids);
for k = 1:K
        
    figure (1); clf;
    a = paired_sweep_visualizer (overall.pair_id(k), outTbl);

    axes(a(1));
    ylim([-0.025 0.025]);
    axes(a(2));
    ylim([-0.025 0.025]);

    %% save that as FIGURES 
    
    pair_id = overall.pair_id(k);    
    outputdir = fullfile(d.figuresdir);
    %createdirectory (outputdir);

    figfile = fullfile(outputdir, sprintf('fig_%s_%d.fig', d.basename, pair_id ));
    pngfile = fullfile(outputdir, sprintf('fig_%s_%d.png', d.basename, pair_id ));

    fprintf ('writing ... %s\n', figfile);
    fprintf ('writing ... %s\n', pngfile);

    savefig (figfile);
    exportgraphics (gcf,pngfile);

    figure (2);   %% down plot visualizer 
    h = subplot (K+1,1,k);        
    [y0, t0] = single_sweep_visualizer (overall.pair_id(k), -1, outTbl, consensus_info.raw);    
    hold on; 
    
    %subplot_down(k) = get(h,'position');

    %% show consensus information 
    t = consensus_info.down.t;

    if (~isempty(t))

        [t0, i] = unique(t0);
        y0 = y0(i);    
        y = interp1(t0,y0,t, 'nearest'); % returfind_nearest(t, []);
        h0 = line    ([ t t], [-10 10], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'k')

    end

    yyaxis right; ylim([-0.2 0.2]);
    yyaxis left;  ylim([-0.5 5]);
    box(gca,'on');
    set(gca,'LineWidth', 1.0);
    set(gca,'FontSize', 16);
    grid off;
    
    if (k > 1)
       
        yyaxis left;
        set(gca,'XTick',[], 'YTick', [])
        yyaxis right;
        set(gca,'XTick',[], 'YTick', [])
    end

    %show_label_VA (consensus_info.down.VA, -1);


    figure (3);    %% up plot visualizer  
    h = subplot (K+1,1,k);
   
    [y0, t0] = single_sweep_visualizer (overall.pair_id(k), +1, outTbl, consensus_info.raw);    
    hold on; 

    %% deal with repeated data
    [t0, i] = unique (t0);
    y0 = y0(i);


    %% show consensus information 
    hold on;
    t = consensus_info.up.t;    

    if (~isempty(t))

        y = interp1(t0,y0,t, 'nearest'); % returfind_nearest(t, []);
        scatter (t, y, 'SizeData', 10, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k')
        h0 = line    ([ t t], [-10 10], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'k')
    end

    yyaxis right;  ylim([-0.035 0.035 ]);
    yyaxis left;  ylim([-0.5 5]);
    box(gca,'on');
    set(gca,'LineWidth', 1.0);
    set(gca,'FontSize', 16);    
    grid off;

    if (k > 1)
       
        yyaxis left;
        set(gca,'XTick',[], 'YTick', [])
        yyaxis right;
        set(gca,'XTick',[], 'YTick', [])

    end
    
    % 
    % uistack (h0);

    %show_label_VA (consensus_info.up.VA, +1);


end

%% Fig 2 & 3 require the overall signal 

figure (2);  %% down 

subplot (K+1,1,1);
%title ('Descending sweep');

subplot (K+1,1,1); 
xlabel ('logMAR');

h = subplot (K+1,1,K+1);        
plot(consensus_info.down.time, consensus_info.down.activity, 'k-', 'LineWidth', 2);
ylim([-0.1 2]);
xlim([ 0 max(consensus_info.down.time)]);
grid on;
%title ('Total OKN activity');
xlabel ('Time (seconds)');
hold on;

%t = consensus_info.down.t;
%y = consensus_info.down.y;
%scatter (t, y, 'SizeData', 20, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k')

if (~isempty(t))
    line    ([ t t], [-2 2], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'k')
end

show_label_VA (consensus_info.down.VA, -1, "consensus ");

box(gca,'on');
set(gca,'LineWidth', 1.0);
grid off;
set(gca,'FontSize', 16);    

f = gcf; f.Position = [ -27 60 800 1000 ];



pngfile = fullfile(d.figuresdir, sprintf('fig_%s_descending.png', d.basename));
exportgraphics (gcf, pngfile);


figure (3);  %% up 

subplot (K+1,1,1);
%title ('Ascending sweep');

subplot (K+1,1,1); 
xlabel ('logMAR');

h = subplot (K+1,1,K+1);        
plot(consensus_info.up.time, consensus_info.up.activity, 'k-', 'LineWidth', 2);
ylim([-0.1 2]);
xlim([ 0 max(consensus_info.up.time)]);
grid on;
%title ('Total OKN activity');
xlabel ('Time (seconds)');


%% show consensus information 
hold on;
%t = consensus_info.up.t;
%y = consensus_info.up.y;
%scatter (t, y, 'SizeData', 20, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k')
if (~isempty(t))
    line    ([ t t], [-2 2], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'k')
end

show_label_VA (consensus_info.up.VA, +1, "consensus ");

box(gca,'on');
set(gca,'LineWidth', 1.0);
grid off;
set(gca,'FontSize', 16);    



pngfile = fullfile(d.figuresdir, sprintf('fig_%s_ascending.png', d.basename));
exportgraphics (gcf, pngfile);


%% sorted per ascending/descending as well 

p1 = (outTbl.k < 0);
p2 = (outTbl.k > 0);
summary.mean_descending_VA = mean (outTbl.VA(p1), 'omitnan');
summary.mean_ascending_VA  = mean (outTbl.VA(p2), 'omitnan');
summary.mean_mean_VA       = mean (overall.fun1_VA, 'omitnan');
summary.mean_all_VA        = mean (outTbl.VA, 'omitnan');

fprintf ('writing ... %s\n', d.sweepsummaryfile);
savejson([], summary, d.sweepsummaryfile); 

end

function show_label_VA (VA, dirn, extra_str, varargin)

p = inputParser ();
p.addOptional ("SuppressUnit", false);
p.parse(varargin{:});
res = p.Results;

if (nargin ==2)
    extra_str = '';
end


if  (res.SuppressUnit)
    str_unit = ''; 
else
    str_unit = ' logMAR';
end


if (dirn == -1)

    if (isfinite(VA))
        VA_string = strcat(extra_str, sprintf ('VA↓ = %4.2f', VA), str_unit); % OD.rightward.VA); 
    else
        VA_string = strcat(extra_str, 'VA↓ not found.'); % OD.rightward.VA);
    end
    
    a = gca;
    a1 = a.Position;
    k  = a1(4)/a1(3);
    a1(3) = 0.99*a1(3);
    a1(4) = 0.9*a1(4);    
    %a1(1) = a1(1)*1.05;
    %a1(2) = a1(2)*0.99;
    t = annotation('textbox','String',VA_string,'Position',a1,'Vert','top','HorizontalAlignment', 'right', 'FitBoxToText','on');    
    t.FontSize = 14;
    t.BackgroundColor = 'w';
    t.LineWidth = 1.5;

end


if (dirn == +1)
    
    if (isfinite(VA))
        VA_string = strcat(extra_str, sprintf ('VA↑ = %4.2f', VA), str_unit); % OD.rightward.VA); 
    else
        VA_string = strcat(extra_str, 'VA↑ not found.'); % OD.rightward.VA);
    end
    
    a = gca;
    a1 = a.Position;
    k  = a1(4)/a1(3);
    %a1(3) = 0.99*a1(3);
    %a1(4) = 0.95*a1(4);    
    a1(1) = a1(1)*1.05;
    a1(2) = a1(2)*0.99;
    
    t = annotation('textbox','String',VA_string,'Position',a1,'Vert','top','HorizontalAlignment', 'left', 'FitBoxToText','on');    
    t.FontSize = 14;
    t.BackgroundColor = 'w';

end


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


%% PRESENTATION SWEEP VISUALIZER 
%
%  presentation_bisweep_visualizer (thisTbl, d, eye_code, VAinfo, which_VA)
%
%  where 
%           thisTbl, 
%           d, 
%           eye_code, 
%           VAinfo, 
%           which_VA


function a = paired_sweep_visualizer (pair_id, thisTbl) % , eye_code, VAinfo, which_VA)
  

% figure; clf;

%% RIGHT DOWN SWEEP 

thisTbl = thisTbl(thisTbl.pair_id == pair_id, :);
%downTbl = thisTbl(i,:);
%downDir = sprintf ('result/okn/%s/%s/', downTbl.clip_direction{1}, downTbl.type{1});
%d.descending.dir = fullfile(d.main_dir, eye_code, downDir);
%okn_string = sprintf ('%s.%s', downTbl.eye{1}, downTbl.okn_direction{1});
%okn_sweep_direction = downTbl.sweep_direction{1};

iDown = (thisTbl.k<0);
downRow         = thisTbl(iDown,:);
sigfile         = downRow.signalfile;
resfile         = downRow.resultcsvfile;
timelinefile    = downRow.timelinefile;
dirn            = sign(downRow.k);
timeline        = loadjson (timelinefile);

VA = downRow.VA;
t  = downRow.t;
VA_down = VA;

a(1) = subplot (2,1,1);

% show_invisible_signal_data  (sigfile, "down", "showTimePoint", t); 

short_name = extractBefore(downRow.name{1},"_");
show_pupilcore_sweep_data  (sigfile, short_name, timeline, dirn, "showTimePoint", t); 
ylabel ('Displacement');   ylim([-0.1 0.25]);
set(gca,'FontSize',22);

if (isfinite(VA))
    VA_string = sprintf ('VA↓ = %4.2f logMAR', VA); % OD.rightward.VA);
else
    VA_string = 'VA↓ not found.'; % OD.rightward.VA);
end


a1 = a(1).Position;
k  = a1(4)/a1(3);
a1(3) = 0.99*a1(3);
a1(4) = 0.95*a1(4);

t = annotation('textbox','String',VA_string,'Position',a1,'Vert','top','HorizontalAlignment', 'right','FitBoxToText','on');

t.FontSize = 22;
t.BackgroundColor = 'w';

%% add labels 

xlabel('');


%% RIGHT UP SWEEP 


iUp = (thisTbl.k>0);
upRow = thisTbl(iUp,:);
sigfile = upRow.signalfile;
resfile = upRow.resultcsvfile;
dirn    = sign(upRow.k);
VA = upRow.VA;
t  = upRow.t;
VA_up = VA;


a(2) = subplot (2,1,2);

short_name = extractBefore(upRow.name{1},"_");
show_pupilcore_sweep_data  (sigfile, short_name, timeline, dirn, "showTimePoint", t); 
set(gca,'FontSize',22); ylim([-0.1 0.25]);


if (isfinite(VA))
    VA_string = sprintf ('VA↑ = %4.2f logMAR', VA); % OD.rightward.VA);
else
    VA_string = 'VA↑ not found.'; % OD.rightward.VA);
end


a1 = a(2).Position;
k  = a1(4)/a1(3);
a1(3) = 0.99*a1(3);
a1(4) = 0.95*a1(4);

t = annotation('textbox','String',VA_string,'Position',a1,'Vert','top','HorizontalAlignment', 'right', 'FitBoxToText','on');

t.FontSize = 22;
t.BackgroundColor = 'w';

VA_mean = (VA_down + VA_up)/2;
if (VA_mean)

    %% back into the first SWEEP 
    VA_string = sprintf ('mean VA = %4.2f logMAR', VA_mean);

else

    VA_string = 'Couldnt get mean VA'; % sprintf ('mean VA = %4.2f logMAR', VA_mean);
end

axes (a(1));

a1 = a(1).Position;
k  = a1(4)/a1(3);
a1(1) = 1.05*a1(1);
a1(2) = 0.975*a1(2);

t = annotation('textbox','String',VA_string,'Position',a1,'Vert','top','HorizontalAlignment', 'left','FitBoxToText','on');
t.FontSize = 22;
t.BackgroundColor = 'w';


%title (sprintf('%s [%s]',eye_code, which_VA), 'Interpreter', 'none');

f = gcf;
f.Position =  [ 4         562        1400         500 ];

%% PRINT THE RESULTS 

%outputdir = fullfile(d.sweepfigurespath, which_VA);
%createdirectory (outputdir);
%savefig (fullfile(outputdir, 'sweep.fig'));
%exportgraphics (gcf,fullfile(outputdir, 'sweep.png'));

end



%% SINGLE SWEEP VISUALIZER 
%
%  single_sweep_visualizer (thisTbl, d, eye_code, VAinfo, which_VA)
%
%  where 
%           thisTbl, 
%           d, 
%           eye_code, 
%           VAinfo, 
%           which_VA


function [y0, t0] = single_sweep_visualizer (pair_id, sweep_dirn, thisTbl, rawTbl) % , eye_code, VAinfo, which_VA)
  

%% SWEEP INFORMATION 

thisTbl = thisTbl(thisTbl.pair_id == pair_id, :);

iSweepDirn      = (sign(thisTbl.k) == sweep_dirn);
sweepRow        = thisTbl(iSweepDirn,:);
sigfile         = sweepRow.signalfile;
resfile         = sweepRow.resultcsvfile;
timelinefile    = sweepRow.timelinefile;
dirn            = sign(sweepRow.k);
timeline        = loadjson (timelinefile);
VA              = sweepRow.VA;
t               = sweepRow.t;

yyaxis right;
a = gca; 
short_name = extractBefore(sweepRow.name{1},"_");
[y0, t0] = show_pupilcore_sweep_data  (sigfile, short_name, timeline, dirn, "showTimePoint", t, "Color", [ 0 0 0 0.4 ]); 
show_label_VA (VA, dirn, "", "SuppressUnit", true);
hold on;


%% show the activity signal 

yyaxis left;
ax = gca;
ax.YAxis(1).Color = 'k';
ax.YAxis(2).Color = 'k';

rawTbl = rawTbl(rawTbl.pair_id == pair_id, :);
i      = (sign(rawTbl.dirn) == sweep_dirn);
rawTbl = rawTbl(i,:);
plot (rawTbl.t, rawTbl.activity, 'Color', [ 0 0 0 0.2 ], 'LineWidth', 2);
ylim ([-0.1 2])

end


%{

% ylabel ('Displacement');   
ylim([-0.1 0.25]);
set(gca,'FontSize',22);

if (dirn < 0)
    if (isfinite(VA))
        VA_string = sprintf ('VA=%4.2f', VA); 
    end
else
   if (isfinite(VA))
        VA_string = sprintf ('VA=%4.2f', VA); 
   end
end
axes(a);
[nx,ny] = coord2norm (gca, t, y);
annotation('textbox', [nx, ny, 0.5, 0.5],'String',VA_string,'FitBoxToText','on');

%}

