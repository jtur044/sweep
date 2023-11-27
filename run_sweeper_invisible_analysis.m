function finalTbl = run_sweeper_invisible_analysis  (sweep_dir)

% RUN_SWEEP_INVISIBLE_ANALYSIS 
%
% run_sweep_invisible_analysis  (sweep_dir)
%
% where 
%       sweep_dir is the sweep directory (invisible)   
%

if (nargin ==0)
    sweep_dir = './DATA/Aug2/cfra_02_08_2023_sweep_left';
end

%% Informational 

[~,basename]        = fileparts (sweep_dir);
d.basename          = basename;
d.timeline_file     = fullfile(sweep_dir, 'timeline.json');
d.events_file       = fullfile(sweep_dir, 'events.json');
d.protocol_file     = fullfile(sweep_dir, 'protocol.json');
d.trials_dir        = fullfile(sweep_dir, 'trials/trial*');
d.outputVAfile      = fullfile(sweep_dir, 'trials', 'VA.csv');
d.consensusVAdir    = fullfile(sweep_dir, 'results');
d.sweepVAdir        = fullfile(sweep_dir, 'results');
d.figuresdir        = fullfile(sweep_dir, 'results', 'figures');
createdirectory (d.figuresdir);


createdirectory (d.sweepVAdir);
createdirectory (d.consensusVAdir);

d.sweepVAfile       = fullfile(d.sweepVAdir, 'sweepVA.csv');
d.sweepsummaryfile  = fullfile(d.sweepVAdir, 'summary.json');

protocol            = easy_sweeper_protocol (d.protocol_file);
sweep_parms         = protocol.sweep_set.x0x5F_parameters;

if (~exist(d.events_file,'file'))
    strf = sprintf('oknevents -i "%s/gaze.csv" > %s', sweep_dir, d.events_file);
    system(strf);
    events              = load_commented_json (d.events_file);
else
    events              = load_commented_json (d.events_file);
end

%% Generate a "trials" object (contains information for each sweep)

trials = containers.Map ();
count = 1;
for q = 1:length(protocol.timeline)
    each = protocol.timeline{q};
    if (strcmpi(each.type,'sweeper_disks'))

        sweep_steps = protocol.sweep_set.(each.which);
        event_type = { sweep_steps.sweep.event_type };
        i = ismember (event_type, 'sweep');

        first = sweep_steps.sweep(1);
        last  = sweep_steps.sweep(end);

        this_trial.key               = sprintf('%s_%s', each.id, each.which);        
        this_trial.id                = each.id;
        this_trial.which             = each.which;
        this_trial.step_duration     = (protocol.sweep_set.step_duration.sweep/1000); % in seconds       
        this_trial.steps             = sum(i);
        this_trial.logMAR            = sweep_parms.logMAR; 
        this_trial.ratio             = (last.logMAR - first.logMAR)/(this_trial.step_duration*(this_trial.steps-1));  
        this_trial.sweep_direction   = sign (last.logMAR - first.logMAR);        
        this_trial.direction         = sweep_steps.x0x5F_parameters.direction;
        
        %% add all events (entry, sweep, exit) 
        

        %% add sweeper events 
        [sweep_event, sub_events]    = find_sweeper_in_events(events, this_trial.id);  
        this_trial.sweep_event       = sweep_event;                                     % main sweeper 
        this_trial.sub_events        = sub_events;                                      % all events
        this_trial.start_event       = find_first_event(sub_events, "sweep");           % first sweep event
        this_trial.end_event         = find_first_event(sub_events, "exit");           % first sweep event
                
        %% SENSOR time-stamp based START & END times
        this_trial.start_time        = this_trial.start_event.sensor_timestamp - this_trial.sweep_event.start.sensor_timestamp; 
        this_trial.end_time          = this_trial.end_event.sensor_timestamp - this_trial.sweep_event.start.sensor_timestamp; 


        trials(this_trial.key) = this_trial;        
        count = count + 1;
    end
end

% trial_keys = natsort(trial_keys);


