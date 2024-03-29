function info = get_sweep_metrics (signalfile, resultfile, varargin)

% GET_SWEEP_METRICS Determine SWEEP metrics 
%
%   get_sweep_metrics (signalfile, resultfile)
%
% where 
%       signalfile  is the information 
%       resultfile  is the information 
%
% Returns:
%
% Info
%
%   ep      - repeated  OKN signal 
%   sp      - separated OKN signal 
%   found_activity = false;
%   onset_t   = 0; 
%   dropoff_t = 0; 
%

p = inputParser ();

p.addOptional ("onset_threshold", 0.5);
p.addOptional ("dropoff_threshold", 0.5);
p.addOptional ("min_okn_chain_length", 2); 
p.addOptional ("min_okn_chains_per_window", 3); 
p.addOptional ("window_length", 2); 

p.parse(varargin{:});
res = p.Results;

%% import signal.csv file 

if (ischar(signalfile) | isstring(signalfile))
    dataTbl = readtable (signalfile);
elseif (istable (signalfile))
    dataTbl = signalfile;
end

%% HACK! add in is_okn field 
if (~any(ismember(dataTbl.Properties.VariableNames,'is_okn')))
    % dataTbl.is_okn = dataTbl.chain_id
end

%% import results.csv
if (ischar(resultfile) | isstring(resultfile))
    results = readtable (resultfile);
elseif (istable (resultfile))
    results = resultfile;
end


% generate an overall activity 

info.ep         = end_point_chain (dataTbl, results, res.min_okn_chain_length);
info.sp         = separated_activity (dataTbl, results, res.min_okn_chains_per_window, res.window_length);
info.total      = info.ep.chain_activity;
info.total(:,2) = info.total(:,2) | info.sp.separated_activity(:,2);

info.break      = activity_break (info.total, res.window_length);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% We should generate a mask - which can be interpreted in two-ways 
%
%   descending 
%   ascending 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ((~info.ep.found_activity) & ~(info.sp.found_activity))

    % no activity found at all

    info.found_activity = false;
    info.onset_t   = Inf; 
    info.dropoff_t = -Inf;  %% this should be at maximum time 
  

elseif ((~info.ep.found_activity) & (info.sp.found_activity))

    % Only ep activity (i.e., chain)

    info.found_activity = true;
    info.onset_t        = info.sp.onset_t; 
    info.dropoff_t      = info.sp.dropoff_t; 

elseif ((info.ep.found_activity) & (~info.sp.found_activity))

    % Only sp activity (i.e., separated)
        
    info.found_activity = true;
    info.onset_t        = info.ep.onset_t; 
    info.dropoff_t      = info.ep.dropoff_t; 

else   %% both activities found 

    % Take lowest and highest times 
    
    info.found_activity = true;  
    info.onset_t   = min([info.ep.onset_t, info.sp.onset_t]);
    info.dropoff_t = max([info.ep.dropoff_t, info.sp.dropoff_t]);

end

%% lowest  50% threshold  
%% highest 50% threshold  

end


function ret = activity_break (act, drop_duration)

    %% ACTIVITY_BREAK 
    %
    %  returns only those areas with >=2 sec duratiosn  
    %
    %   ret = activity_break (act, drop_duration)

    
    t             = act(:,1);
    is_not_okn    = ~act(:,2);
    regions       = bwconncomp (is_not_okn);
    
    %
    % Find these times: 
    %
    % latest time of lost activity (ascending) 
    %
    % earliest time of lost activity (descending) 
    %

    M = length (regions.PixelIdxList);
    if (M > 1)
        for m = 1:M
            each_region = regions.PixelIdxList{m};
            n1 = each_region(1);
            n2 = each_region(end);
            start_time    = t(n1);
            end_time      = t(n2);
            if ((end_time - start_time) < drop_duration)                
                is_not_okn(n1:n2) = false; 
            end
        end

        % info.found_break = true;
        % info.earliest    = min(interval(:,1)); % descending 
        % info.latest      = max(interval(:,2)); % ascending 
        % info.regions     = interval;
        
    end

    ret(:,1) = t;
    ret(:,2) = is_not_okn;
    

end


