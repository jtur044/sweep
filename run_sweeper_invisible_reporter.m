 function run_sweeper_invisible_reporter  (participant_file, varargin)

% RUN_SWEEPER_INVISIBLE_REPORTER Report on SWEEPS 
%
%   run_sweeper_invisible_reporter  (participant_file, ...)
%
% where 
%       participant_file  is the participant file (invisible)   
%
% opts 
%       data_directory    is the main directory for ['./DATA']
%
% EXAMPLE  
%
%   % generate output information 
%   run_sweeper_invisible_reporter ('./DATA/EXPERIMENT/participant_info_lab.xlsx', 'is_generator', true);
%   
%   % information 
%   run_sweeper_invisible_reporter ('./DATA/EXPERIMENT/participant_info_lab.xlsx');
%


%% Informational 
p = inputParser ();
p.addOptional ('data_directory', './DATA');
p.addOptional ('is_generator', false);
p.addOptional ('ignorefile', []);
p.parse (varargin{:});
res = p.Results;


%% participant information 

inputTbl    = readtable(participant_file);


fprintf ('looking for ignore file ...');

if (isempty(res.ignorefile))
   [mypath, mybase, myext] = fileparts (participant_file);
   participant_ignore_file = fullerfile(mypath,strcat(mybase, '.ignore', myext));  
else
   participant_ignore_file = res.ignorefile;
end
fprintf ('%s\n', participant_ignore_file);

if (exist(participant_ignore_file, 'file'))
    exclTbl     = readtable(participant_ignore_file);
    fprintf ('found.\n');
else
    exclTbl = [];
    fprintf ('not found.\n');
end


%% run the generator if needed  

[pathname,basename,~] = fileparts (participant_file);    
outputDir  = fullerfile (pathname, basename);
outputFile = fullerfile (outputDir, 'experiment_main_data.csv');
summaryFile  = fullerfile (outputDir, 'experiment_summary_data.json');

if (res.is_generator)

    %% export generated data 
    
    g = run_generator (res, inputTbl, exclTbl);
    createdirectory (outputDir);
    writetable (g, outputFile);
    
    summary.mean_diff_VA_descending      = mean(g.mean_VA_descending - g.EVA, 'omitnan');
    summary.mean_diff_VA_ascending       = mean(g.mean_VA_ascending- g.EVA, 'omitnan');
    summary.mean_diff_VA                 = mean(g.mean_VA - g.EVA, 'omitnan');
    
    summary.consensus_diff_VA_descending = mean(g.consensus_VA_descending - g.EVA, 'omitnan');
    summary.consensus_diff_VA_ascending  = mean(g.consensus_VA_ascending - g.EVA, 'omitnan');
    summary.consensus_diff_mean_VA       = mean(g.consensus_VA - g.EVA, 'omitnan');
    
    %% save summary experiment main data 
    
    savejson ([], summary, summaryFile);
    fprintf ('wrote ... %s\n', summaryFile);

else 

    g = readtable (outputFile);
    l = load_commented_json (summaryFile);
end


%% report formatted data 
%
%  id, show, od_EVA, od_SWEEP, od_SWEEP_std,  os_EVA, os_SWEEP, os_SWEEP_std  
%
% Then 
%      summary 

i_Rx    = (g.Group == 0);
i_noRx  = (g.Group == 1);

Rx      = g(i_Rx,:);

% round everything to 2-dp for presentation 
Rx.EVA      = round(Rx.EVA, 2);
Rx.mean_VA  = round(Rx.mean_VA, 2);

i_OD    = strcmpi(Rx.Eye, 'OD');
i_OS    = strcmpi(Rx.Eye, 'OS');
tblRx   = innerjoin(Rx(i_OS,:), Rx(i_OD,:), 'Keys', {'id', 'Group' });

noRx    = g(i_noRx,:);

% round everything to 2-dp for presentation 

noRx.EVA      = round(noRx.EVA, 2);
noRx.mean_VA  = round(noRx.mean_VA, 2);

i_OD    = strcmpi(noRx.Eye, 'OD');
i_OS    = strcmpi(noRx.Eye, 'OS');
tblnoRx   = innerjoin(noRx(i_OS,:), noRx(i_OD,:), 'Keys', {'id', 'Group' });

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE RX TABLE 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