%% additional SWEEP information 
% p = protocol.sweep_set;
% this_sweep_info.step_duration = p.step_duration.sweep; 
% this_sweep_info.logMAR        = p.x0x5F_parameters.logMAR; 


activity = [];

%% read names in trials directory 
trials_list = dir (d.trials_dir);
[~,n] = natsort({ trials_list.name });
trials_list = trials_list(n);

trial_names = { trials_list.name };
trial_keys  = trials.keys();
trial_keys = natsort (trial_keys);

%textprogressbar ('running : ');

M = length (trial_keys);

isfirst = true;

for m = 1:M     %% cycle through keys

    %textprogressbar (m/M*100);
    
    %% cross-check with the current "trial_key" 
    each_trial_key = trial_keys{m};    
    i = contains (trial_names, each_trial_key);
    if (~any(i))
        error ("trial wasnt found");
    end
    if (sum(i) > 1)
        error ("repeating trials");
    end


    %% located information ... so get it!
    this_trial      = trials_list (i); % from directory
    this_trial_name = this_trial.name;
    signalfile = fullfile(this_trial.folder, this_trial.name, "result", "signal.csv");
    jsonfile   = fullfile(this_trial.folder, this_trial.name, "result", "result.json");
    resultfile = fullfile(this_trial.folder, this_trial.name, "result", "result.csv");
    if (((exist(jsonfile) > 0) & (~(exist(resultfile) > 0))))
        str_cmd = sprintf('oknconvert -i "%s"', jsonfile);
        system (str_cmd);
    end
    sigTbl    = readtable (signalfile);
    resultTbl = readtable (resultfile);



    %% analyze the data  
    %
    % note: this will read the SIGNALFILE and therefore the timebase 
    % is signal file based.
    %


    %% ADDITIONAL INFORMATION ADDED IN HERE 

    info = get_sweep_metrics (sigTbl, resultTbl); 

    output(m).name           = this_trial_name;
    output(m).id             = m;    
    output(m).pair_id        = floor((m-1)/2)+1;    
    output(m).k              = trials(each_trial_key).ratio;  %% signed sweep direction
    output(m).found_activity = info.found_activity;
    output(m).signalfile     = signalfile;
    output(m).resultcsvfile  = resultfile;
    output(m).timelinefile   = string(d.timeline_file);
    output(m).eventsfile     = string(d.events_file);
    

    %% add the start time 
    this_sweep_trial     = trials(each_trial_key);
    
    %% use the first trial as the consensus trial 
    if (isfirst)
        consensus_sweeper = this_sweep_trial;
        isfirst = false;
    end

    %% start-time and end-time are calculated based on sensor_timestamp 
        
    output(m).trial      = this_sweep_trial;
    start_time           = this_sweep_trial.start_time;
    output(m).start_time = start_time;                  %% start-time using sensor_timestamp 
    end_time             = this_sweep_trial.end_time;
    output(m).end_time = end_time;                    %% end-time using sensor_timestamp 

    % entry_event_record_timestamp = get_record_timestamp (sigTbl, this_sweep_trial.start_event.sensor_timestamp);
    % sweep_event_record_timestamp = get_record_timestamp (sigTbl, this_sweep_trial.sweep_event.start.sensor_timestamp);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % PER sweep-VA
    %
    % Note that info is determined from SIGNALFILE time  
    % 
    % (start_time, end_time) are offsets into the SIGNALFILE  
    %
    %  VA will be bounded by (start_time, end_time) offsets 
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    bounded_VA          = get_bounded_VA (this_sweep_trial, info, start_time, end_time);
    output(m).VA        = bounded_VA.VA;
    output(m).t         = bounded_VA.t;    
    output(m).bounded   = bounded_VA.bounded;


    %% activity matrix for CONSENSUS method  
    %
    %   pair_id is the name of the PAIR 
    %   id      is the indiivudal name of the SWEEP 
    %
    
    L = size(info.sp.separated_activity, 1);
    activity = [  activity ; output(m).pair_id*ones(L,1) output(m).id*ones(L,1)  output(m).k*ones(L,1) info.sp.separated_activity info.ep.chain_activity ];
    
    % analyze the activity 
    output(m).activity.sp = info.sp.separated_activity;
    output(m).activity.ep = info.ep.chain_activity;




    % csHeader = [ output(m).pair_id output(m).id  output(m).k ];
    % csDecider.add (csHeader, info.sp.separated_activity | info.ep.chain_activity)



    %% save these VA to an output file 
    fprintf ('"%s" k = %4.2f, t=%4.2f, st = %4.2f, VA = %4.2f\n', each_trial_key, output(m).k, output(m).t,  start_time, output(m).VA);
    