function info = end_point_chain (dataTbl, results, min_repeats)

    info.found_activity = false;
    info.found_onset    = false;    
    info.found_dropoff  = false;
    

    %% This will list chains that are valid this should use "result_chain_id"
    results = results(logical(results.is_valid), :);
    summary = groupsummary (results, "chain_id");
    %summary = groupsummary (results, ["is_valid","chain_id"]);
    i = (summary.GroupCount >= min_repeats); % & (summary.is_valid));

    t = dataTbl.t;
    y = t*0;

    %% this will check if a given the sample of data belongs to a repeating chain

    if (any(i))

        valid_chain_id =  summary(i,:).chain_id;
        y = ismember (dataTbl.chain_id, valid_chain_id);

        is_sp    = cellfun (@(x) strcmpi(x,'true'), dataTbl.is_sp);
        is_qp    = cellfun (@(x) strcmpi(x,'true'), dataTbl.is_qp); 

        y = y & (is_sp | is_qp);
        
        %is_okn   = ( is_sp | is_qp );
        %dataTbl2 = dataTbl2(is_okn,:);
    end
    
    info.chain_activity = [ t y  ];

    if (~any(i))
        info.onset_t   = 0; % min(dataTbl2.t);
        info.dropoff_t = 0; % max(dataTbl2.t);
        return
    end

    info.found_activity = true;
    summary = summary(i,:);

    %summary

    include_chain_id    = summary.chain_id;
    i  = ismember(dataTbl.result_chain_id, include_chain_id); 

    %% hack to account for not using "result_chain_id"
    dataTbl2 = dataTbl(i,:);
    %is_sp    = cellfun (@(x) strcmpi(x,'true'), dataTbl2.is_sp);
    %is_qp    = cellfun (@(x) strcmpi(x,'true'), dataTbl2.is_qp); 
    %is_okn   = ( is_sp | is_qp );
    %dataTbl2 = dataTbl2(is_okn,:);

    % first and last repeating chained OKN points  
    info.onset_t   = min(dataTbl2.t);
    info.dropoff_t = max(dataTbl2.t);

    info.found_onset    = true;    
    info.found_dropoff  = true;
       
end


function info = separated_activity (dataTbl, results, min_okn_chains_per_window, window_length) 

%% chains summary 

info.found_activity = false;

info.found_onset = false;
info.onset_t = 0;
info.onset_n = 0;
info.found_onset = false;

info.dropoff_t = 0;
info.dropoff_n = 0;
info.found_dropoff = false;

t = dataTbl.t;
total_time = max(dataTbl.t);
M = size(dataTbl,1);
y = false(M,1);

%% aummary information 
summary = groupsummary (results, ["is_valid","chain_id"]);
i = logical(summary.is_valid);
chains_id = summary.chain_id(i);


%% list VALID chain ids in the SWEEP 
dataTbl.is_valid = ismember(dataTbl.chain_id, chains_id);

g_is_valid = dataTbl.is_valid;
g_is_sp    = cellfun (@(x) strcmpi(x,'true'), dataTbl.is_sp);
g_is_qp    = cellfun (@(x) strcmpi(x,'true'), dataTbl.is_qp); 
g_is_okn   = ( g_is_sp | g_is_qp ) & (g_is_valid);

global_is_okn = dataTbl.t;

for k = 1:M


    %% get the contents of the WINDOW (start_time, end_time)    
    start_time = dataTbl.t(k);
    end_time   = min( [ start_time+window_length, total_time ]);
    i          = ((start_time <= dataTbl.t) & (dataTbl.t <= end_time));    
    
    %% local information 
    thisTbl  = dataTbl(i,:);      
    is_sp    = g_is_sp(i);      % cellfun (@(x) strcmpi(x,'true'), thisTbl.is_sp);
    is_qp    = g_is_qp(i);      % cellfun (@(x) strcmpi(x,'true'), thisTbl.is_qp); 
    is_valid = g_is_valid(i);   % thisTbl.is_valid; 
    is_okn   = g_is_okn(i);     % ( is_sp | is_qp ) & (is_valid);

    %% chain IDs 
    CL_ids = unique(thisTbl.result_id (is_okn));
    if (any(CL_ids==-1))
        error ('This shouldnt be possible');
    end

    res = bwconncomp(is_okn);    
    NumObjects = length (CL_ids);
    if ((NumObjects >= min_okn_chains_per_window) & (res.NumObjects > 1))

        y(k) = true;
        
        %% WE SHOULD DO THIS AT THE END!

        %% ... so find highest dropoff       
        info.dropoff_n = find(is_okn, 1, 'last');
        info.dropoff_t = thisTbl.t(info.dropoff_n);

        %% revised estimate 
        i = dataTbl.t == info.dropoff_t;            
        if (any(i))
           new_chain_id = dataTbl.result_chain_id(i);
           n = find(dataTbl.result_chain_id == new_chain_id, 1, 'last');                                
           info.dropoff_n = n;
           info.dropff_t = dataTbl.t(n);
        end
        
        %% ... and find lowest onset
        if (~info.found_onset)
            onset_n = find(is_okn, 1, 'first');
            if (~isempty(onset_n))                
                info.found_activity = true;

                %% we should check what the earliest point of time is 
                
                % first estimate 
                
                onset_t = thisTbl.t(onset_n);        
                info.onset_t = onset_t;
                info.onset_n = onset_n;
                info.found_onset = true;  

                % revised estimate                 
                i = dataTbl.t == onset_t;            
                if (any(i))
                    new_chain_id = dataTbl.result_chain_id(i);
                    n = find(dataTbl.result_chain_id == new_chain_id, 1);                                
                    info.onset_n = n;
                    info.onset_t = dataTbl.t(n);
                end

            end
         end

        
    else
        y(k) = false;    
    end
end


%% we should zero any points that dont have OKN signalled 

%% NAMED CHAINS 

r                 = (y & (g_is_okn)); 
valid_chain_id    = unique(dataTbl.chain_id (r));
valid_data_points = ismember(dataTbl.chain_id, valid_chain_id) & (g_is_sp | g_is_qp );
r                 = r | valid_data_points;


info.separated_activity = [ t r ];

end