output.data     = table2struct (tblRx);

% round columns 

groupFilter = ((g.Group == 0) & logical(g.Analyze));
h = g(groupFilter,:);
fprintf ('VA deficit (OKN). (n = %d)\n', size(h,1));
fprintf ('mean_VA : %4.2f ± %4.2f\n ', mean(h.mean_VA), 2*std(h.mean_VA));
fprintf ('asc. mean_VA : %4.2f ± %4.2f\n ', mean(h.mean_VA_ascending), 2*std(h.mean_VA_ascending));
fprintf ('desc. mean_VA : %4.2f ± %4.2f\n ', mean(h.mean_VA_descending), 2*std(h.mean_VA_descending));
fprintf ('mean_VA (EVA): %4.2f ± %4.2f\n ', mean(h.EVA), 2*std(h.EVA));

h0=h;

output.summary.mean_VA  = round(mean(h.mean_VA), 2);
output.summary.mean_EVA = round(mean(h.EVA), 2);
output.summary.std_VA   = round(2*std(h.mean_VA), 2);
output.summary.std_EVA  = round(2*std(h.EVA), 2);

rxjsonfile    = fullerfile (outputDir, 'summary-rx-group.json');
writelines(jsonencode (output), rxjsonfile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE NORX TABLE 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

output.data     = table2struct (tblnoRx);

% round columns 



groupFilter = ((g.Group == 1) & logical(g.Analyze));
h = g(groupFilter,:);
fprintf ('No VA deficit. (n = %d)\n', size(h,1))
fprintf ('VA (mean ± 2SD)\n ', mean(h.mean_VA), 2*std(h.mean_VA))
fprintf ('mean_VA : %4.2f ± %4.2f\n ', mean(h.mean_VA), 2*std(h.mean_VA))
fprintf ('asc. mean_VA : %4.2f ± %4.2f\n ', mean(h.mean_VA_ascending), 2*std(h.mean_VA_ascending))
fprintf ('desc. mean_VA : %4.2f ± %4.2f\n ', mean(h.mean_VA_descending), 2*std(h.mean_VA_descending))
fprintf ('mean_VA (EVA): %4.2f ± %4.2f\n ', mean(h.EVA), 2*std(h.EVA));

h1=h;

output.summary.mean_VA  = round(mean(h.mean_VA), 2);
output.summary.mean_EVA = round(mean(h.EVA), 2);
output.summary.std_VA   = round(2*std(h.mean_VA), 2);
output.summary.std_EVA  = round(2*std(h.EVA), 2);

norxjsonfile  = fullerfile (outputDir, 'summary-norx-group.json');
writelines(jsonencode (output), norxjsonfile);


%% statistics graphs 



fprintf ('Statistics\n')

fprintf ('Group 0 vs Group 1. small p = doubt\n');

% The result h is 1 if the test rejects the null hypothesis at the 5% significance level, and 0 otherwise.
% null hypothesis that the data in vectors x and y comes from independent random samples from normal distributions with equal means 
% and equal but unknown variances

[h,p,ci,stats] = ttest2(h0.mean_VA, h1.mean_VA);
fprintf ('h=%d. p=%4.2f\n', h, p);


fprintf ('Group 0 VA-ETDRS vs VA-SWEEP.\n');
fprintf ('Paired t-test, h=0 means that null hypothesis is not rejected at the 5% significance level.\n');

[h,p,ci,stats] = ttest(h0.mean_VA, h0.EVA);
fprintf ('h=%d. p=%4.2f\n', h, p);


fprintf ('Group 1 VA-ETDRS vs VA-SWEEP.\n');
fprintf ('Paired t-test, h=0 means that null hypothesis is not rejected at the 5% significance level.\n');

[h,p,ci,stats] = ttest(h1.mean_VA, h1.EVA);
fprintf ('h=%d. p=%4.2f\n', h, p);







%% make summaries of information 

close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NORX 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure (1); clf; 
showBlandAltman ('all', h0);
outputFile = fullerfile (outputDir, 'fig-BA-DEFICIT.png');
exportgraphics(gcf, outputFile); 

figure (2); clf; 
showBlandAltman ('all', h1);
outputFile = fullerfile (outputDir, 'fig-BA-NODEFICIT.png');
exportgraphics(gcf, outputFile); 



%{
% creates a figure 
groupFilter = ((g.Group == 0) & (g.Analyze));
showBlandAltman ('by_OS', g(groupFilter, :));
outputFile = fullerfile (outputDir, 'fig-BA-by-OS.png');
exportgraphics(gcf, outputFile); 

% creates a figure 
groupFilter = ((g.Group == 0) & (g.Analyze));
showBlandAltman ('by_OD', g(groupFilter, :));
outputFile = fullerfile (outputDir, 'fig-BA-by-OD.png');
exportgraphics(gcf, outputFile); 


% creates a Random Figure 
groupFilter = ((g.Group == 0) & (g.Analyze));
showBlandAltman ('by_random_eye', g(groupFilter, :));
outputFile = fullerfile (outputDir, 'fig-BA-by-random.png');
exportgraphics(gcf, outputFile); 

% creates a Random Figure 
groupFilter = ((g.Group == 0) & (g.Analyze));
showBlandAltman ('by_combined_eye', g(groupFilter, :));
outputFile = fullerfile (outputDir, 'fig-BA-by-combined.png');
exportgraphics(gcf, outputFile); 
%}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NORX 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{

% creates a figure 
groupFilter = ((g.Group == 1) & (g.Analyze));
showBlandAltman ('by_OS', g(groupFilter, :));
outputFile = fullerfile (outputDir, 'fig-BA-by-OS-NORX.png');
exportgraphics(gcf, outputFile); 

% creates a figure 
groupFilter = ((g.Group == 1) & (g.Analyze));
showBlandAltman ('by_OD', g(groupFilter, :));
outputFile = fullerfile (outputDir, 'fig-BA-by-OD-NORX.png');
exportgraphics(gcf, outputFile); 


% creates a Random Figure 
groupFilter = ((g.Group == 1) & (g.Analyze));
showBlandAltman ('by_random_eye', g(groupFilter, :));
outputFile = fullerfile (outputDir, 'fig-BA-by-random-NORX.png');
exportgraphics(gcf, outputFile); 

% creates a Random Figure 
groupFilter = ((g.Group == 1) & (g.Analyze));
showBlandAltman ('by_combined_eye', g(groupFilter, :));
outputFile = fullerfile (outputDir, 'fig-BA-by-combined-NORX.png');
exportgraphics(gcf, outputFile); 

%}


end


function r = assignParameter (x, r)

    if (isempty(x))
        return
    end

    r = x;
    return
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SHOW INFORMATION 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function showBlandAltman (this_arrangement, y, varargin)

    
    switch (this_arrangement)


        case { 'all'}

            [X2, X1] = get_all_data (y);
            label = {'VA-EVA','VA-SWEEP','logMAR'};
            tit = 'VA-SWEEP versus VA-EVA';
                        
            %% gnames 
            gnames = { 'Selected Eye' };


        case { 'by_OD' }
            
            %% x-axes titles and units 
            [X1, X2] = get_data_per_eye (y, 'OD');        
            label = {'VA-EVA','SS-VA','logMAR'};
                        
            %% titles 
            tit = 'SS-VA versus VA-EVA (OD)';

            %% gnames 
            gnames = { 'OD' };


        case { 'by_OS' }
            
            %% x-axes titles and units 
            [X1, X2] = get_data_per_eye (y, 'OS');        
            label = {'VA-EVA','SS-VA','logMAR'};
                        
            %% titles 
            tit = 'SS-VA versus VA-EVA (OS)';
            
            %% gnames 
            gnames = { 'OS' };

        case { 'by_random_eye' }
            
            %% x-axes titles and units 
            [X1, X2] = get_data_per_eye (y, 'random_eye');        
            label = {'VA-EVA','SS-VA','logMAR'};
                        
            %% titles 
            tit = 'SS-VA versus VA-EVA (Random)';
            
            %% gnames 
            gnames = { 'Random Eye' };



        case { 'by_combined_eye' }

            
            %% x-axes titles and units 
            [X1, X2] = get_data_by_eye (y);        
            label = {'VA-EVA','VA-OKN','logMAR'};
            
            %% titles 
            tit = 'VA-OKN versus VA-EVA (Combined)';
            
            %% gnames 
            gnames = { 'OD','OS' };

    end

    BlandAltman (X1, X2, label, tit, gnames, 'markerSize', 10, ...
            'baInfo', { 'LOA' },...
            'corrInfo', { 'eq', 'r2' }); % , varargin{:})



