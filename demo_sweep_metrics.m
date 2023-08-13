
sweepfile = "/Users/jtur044/Documents/Documents-BN411809/MATLAB/sweep/DATA/BROOKS/TEST/TESTOKN1_OD1/result/okn/clip-1-right_down-sweep_disks/NT";
signalfile = fullfile(sweepfile,  "OD.rightward", "signal.updated.csv");
resultfile = fullfile (sweepfile, "OD.rightward", "result.csv");



dataTbl = readtable (signalfile);
results = readtable (resultfile);

plot (dataTbl.t, dataTbl.x);


min_repeats = 2;
min_separated = 3;

summary = groupsummary (results, ["is_valid","chain_id"]);
i = ((summary.GroupCount >= min_repeats) & (summary.is_valid));
summary = summary(i,:);

include_chain_id    = summary.chain_id;
i = ismember(dataTbl.result_chain_id, include_chain_id); 
dataTbl2 = dataTbl(i,:);

% first time and last time 
min_t = min(dataTbl2.t)
max_t = max(dataTbl2.t)


%% chains summary 

best_t = 0;

total_time = max(dataTbl.t);
M = size(dataTbl,1);
y = false(M,1);
for k = 1:M

    start_time = dataTbl.t(k);
    end_time   = min( [ start_time+2, total_time ]);
    
    i = ((start_time <= dataTbl.t) & (dataTbl.t <= end_time));    
    thisTbl = dataTbl(i,:);

    res = bwconncomp(this_i);
    if (res.NumObjects >= min_separated)
        y(k) = true;
        
        %% information 
        best_n = find(thisTbl.is_okn, 1, 'last');
        best_t = thisTbl.t(best_n);

    else
        y(k) = false;    
    end
    


end

%% find the highest point of SP or QP 


best_t


    