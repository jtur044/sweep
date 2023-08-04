function protocol = load_commented_json (protocolfile)

% LOAD_COMMENTED_JSON load protocol file with comments 


    temp_protocolfile = tempname();        
    stripcomments(protocolfile, temp_protocolfile);        

    %try
    
        protocol = loadjson (temp_protocolfile);

    %catch ME
        
        %error (sprintf('Error loading protocol file ... %s', protocolfile));
        
    %end
    
end