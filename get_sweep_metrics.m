function info = get_sweep_metrics (signalfile, resultfile, varargin)

% GET_SWEEP_METRICS Determine SWEEP metrics 
%
%   get_sweep_metrics (signalfile, resultfile)
%
% where 
%       signalfile  is the information 
%       resultfile  is the information 
%

p = inputParser ();

p.addOptional ("onset_threshold", 0.5);
p.addOptional ("dropoff_threshold", 0.5);
p.addOptional ("min_okn_chain_length", 2); 
p.addOptional ("min_okn_chains_per_window", 3); 
p.addOptional ("window_length", 2); 

p.parse(varargin{:});
res = p.Results;

dataTbl = readtable (signalfile);
results = readtable (resultfile);

%% maximum OKN 2-chain point 
%% minimum OKN 2-chain point 

info.ep = end_point_chain (dataTbl, results, res.min_okn_chain_length);
info.sp = separated_activity (dataTbl, results, res.min_okn_chains_per_window);

% check for highest and lowest 

if ((~info.ep.found_activity) & ~(info.sp.found_activity))

    % no activity found at all

    info.found_activity = false;
    info.onset_t   = 0; 
    info.dropoff_t = 0; 

elseif ((~info.ep.found_activity) & (info.sp.found_activity))

    % Only ep activity (i.e., chain)

    info.found_activity = true;
    info.onset_t   = info.sp.onset_t; 
    info.dropoff_t = info.sp.dropoff_t; 

elseif ((info.ep.found_activity) & (~info.sp.found_activity))

    % Only sp activity (i.e., separated)
        
    info.found_activity = true;
    info.onset_t   = info.ep.onset_t; 
    info.dropoff_t = info.ep.dropoff_t; 

else   %% both activities found 

    % Take lowest and highest times 
    
    info.found_activity = true;  
    info.onset_t   = min([info.ep.onset_t, info.sp.onset_t]);
    info.dropoff_t = max([info.ep.dropoff_t, info.sp.dropoff_t]);

end

%% lowest  50% threshold  
%% highest 50% threshold  

end

function info = end_point_chain (dataTbl, results, min_repeats)

    info.found_activity = false;
    info.found_onset    = false;    
    info.found_dropoff  = false;
    
    summary = groupsummary (results, ["is_valid","chain_id"]);
    i = ((summary.GroupCount >= min_repeats) & (summary.is_valid));

    if (~any(i))
        info.onset_t   = 0; % min(dataTbl2.t);
        info.dropoff_t = 0; % max(dataTbl2.t);
        return
    end

    info.found_activity = true;
    summary = summary(i,:);

    include_chain_id    = summary.chain_id;
    i = ismember(dataTbl.result_chain_id, include_chain_id); 
    dataTbl2 = dataTbl(i,:);

    % first and last repeating chained OKN points  
    info.onset_t   = min(dataTbl2.t);
    info.dropoff_t = max(dataTbl2.t);

    info.found_onset    = true;    
    info.found_dropoff  = true;
       
end


function info = separated_activity (dataTbl, results, min_okn_chains_per_window) 

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
for k = 1:M

    start_time = dataTbl.t(k);
    end_time   = min( [ start_time+2, total_time ]);
    
    i = ((start_time <= dataTbl.t) & (dataTbl.t <= end_time));    
    thisTbl = dataTbl(i,:);

    res = bwconncomp(thisTbl.is_okn);
    if (res.NumObjects >= min_okn_chains_per_window)
        y(k) = true;
        
        %% find highest dropoff       
        info.dropoff_n = find(thisTbl.is_okn, 1, 'last');
        info.dropoff_t = thisTbl.t(info.dropoff_n);
        if (info.dropoff_t > info.dropoff_t)
            info.found_dropoff = true;
            info.dropoff_t = dropoff_t;
            info.dropoff_n = dropoff_n;
        end    

        %% find lowest onset
        if (~info.found_onset)
            onset_n = find(thisTbl.is_okn, 1, 'first');
            if (~isempty(onset_n))                
                info.found_activity = true;
                onset_t = thisTbl.t(onset_n);        
                info.onset_t = onset_t;
                info.onset_n = onset_n;
                info.found_onset = true;   
            end
         end

        
    else
        y(k) = false;    
    end
end

%info.onset_t   = min(dataTbl2.t);
%info.dropoff_t = max(dataTbl2.t);
      

info.separated_activity = [ t y ];

end