end

function [X1, X2] = get_data_by_eye (y)


    [y1, x1] = get_data_per_eye (y, 'OD');
    [y2, x2] = get_data_per_eye (y, 'OS');
        
    N = max([ length(y1), length(y2) ]);    
    X1 = nan*ones(N,2);
    X1(1:length(y1),1) = y1;
    X1(1:length(y2),2) = y2;

    X2 = nan*ones(N,2);
    X2(1:length(y1),1) = x1;
    X2(1:length(y2),2) = x2;
    
end


function [X1, X2] = get_all_data (y)
    
    X1 = y.mean_VA;
    X2 = y.EVA;
    
end


function [X1, X2] = get_data_per_eye (y, which_eye)

    if (strcmpi(which_eye,'random_eye'))    
            
        [X1, X2] = get_data_by_eye (y);
        M = size(X1,1);
        selector = randi([ 1 2 ], M, 1);
        
        ind = sub2ind([ M 2], (1:M).', selector);
        X1 = X1(ind);
        X2 = X2(ind);
        return
    end

    i = strcmpi(y.Eye, which_eye);
    X1 = y.mean_VA (i); 
    X2 = y.EVA (i);
    
end



function y = run_generator (res, inputTbl, exclTbl)

    %% read the generator file 

    P = size(inputTbl, 1);
    for p =1:P 
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % SWEEP DIRECTORY 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        each_eye            = inputTbl (p, :);
    
        input_file          = fullerfile (res.data_directory, each_eye.Date{1}, each_eye.File{1});
        each_results_dir    = fullerfile(input_file, 'results');
            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Given people 
        %
        % 1. EVA 
        % 2. mean descending sweep VA 
        % 3. mean ascending sweep VA 
        % 4. mean all sweep VA
        % 5. mean descending consensus VA 
        % 6. mean ascending consensus VA 
        % 7. mean consensuses VA 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        input_file = fullerfile(each_results_dir, 'sweepVA.csv');
        each_sweep_data = readtable(input_file);

        % individual VA INFORMATION (for OVERRIDE)
        input_file = fullerfile(each_results_dir, '../trials', 'VA.csv');
        each_trials_data = readtable(input_file, 'Delimiter', ',');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   summary.json 
        %
        %	2. "mean_descending_VA": 0.01859720945,
        %	3. "mean_ascending_VA": 0.1015186715,
        %	4. "mean_mean_VA": 0.06005794048,
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        input_file = fullerfile(each_results_dir, 'summary.json');
        each_sweep_summary = load_commented_json(input_file);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   simple_consensus_VA.json
        %
        %	7. "meanVA": 0.07459815264,
        %	5. "dropoff_VA": 0,
        %	6. "onset_VA": 0.1491963053
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        input_file = fullerfile(each_results_dir, 'simple_consensus_VA.json');
        each_consensus_summary = load_commented_json(input_file);
    
    
        %% see if we contains an IGNORE 
        i = ismember(exclTbl.File, each_eye.File) & (exclTbl.Ignore); % & contains (each_trials_data.name, exclTbl.Trial);
        thisExcl = exclTbl(i,:);

        if (p == 1)
    
            %% easy way to get VA near computed VA
            appInfo.EVA                     = each_eye.VA;
            

            if (~any(i))

                 appInfo.mean_VA_descending      = each_sweep_summary.mean_descending_VA;
                 appInfo.mean_VA_ascending       = each_sweep_summary.mean_ascending_VA;
                 appInfo.mean_VA                 = each_sweep_summary.mean_mean_VA;

                 appInfo.unbounded                = any((each_trials_data.VA == 1.1) & (~logical(each_trials_data.bounded)));
                 
            else 
                 
                %% these trials will be marked unbounded 
                 i = ismember(each_trials_data.name, thisExcl.Trial);                  
                 appInfo.mean_VA_descending      = each_sweep_summary.mean_descending_VA;
                 appInfo.mean_VA_ascending       = each_sweep_summary.mean_ascending_VA;
                 appInfo.mean_VA                 = mean(each_trials_data.VA(~i));
                 appInfo.unbounded               = false; % any((each_trials_data.VA == 1.1) & (~logical(each_trials_data.bounded)));

                 fprintf ('applying ignore sweep rule ... %4.2f to %4.2f (%s)\n', each_sweep_summary.mean_mean_VA, appInfo.mean_VA, each_eye.File{:});                 


            end 

            appInfo.consensus_VA_descending  = assignParameter(each_consensus_summary.dropoff_VA, nan);
            appInfo.consensus_VA_ascending   = assignParameter(each_consensus_summary.onset_VA,nan);
            appInfo.consensus_VA             = assignParameter(each_consensus_summary.meanVA, nan); 
        
            %% contains unbounded information 
            %appInfo.unbounded                = any (~logical(each_trials_data.bounded));


            %{
            if (appInfo.unbounded)

                i = logical(each_trials_data.bounded);

                %if (sum(i) < length(i)/2)
             
                    % appInfo.mean_VA = mean(each_trials_data.VA(i));
                    %
                    % i = (each_trials_data.bounded) & (each_trials_data.k < 0);                
                    % appInfo.mean_VA_descending = mean(each_trials_data.VA(i));
                    %
                    % i = (each_trials_data.bounded) & (each_trials_data.k > 0);                
                    % appInfo.mean_VA_ascending  = mean(each_trials_data.VA(i));

                % end
                %appInfo.mean_VA_descending      = each_sweep_summary.mean_descending_VA;
                %appInfo.mean_VA_ascending       = each_sweep_summary.mean_ascending_VA;
                %appInfo.mean_VA                 = each_sweep_summary.mean_mean_VA;
        
            end
            %}


        else
        



            %% easy way to get VA near computed VA
            appInfo(p).EVA                      = each_eye.VA;
            

          if (~any(i))

                 appInfo(p).mean_VA_descending      = each_sweep_summary.mean_descending_VA;
                 appInfo(p).mean_VA_ascending       = each_sweep_summary.mean_ascending_VA;
                 appInfo(p).mean_VA                 = each_sweep_summary.mean_mean_VA;

                 appInfo(p).unbounded                = any((each_trials_data.VA == 1.1) & (~logical(each_trials_data.bounded)));
          
          else 

                 i = ismember(each_trials_data.name, thisExcl.Trial);                  
                 appInfo(p).mean_VA_descending      = each_sweep_summary.mean_descending_VA;
                 appInfo(p).mean_VA_ascending       = each_sweep_summary.mean_ascending_VA;
                 appInfo(p).mean_VA                 = mean(each_trials_data.VA(~i));
                 appInfo(p).unbounded               = false; % any((each_trials_data.VA == 1.1) & (~logical(each_trials_data.bounded)));

                 fprintf ('applying ignore sweep rule ... %4.2f to %4.2f (%s)\n', each_sweep_summary.mean_mean_VA, appInfo(p).mean_VA, each_eye.File{:});                 

            end 

            % appInfo(p).std_VA_descending   = each_sweep_summary.mean_descending_VA;
            % appInfo(p).std_VA_ascending    = each_sweep_summary.mean_ascending_VA;
            % appInfo(p).std_VA              = each_sweep_summary.mean_mean_VA;
    
            appInfo(p).consensus_VA_descending  = assignParameter(each_consensus_summary.dropoff_VA, nan);
            appInfo(p).consensus_VA_ascending   = assignParameter(each_consensus_summary.onset_VA, nan);
            appInfo(p).consensus_VA             = assignParameter(each_consensus_summary.meanVA, nan); 


        end
    
    end 
    
    u = struct2table (appInfo);
    y = [ inputTbl u ];


    

end