end

%textprogressbar ('done.');


fprintf ('writing ... %s\n', d.outputVAfile);
outTbl = struct2table(output);
writetable(outTbl, d.outputVAfile); 

%% convert to a TABLE for ACTIVITY SIGNAL 
%  put into old format to call get_consensus_VA
%
% just requires some genral information 
%
%   logMAR.max, logMAR.min, logMAR.step
%

%% calculating CONSENSUS VA
%
% Note that times t are in SIGNALFILE times  
% VA are relative to start_time i.e., sensor_timestamp 
%
% VA are also bounded 
%

fprintf ('Calculating CONSENSUS VA.\n');

va_info.logMAR.max = 1.0;
va_info.logMAR.min = 0.0;
va_info.ratio      = 0.05;

% activity = array2table (activity, "VariableNames", { 'pair_id','id', 'dirn', 't1', 'sp1', 't2', 'ep1' } );
% consensus_info    = get_consensus_VA (activity, va_info);

%% consensus entire input 
consensus_info    = get_output_consensus_VA (output, va_info);
simple.meanVA     = consensus_info.meanVA;
simple.dropoff_t  = consensus_info.dwn.t;   
simple.dropoff_VA = consensus_info.dwn.VA;
simple.onset_t    = consensus_info.up.t;
simple.onset_VA   = consensus_info.up.VA;

file1 = fullfile(d.consensusVAdir, 'simple_consensus_VA.json');
file2 = fullfile(d.consensusVAdir, 'simple_consensus_mat.mat');
%file3 = fullfile(d.consensusVAdir, 'activity.csv');

fprintf ('writing ... %s\n', file1);
fprintf ('writing ... %s\n', file2);
%fprintf ('writing ... %s\n', file3);
savejson ([], simple, file1);
save(file2, 'consensus_info');
%writetable(activity, file3);


%% we can compute "paired VA" as well 

overall = groupsummary (outTbl, "pair_id", @(x) mean (x, 'omitnan'), { "VA" });
fprintf ('writing ... %s\n', d.sweepVAfile);
writetable(overall, d.sweepVAfile); 




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% VISUALIZER 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure (2); clf;  %% down-sweep 
f = gcf; f.Position = [ -27 60 800 1000 ];
figure (3); clf;  %% up-sweep
f = gcf; f.Position = [ -27 60 800 1000 ];

