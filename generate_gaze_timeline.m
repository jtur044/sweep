function generate_gaze_timeline (inputfile, gazefile, outputfile)

%% GENERATE_GAZE_TIMELINE Determine a gaze timeline FILE 
%
%   generate_gaze_timeline (timelinefile, gazefile, outputfile)
%
% where 
%       timelinefile = location of original timeline.json 
%       gazefile     = location of gaze.csv with events 
%       outputfile   = updated timeline.gaze.json file
%



%% gaze information  
gazetbl   = readtable (gazefile);
is_event  = cellfun (@(x) ~isempty(x), gazetbl.event_string);
eventtbl  = gazetbl(is_event, :);

%% timeline 
count = 1;
input_obj  = load_commented_json (inputfile); 0

index2  =1;
N = length(input_obj);
for k = 1:N

    each_item = input_obj {k};
    if (isfield(each_item,'start'))  %% start/end marker combo     
       
        %% find start  
        index = find_event (each_item.start, eventtbl, index2);            
        if  (isempty (index))            
            error ('inconsistency found.');
        end

        %% process 
        % fprintf ('process ... %d\n', k);
        
        fprintf ('start=%4.2f, end=%4.2f\n', each_item.start.timestamp.pts_time, each_item.end.timestamp.pts_time);
        
        %%%%%%%%%%%%%%%%%%
        %   INFORMATION  %
        %%%%%%%%%%%%%%%%%%

        each_item.start.timestamp.pts_time = eventtbl.record_timestamp(index);       
        fprintf ('start replace = %4.2f\n', eventtbl.record_timestamp(index));

        %% find end evemt 
        index2 = find_event (each_item.end, eventtbl, index2);            
        if  (isempty (index2))            
            error ('inconsistency found.');
        end

        %% process 
        %fprintf ('process ... %d\n', k);
        each_item.end.timestamp.pts_time = eventtbl.record_timestamp(index2);       
        fprintf ('end replace = %4.2f\n', eventtbl.record_timestamp(index2));
        

        %fprintf (' start=%4.2f, end=%4.2f\n', each_item.start.timestamp.pts_time, each_item.end.timestamp.pts_time);

        %keyboard;
        output_obj{count} = each_item;
        count = count + 1;
                
    end 

end

%% save-json  
savejson ([], output_obj, outputfile);

end

%% Information 

function y = find_event (x1, eventtbl, k_start)

    if (nargin == 2)
        k_start = 1;
    end


    y = [];
    
    N = size (eventtbl, 1);
    for k = k_start:N 
        jsonstr = eventtbl(k,:).event_string{1};
        try
            
            t  = x1.event;
            e  = loadjson(jsonstr);            
            if (isequal(t,e))                            
                y = k; 
                return
            end 
        catch ME 

        end    
    end 

    y = [];

end