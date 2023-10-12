function protocol = easy_sweeper_protocol (inputfile)

% EASY_SWEEPER_PROTOCOL Easy sweep protocol
%
% This will load protocol 
%
%   expand disk_set
%   expand sweep_set
%   expand timeline
%

protocol = load_commented_json (inputfile);

%% get the disk_set  
x_disks = containers.Map(); 

disk_set = protocol.disk_set;
if (isfield(disk_set, "x0x5F_parameters"))
    disk_set_parm = disk_set.x0x5F_parameters;
    disk_set = rmfield (disk_set, "x0x5F_parameters");
end

% cycle through conditions 
fnames = fieldnames(disk_set);
N = length(fnames);
for k = 1:N
    each_disk = disk_set.(fnames{k});
    x_disks(fnames{k}) = MergeStruct (disk_set_parm, each_disk);
end

protocol.disk_set = x_disks;  %% updated with explaned set


sweeps = containers.Map(); 

%% kludgy 

sweep_set = protocol.sweep_set;
if (isfield(sweep_set, "step_duration"))
    step_duration = sweep_set.step_duration;
    sweep_set = rmfield(sweep_set, "step_duration");
end

if (isfield(sweep_set, "x0x5F_parameters"))
    sweep_parms = sweep_set.x0x5F_parameters;
    sweep_set = rmfield(sweep_set, "x0x5F_parameters");
end

%% e.g.,left_down, right_down 

sweep_seq = fieldnames (sweep_set);
M = length (sweep_seq);
for k =1:M       

    each_sweep = sweep_set.(sweep_seq{k});
    if (isfield(each_sweep, "x0x5F_parameters"))   
        each_sweep_parms = each_sweep.x0x5F_parameters;
        each_sweep = rmfield (each_sweep, "x0x5F_parameters");
    else
        each_sweep_parms = [];
    end 

    events = fieldnames(each_sweep);
    N = length (events);
    count = 1; 
    for l = 1:N  %% e.g., entry, sweep, exit

            each_event = events{l};
            Q = length (each_sweep.(each_event));

            for q = 1:Q

                %% convert to an "addable" event
                this_disk = each_sweep.(each_event){q}; 

                replacestr = sprintf('_0x%s_',dec2hex(double('-')));
                disk_key   = strrep (this_disk.id, '-', replacestr);

                this_one = disk_set.(disk_key);
                this_one.event_type = each_event;   

                if (count == 1)
                    x_each_sweep = this_one;
                else
                    x_each_sweep(count) = this_one;                
                end 

                count = count + 1;
            end

            
    end

    %% put things back 
    
    protocol.sweep_set.(sweep_seq{k}).sweep = x_each_sweep;
    protocol.sweep_set.(sweep_seq{k}).x0x5F_parameters = each_sweep_parms;           
    
    %% put things back
    %
    %   step_duration
    %   sweep_parms

    protocol.sweep_set.step_duration    = step_duration;
    protocol.sweep_set.x0x5F_parameters = sweep_parms;
    
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% "id" : "trial-2", "which" : "right_down"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Q = length (protocol.timeline);
%
%for q = 1:Q
%end

    
end



function info = get_sequence_info (sequence_list)




    logMAR           = [ sequence_list.logMAR ];
    info.max_logMAR  = max(logMAR);
    info.min_logMAR  = min(logMAR);
    info.logmar_step = mean(diff(logMAR));

% info.win_length  = 2;
% info.ratio       = logmar_step/win_length;

end