pair_ids = unique(overall.pair_id);
K = length (pair_ids);
for k = 1:K
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% VISUALIZE PAIRS 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%{
    figure (1); clf;
    paired_sweeper_visualizer (overall.pair_id(k), outTbl, trials);

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
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% VISUALIZE ONLY DOWN 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    figure (2);   %% down plot visualizer 
    a_down(k) = subplot (K+1,1,k);    

    %a1 = a.Position;
    %ratio  = a1(4)/a1(3);
    %a1(3) = 0.99*a1(3);
    %a1(4) = 0.95*a1(4); 

    xlim_down(k,1:2) = single_sweeper_visualizer (a_down(k), overall.pair_id(k), -1, outTbl, trials);    
    hold on; 
    
    %subplot_down(k) = get(h,'position');

    %% show consensus information 
    %t = consensus_info.down.t;
    %
    %if (~isempty(t))
    %
    %        [t0, i] = unique(t0);
    %    y0 = y0(i);    
    %    y = interp1(t0,y0,t, 'nearest'); % returfind_nearest(t, []);
    %    h0 = line    ([ t t], [-10 10], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'k')
    %
    %    end
    %
    %% set axes 
    %yyaxis right; ylim([-0.2 0.2]);
    %yyaxis left;  %ylim([-0.5 5]);
    
    box(gca,'on');
    set(gca,'LineWidth', 1.0);
    set(gca,'FontSize', 16);
    grid off;
        
    %% empty aces 
    if (k > 1)       
        yyaxis left;
        set(gca,'XTick',[], 'YTick', []);
        ylabel('');
        yyaxis right;
        set(gca,'XTick',[], 'YTick', [])
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% VISUALIZE ONLY UP 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    figure (3);    %% up plot visualizer  
    a_up(k) = subplot (K+1,1,k);


    %a1 = a.Position;
    %ratio  = a1(4)/a1(3);
    %a1(3) = 0.99*a1(3);
    %a1(4) = 0.95*a1(4); 
    
    xlim_up(k,1:2) = single_sweeper_visualizer (a_up(k), overall.pair_id(k), +1, outTbl, trials);    
    hold on; 

    % single_sweeper_visualizer (a, overall.pair_id(k), +1, outTbl, consensus_info.raw);    
    % hold on; 

    %%% deal with repeated data
    %[t0, i] = unique (t0);
    %y0 = y0(i);
    %
    %
    % %% show consensus information 
    % hold on;
    % t = consensus_info.up.t;    
    %
    % if (~isempty(t))
    %
    %    y = interp1(t0,y0,t, 'nearest'); % returfind_nearest(t, []);
    %    scatter (t, y, 'SizeData', 10, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k')
    %    h0 = line    ([ t t], [-10 10], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'k')
    % end
    %
    %% set axes 
    %yyaxis right;  ylim([-0.2 0.2]);
    %yyaxis left;  %ylim([-0.5 5]);
    
    box(gca,'on');
    set(gca,'LineWidth', 1.0);
    set(gca,'FontSize', 16);    
    grid off;

    %% empty out axes 
    if (k > 1)       
        yyaxis left;
        set(gca,'XTick',[], 'YTick', []);
        ylabel('');
        yyaxis right;
        set(gca,'XTick',[], 'YTick', []);
    end
    
    % 
    % uistack (h0);

    %show_label_VA (consensus_info.up.VA, +1);


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CONSENSUS 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FIG 2 - ADD ADDITIONAL TO DOWN ONLY GRAPHS 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure (2);  %% down 

%% Label the TOP line 
subplot (K+1,1,1); 
xlabel ('VA (logMAR)');

%% Add CONSENSUS graph
h = subplot (K+1,1,K+1);        
xlim_data = show_sweeper_events (consensus_sweeper);
show_consensus (h, 'consensus VA↓', consensus_info.dwn);

%% SET X-LIMITS
xl = min(xlim_down);
xlim([ a_down h ],xl);
set(a_down,'FontSize', 16);    


f = gcf; f.Position = [ -27 60 800 1000 ];


figfile = fullfile(d.figuresdir, sprintf('fig_%s_descending.fig', d.basename));
savefig(figfile);
pngfile = fullfile(d.figuresdir, sprintf('fig_%s_descending.png', d.basename));
exportgraphics (gcf, pngfile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FIG 3 - ADD ADDITIONAL TO UP ONLY GRAPHS 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure (3);  %% up 

subplot (K+1,1,1);
%title ('Ascending sweep');

subplot (K+1,1,1); 
xlabel ('VA (logMAR)');

h = subplot (K+1,1,K+1);  
xlim_data = show_sweeper_events (consensus_sweeper);
show_consensus (h, 'consensus VA↑', consensus_info.up);

%% show consensus information 
%hold on;
%t = consensus_info.up.t;
%y = consensus_info.up.y;
%scatter (t, y, 'SizeData', 20, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k')

%if (~isempty(t))
%    line    ([ t t], [-2 2], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'k')
%end
%
%show_label_VA (consensus_info.up.VA, +1, "consensus ");



%% SET X-LIMITS
xl = min(xlim_up);
xlim([ a_up h ],xl);
set(a_up,'FontSize', 16);    

%box(gca,'on');
%set(gca,'LineWidth', 1.0);
grid off;
set(gca,'FontSize', 16);    

f = gcf; f.Position = [ -27 60 800 1000 ];

figfile = fullfile(d.figuresdir, sprintf('fig_%s_ascending.fig', d.basename));
savefig(figfile);
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


function paired_sweeper_visualizer (pair_id, thisTbl, trials) % , eye_code, VAinfo, which_VA)
  

% figure; clf;

%% RIGHT DOWN SWEEP 

thisTbl = thisTbl(thisTbl.pair_id == pair_id, :);
% sigfile         = downRow.signalfile;
% resfile         = downRow.resultcsvfile;
% eventsfile      = downRow.eventsfile;
% dirn            = sign(downRow.k);
% events          = loadjson (eventsfile);

%% stardard text VA options 
opts = { 'FontSize',22, 'HorizontalAlignment', 'right' };


%% SHOW DOWNSWEEP
iDown = (thisTbl.k<0);
downRow         = thisTbl(iDown,:);
a(1) = subplot (2,1,1);
down_sweeper = trials(downRow.name{1});
xlim_data_down = show_sweeper (a(1), down_sweeper, downRow, opts{:});

%% SHOW UPSWEEP
iUp = (thisTbl.k>0);
upRow = thisTbl(iUp,:);
a(2) = subplot (2,1,2);
up_sweeper = trials(upRow.name{1});
xlim_data_up = show_sweeper (a(2), up_sweeper, upRow, opts{:});
ylabel('');


%% SHOW VA
VA_mean = (downRow.VA + upRow.VA)/2;
axes(a(1));
a1 = a(1).Position;
show_VA_label(a1, 'mean VA', VA_mean, 'FontSize',22, 'HorizontalAlignment', 'left');


%% SET X-LIMITS
xl = min([ xlim_data_down ; xlim_data_up ]);
axes(a(1));
xlim(xl);
axes(a(2));
xlim(xl);


%% Default positioning of the graph

f = gcf;
f.Position =  [ 4         562        1400         500 ];

end



%% SHOW CONSENSUS 

function show_consensus (a, strp, consensus_info)

    t = consensus_info.activity(:,1);
    y = consensus_info.activity(:,2);    
    plot(t, y, 'k-', 'LineWidth', 2);
    ylim([-0.1 2]);
    
    % xlim([ 0 max(tconsensus_info.time)]);
    grid on;
    %title ('Total OKN activity');
    xlabel ('Time (seconds)');
    hold on;
    box(gca,'on');
    set(gca,'LineWidth', 1.0);
    grid on;
    ylabel('Consensus');


    %% stardard text VA options 
    opts = { 'FontSize',16, 'HorizontalAlignment', 'right' };

    a1 = a(1).Position;
    show_VA_label(a1, strp, consensus_info.VA, opts{:});

    t0 = consensus_info.t;
    line ([t0 t0], [-10 10], 'LineStyle', '--', 'Color', 'red');
    
    hold on;
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


function xlim_data = single_sweeper_visualizer (a, pair_id, sweep_dirn, thisTbl, trials)  % , eye_code, VAinfo, which_VA)


%% SWEEP INFORMATION 

thisTbl = thisTbl(thisTbl.pair_id == pair_id, :);
iSweepDirn      = (sign(thisTbl.k) == sweep_dirn);
sweepRow        = thisTbl(iSweepDirn,:);

opts = { 'FontSize',16, 'HorizontalAlignment', 'right' };
sweeper = trials(sweepRow.name{1});
xlim_data = show_sweeper (a, sweeper, sweepRow, opts{:});

%% show the activity signal 

yyaxis right;

t  = sweepRow.activity.sp(:,1);
sp = sweepRow.activity.sp(:,2);
ep = sweepRow.activity.ep(:,2);
plot (t, sp|ep);
ylim([-0.1 4.0]);


% ax = gca;
% ax.YAxis(1).Color = 'k';
% ax.YAxis(2).Color = 'k';
%
% rawTbl = rawTbl(rawTbl.pair_id == pair_id, :);
% i      = (sign(rawTbl.dirn) == sweep_dirn);
% rawTbl = rawTbl(i,:);
% plot (rawTbl.t, rawTbl.activity, 'Color', [ 0 0 0 0.2 ], 'LineWidth', 2);
% ylim ([-0.1 2])

end


%% SHOW_SWEEPER


function xlim_data = show_sweeper (a, sweeper, row, varargin) % , eye_code, VAinfo, which_VA)
  

    %% get anlaysis information  
    VA      = row.VA;
    t       = row.t;
    sigfile = row.signalfile;

    
    %% show data 
    show_invisible_sweeper_data  (sigfile, "showTimePoint", t); 
    xlim_data = show_sweeper_events (sweeper);
    show_sweeper_logmar_ticks (sweeper);

    ylabel ('Displacement');   ylim([-0.1 0.25]);
    set(gca,'FontSize',22);

    %% positioning for right-hand side VA 
    a1 = a.Position;
    k  = a1(4)/a1(3);
    a1(3) = 0.99*a1(3);
    a1(4) = 0.95*a1(4);      

    if (sweeper.sweep_direction == -1)
        show_VA_label (a1, 'VA↓', VA, varargin{:});
    else
        show_VA_label (a1, 'VA↑', VA, varargin{:});
    end
    
end



function show_VA_label (a, VAstr, VA, varargin)

    %% add the down VA
    if (isfinite(VA))
        VA_string = sprintf ('%s = %4.2f logMAR', VAstr, VA); % OD.rightward.VA);
    else
        VA_string = sprintf('%s not found.', VAstr); % OD.rightward.VA);
    end

    
    if (isempty(varargin))
        t.FontSize = 22;
        t = annotation('textbox','String',VA_string,'Position',a,'Vert','top','FitBoxToText','on', 'HorizontalAlignment', 'right');
    else
        
        t = annotation('textbox','String',VA_string,'Position',a,'Vert','top','FitBoxToText','on', varargin{:});
    end
    t.BackgroundColor = 'w';

