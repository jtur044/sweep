function p = easy_sweep_protocol (inputfile)

% EASY_SWEEP_PROTOCOL Easy sweep protocol

protocol = load_commented_json (inputfile);

disks = containers.Map(); 
main_disk = protocol.DISKS;
main_disk = rmfield (main_disk, "trials");

%% information  
N = length(protocol.DISKS.trials);
for k = 1:N

    each_disk = protocol.DISKS.trials{k};
    disks(each_disk.id) = MergeStruct (main_disk, each_disk);
    
end


%% sweep sequences 

sweep_sequence = containers.Map(); 
sweep_sequence_names = fieldnames (protocol.SWEEP_TABLES);
M = length (sweep_sequence_names);
for k =1:M
       
    each_sweep = protocol.SWEEP_TABLES.(sweep_sequence_names{k});
    for l = 1:length (each_sweep)        
        sequence_list(l) = disks(each_sweep{l}.id);
    end

    this_data.sequence = sequence_list;
    this_data.info     = get_sequence_info (sequence_list);
    sweep_sequence(sweep_sequence_names{k}) = this_data;    
end


%% timelines 

sweep = containers.Map(); 
trials = protocol.timeline;
S = length (trials);
for k = 1:S
    if (strcmpi(trials{k}.type, 'sweep_disks'))           
       
        this_data.trial           = trials{k};
        this_data.sweep_sequence  = sweep_sequence (trials{k}.which);                
        this_data.info.win_length = trials{k}.sweep_step_duration/1000; % in seconds  
        this_data.info.ratio      = this_data.sweep_sequence.info.logmar_step/this_data.info.win_length;         
        sweep(trials{k}.id)       = this_data;    
        
    end
end

%% information 

p.disks = disks;
p.sweep_sequence = sweep_sequence;
p.sweep = sweep;


end

%% Sequence  

function info = get_sequence_info (sequence_list)

    logMAR           = [ sequence_list.logMAR ];
    info.max_logMAR  = max(logMAR);
    info.min_logMAR  = min(logMAR);
    info.logmar_step = mean(diff(logMAR));

% info.win_length  = 2;
% info.ratio       = logmar_step/win_length;

end



