function protocol = load_commented_json (protocolfile)

% LOAD_COMMENTED_JSON load protocol file with comments 
%
%  ASSUMES THE EXISTENCE OF 
% 
%       strip-json-comments-cli
%
%   npm install --global strip-json-comments-cli
%


    temp_protocolfile = tempname();      
    
    if (~exist(protocolfile,'file'))
        error (sprintf('Error loading protocol file ... %s', protocolfile));
    end
    

    try 
         
        strp = sprintf('strip-json-comments "%s" > "%s"', protocolfile, temp_protocolfile);
        system(strp);

    catch ME 

         throw ME;

    end 


    try
    
        protocol = loadjson (temp_protocolfile);

    catch ME
        
        error (sprintf('Error loading protocol file ... %s', protocolfile));
        
    end
    
end