end



function ret = get_bounded_VA (this_sweep_trial, info, start_time, end_time)

    switch (sign(this_sweep_trial.sweep_direction))

        case { -1 }  % downward sweep

                if (info.dropoff_t <= start_time)   % dropoff before start               
                    ret.VA       = this_sweep_trial.logMAR.max + 0.1;
                    ret.t        = start_time;
                    ret.bounded  = false;

                elseif (info.dropoff_t >= end_time) % dropoff after start 

                    ret.VA       = this_sweep_trial.logMAR.min;
                    ret.t        = end_time;
                    ret.bounded  = false;

                else                                % dropoff in-between

                    ret.VA = this_sweep_trial.logMAR.max + 0.1 + this_sweep_trial.ratio*(info.dropoff_t - start_time);
                    ret.t  = info.dropoff_t;
                    ret.bounded  = true;
                end

        case { +1 }  % upward sweep

                
                if (info.onset_t <= start_time)   % onset before start                                   
                    ret.VA       = this_sweep_trial.logMAR.min;
                    ret.t        = start_time;
                    ret.bounded  = false;

                elseif (info.onset_t >= end_time) % onset after start 
                    
                    ret.VA       = this_sweep_trial.logMAR.max + 0.1;
                    ret.t        = end_time;
                    ret.bounded  = false;

                else  

                    % onset in-between
                    ret.VA = this_sweep_trial.logMAR.min + this_sweep_trial.ratio*(info.onset_t - start_time);
                    ret.t  = info.onset_t;
                    ret.bounded  = true;
                end
              
        otherwise 
            error ('No signed ratio set');
    end

    end



%{
function y = get_record_timestamp (dataTbl, t)

    % GET_RECORD_TIMESTAMP Get timestamp
    %
    %   get_record_timestamp (dataTbl, t)
    %
    % where 
    %       dataTbl is the the data-table
    %       t       is the sensor_timestamp


     i = ismember(dataTbl.t, t);
     if (sum(i) == length(t))
         y = dataTbl.record_timestamp(i);
     else
        error ('Timestamp problem.');
     end

end
%}


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

