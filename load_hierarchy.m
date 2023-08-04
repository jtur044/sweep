function final = load_hierarchy (this_dir, root_dir, setupfile)

%% LOAD_HIERARCHY Transverse up the tree merging setupfiles 
%
%   y = load_hierarchy (this_dir, root_dir, setupfile)
%   y = load_hierarchy (this_dir, setupfile)
% 
% where 
%       this_dir    is the branch directory 
%       root_dir    is the main directory 
%       setupfile   is the file to merge (setup.config)
%
% 


    y =[];
    
    if (nargin == 2)
        setupfile = root_dir;
        root_dir = this_dir;
    else 
        if (~contains (this_dir, root_dir))
            error ('root needs to be part of the specified directory.');
        end
    end
    
    %% now we can put these back ON
    
    count = 1;
    isroot = false;
    this_info = {};
    while (~isroot)

        %% step up a directory         
        isroot = strcmp(this_dir, root_dir);        
        load_file = fullfile (this_dir, setupfile);    
        if  (exist(load_file, 'file'))            
            this_info{count} = load_commented_json (load_file);       
            count = count + 1;
        end
        
        %% up a directory
        this_dir = fileparts(this_dir);
    end
    
    
    if (isempty(this_info))
        error ('no CONFIG was FOUND.');
    end
    
    %% The 'final' is the root setup file  
    final = this_info{end};    
    N = length (this_info);
    if (N == 1)
        return
    end
    
    for k = (N-1):-1:1        
        final = MergeStruct (final, this_info{k});        
    end
    
end


%% OVERWRITE INFORMATION 

function A = overwrite (A, b)
    flds = fieldnames (b);    
    M = length (flds);
    for k=1:M    
        
        %% clear the field (PROBABLY
        %if (isfield(A, flds{k}))        
        %   A.(flds{k}) = [];
        %end
        
        %% replace 
        A.(flds{k}) = b.(flds{k});        
     end

end














