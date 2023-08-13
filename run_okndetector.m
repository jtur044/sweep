function run_okndetector (configfile, inputfile, outputdir, varargin)

% RUN_OKNDETECTOR Generate updated signals 
%
%   run_updater (configfile, inputfile, outputdir, varargin)
%
% where 
%       configfile is the location of the OKN configuration file 
%       inputfile  is the input data .CSV file (results.csv) 
%       outputdir  is the updated data file (results.updated.csv)
%       whichCol   is the type of data column (EC/NT)
%
% see demo_updater 
%

p = inputParser ();
p.addOptional ('ProgressTitle', 'okn');
p.addOptional ('snippetString', []);
p.parse(varargin{:});
res = p.Results;


%% load configuration file 

if (ischar(inputfile) | isstring(inputfile))
   dataTbl  = readtable (inputfile); 
end


%%  SETUP Basic Information 

% cdp_timeline = fullfile (each_path, each_name, 'steps.json');
[each_path, each_name, ~] = fileparts (inputfile);        


%%% extra information 
%extra.logfile    = fullfile (each_path, '../../clips/log.json');
%extra.log        = load_commented_json(extra.logfile);
%extra.inputfile  = inputfile;
%extra.outputfile = outputfile;
%extra.config     = config;

clear textprogressbar;
textprogressbar(sprintf('%s:', res.ProgressTitle));

%% Update each Tracker similarly    
total_table = table();    

K = 1;

%% Check if we have a TrackerId  
is_tracker_id = contains('TrackerId',dataTbl.Properties.VariableNames);
if (is_tracker_id)
    ids = unique(dataTbl.TrackerId);    
    K = length(ids); 
end 

%% Check if we have SNIPPETS defined
is_snippets = ~isempty(res.snippetString);

%% Check if EYE is DEFINED 
is_eye = contains('eye',dataTbl.Properties.VariableNames);

%% Each Tracker Id 
counter = 0;
% M = length(config.filters);

%% Configuration for OKN detector

% if (isstring(config) | ischar(config))
%    config = load_commented_json (config);
% end


%% Cycle through trackers    
for k = 1:K
    
         
        
        if (is_tracker_id)
            
            
            %% get the tracker 
            eachTrackerId = ids(k);
            rows = dataTbl.TrackerId == eachTrackerId;
            eachTbl = dataTbl(rows, :);
            
            %% get the eye to which the tracker applies 
            whichEye = unique(eachTbl.eye);
            if (length(whichEye) > 1)
                error ('Error inconsistnecy in data');
            end            
            whichEye = whichEye{1};
            
        end
        
        
        
        %% run OKNDETECTOR configuration  
        
        if ((is_snippets) & (is_tracker_id) & (is_eye))
        
            %% Snippets are DEFINED
            %
            %  Override the default TrackerId 
            %
                        
            %
            % MIGHT HAVE MESSED THIS UP!
            %
            
            
            overrideString = getOverrideString (eachTrackerId, res.snippetString);

            
            %% left_okn detection (will create non-existent path)
            thisoutputdir = fullfile(outputdir, sprintf('%s.leftward',whichEye));  

            disp (thisoutputdir)

            strline = sprintf ('okndetector -c "%s" -i "%s" -x "%s" -o "%s" -d %d', configfile, inputfile, overrideString, thisoutputdir, -1);        
            [status,result] = system(strline);
            %disp(strline);  
            
            thisoutputfile = fullerfile (thisoutputdir, 'result.json');            
            strline = sprintf ('oknconvert -i "%s"', thisoutputfile);        
            [status,result] = system(strline);


            %% right_okn detection  (will create non-existent path)
            thisoutputdir = fullfile(outputdir, sprintf('%s.rightward',whichEye));         
            strline = sprintf ('okndetector -c "%s" -i "%s" -x "%s" -o "%s" -d %d', configfile, inputfile, overrideString, thisoutputdir, +1);        
            [status,result] = system(strline);
            %disp(strline); 

            thisoutputfile = fullerfile (thisoutputdir, 'result.json');            
            strline = sprintf ('oknconvert -i "%s"', thisoutputfile);        
            [status,result] = system(strline);
            
            
        elseif ((~is_snippets) & (is_tracker_id) & (is_eye)) 
            
            %% Basic configuration for OKNDETECTOR 
            overrideString = getOverrideString (eachTrackerId);
            
            %% left_okn detection (will create non-existent path)
            thisoutputdir = fullfile(outputdir, sprintf('%s.leftward',whichEye));         
            strline = sprintf ('okndetector -c "%s" -i "%s" -x "%s" -o "%s" -d %d', configfile, inputfile, overrideString, thisoutputdir, -1);        
            [status,result] = system(strline);
            
            thisoutputfile = fullerfile (thisoutputdir, 'result.json');
            strline = sprintf ('oknconvert -i "%s"', thisoutputfile);        
            [status,result] = system(strline);
            
            
            %% right_okn detection  (will create non-existent path)
            thisoutputdir = fullfile(outputdir, sprintf('%s.rightward',whichEye));         
            strline = sprintf ('okndetector -c "%s" -i "%s" -x "%s" -o "%s" -d %d', configfile, inputfile, overrideString, thisoutputdir, +1);        
            [status,result] = system(strline);
            %disp(strline); 

            thisoutputfile = fullerfile (thisoutputdir, 'result.json');
            strline = sprintf ('oknconvert -i "%s"', thisoutputfile);        
            [status,result] = system(strline);

            %keyboard;

        elseif ((~is_snippets) & (~is_tracker_id) & (~is_eye)) 
            
            %% Basic configuration for OKNDETECTOR 
            

            %% left_okn detection  (will create non-existent path)
            thisoutputdir = fullfile(outputdir, 'leftward');         
            strline = sprintf ('okndetector -c "%s" -i "%s" -o "%s" -d %d', configfile, inputfile, thisoutputdir, -1);        
            [status,result] = system(strline);
            
            thisoutputfile = fullerfile (thisoutputdir, 'result.json');
            strline = sprintf ('oknconvert -i "%s"', thisoutputfile);        
            [status,result] = system(strline);


            
            %% right_okn detection  (will create non-existent path)
            thisoutputdir = fullfile(outputdir, 'rightward');         
            strline = sprintf ('okndetector -c "%s" -i "%s" -o "%s" -d %d', configfile, inputfile, thisoutputdir, +1);        
            [status,result] = system(strline);
            %disp(strline);       
            
            thisoutputfile = fullerfile (thisoutputdir, 'result.json');
            strline = sprintf ('oknconvert -i "%s"', thisoutputfile);        
            [status,result] = system(strline);

            
        else 
            
            error ('This is an unknown combination.')
            
        end
        
        %% Percent Information 
        percent_progress = floor(100*(k/K));
        textprogressbar(percent_progress);         
            
        
        %rlog ('rlog','updater','%d.\tconfig = %s\n', d.item, configfile);
        %rlog ('rlog','updater','\tinput  = %s\n', inputfile);
        %rlog ('rlog','updater','\toutput = %s\n', outputfile);

        
        %% build individual tables
        %total_table = [ total_table ; eachTbl ];
        
  end
  
%end


textprogressbar(100);
textprogressbar('done');    
        

%% OutputCOPY RESULT FILE 
%writetable(total_table, outputfile);

    
end


%% getOverrideString 

function overrideString = getOverrideString (eachTrackerId, snippetObj) 


    if (nargin == 2)

        %% inputStr       = setup.snippet.(whichCol);
        JsonStr = savejson([], snippetObj, 'Filename', []);
        JsonStr = strrep(JsonStr,'"','\"');
        JsonStr = strrep(JsonStr,' ','');

        overrideString = sprintf('{\\"remapper\\" : { \\"filter\\" : \\"Number(record.TrackerId)==%d\\" }, \\"input\\" : %s }', eachTrackerId, JsonStr);            
        % overrideString = sprintf('{\\"remapper\\" : { \\"filter\\" : \\"Number(record.TrackerId)==%d\\" } }', eachTrackerId);    

    else
        overrideString = sprintf('{\\"remapper\\" : { \\"filter\\" : \\"Number(record.TrackerId)==%d\\" }}', eachTrackerId);                    
    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILTER DISPATCHER  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% dispatch function 

function y = dispatch_function  (this_filter, y, extra)


    %global gbl_log;

    switch (this_filter.function)

        case { 'cdp_direction' }
            
            %% create the direction mask               
            t = y.(this_filter.input);            
            [p,basename,ext] = fileparts (extra.inputfile);            
            [~,keyname,~] = fileparts(p);

                        
            f = cdp_direction (extra.log, keyname,t);            
            %f = steps2mask (t, logItem.direction);            
            
            %% add this information             
            y.(this_filter.output) = f; 
            %fprintf ('OK\n');
        
        
        case { 'passthrough' }
            
            f = y.(this_filter.input);
            y.(this_filter.output) = f; 
            %fprintf ('OK\n');
        
        case { 'dshift' }

            f = y.(this_filter.input{1});
            %n = this_filter.value;                        
            y.(this_filter.output) = dshift (f);
            %fprintf ('OK\n');
            
        case { 'tidy' }

            f = y.(this_filter.input{1});
            n = this_filter.value;
            thicken = this_filter.thicken;
                        
            is_tracking = y.(this_filter.input{2});
            y.(this_filter.output) = tidy (f, n, thicken, ~is_tracking);
            %fprintf ('OK\n');

        case { 'wavelet' }

            f = y.(this_filter.input{1});        
            
            if (all(isnan(f)))
                %fprintf ('OK\n');
                y.(this_filter.output) = f;
                return
            end
            
            levelForReconstruction = cell2mat(this_filter.levelForReconstruction);
            waveletType = this_filter.type;
            level = this_filter.Level;
            y.(this_filter.output) = waveleter (f, levelForReconstruction, waveletType, level);
            %fprintf ('OK\n');
                        
        case { 'deblinker' }

            f = y.(this_filter.input{1});
            is_blinking = y.(this_filter.input{2});
            y.(this_filter.output) = deblinker (f, is_blinking);
            %fprintf ('OK\n');

        case { 'shiftSignal' }
 
            f = y.(this_filter.input{1});            
            y.(this_filter.output) = shiftSignal (f);
            
            
        case { 'signalReset' }
 
            f = y.(this_filter.input{1});            
            y.(this_filter.output) = signalReset (f);
            
        case { 'medianFilter' }
 
            f = y.(this_filter.input{1});            
            n = this_filter.npoint;
            y.(this_filter.output) = medfilt1 (f, n); 
            
        case { 'applymask' }

            f = y.(this_filter.input{1});
            is_mask = y.(this_filter.input{2});
            
            %% reverse the mask 
            if (isfield(this_filter, 'reverse'))            
                if (this_filter.reverse)
                    is_mask = ~is_mask;
                end 
            end 
            
            y.(this_filter.output) = applymask (f, is_mask);
            %fprintf ('OK\n');
            
        case { 'detrender' }

            f = y.(this_filter.input{2});
            t = y.(this_filter.input{1});
            poly_order   = this_filter.polyorder;
            min_duration = this_filter.min_duration;
            y.(this_filter.output) = detrender (t, f, poly_order, min_duration);
            %fprintf ('OK\n');

        case { 'gradient' }

            f = y.(this_filter.input{2});
            t = y.(this_filter.input{1});
            y.(this_filter.output) = grad (f, t);
            %fprintf ('OK\n');
            
        otherwise            
            error ('NOT FOUND\n');
            
            
    end

    
    %% POST CHECK 
    %f = y.(this_filter.output);
    %if (all(isnan(f)))
    %    warning ('All outputs were NAN');
    %end
    %pause;
end



function x11 = waveleter (x, levelForReconstruction, waveletType, level)


[x1, i] = fillmissing(x, 'nearest');

% Decompose Signal using the MODWT
% Generated by MATLAB(R) 9.9 and Wavelet Toolbox 5.5.
% Generated on: 21-Feb-2021 21:57:56
% Logical array for selecting reconstruction elements
levelForReconstruction = logical(levelForReconstruction); %[false, false, true, true, true];

% Perform the decomposition using modwt
wt = modwt(x1, waveletType, level);
% Construct MRA matrix using modwtmra
mra = modwtmra(wt, waveletType);
% Sum along selected multiresolution signals
x11 = sum(mra(levelForReconstruction,:),1);

x11(i) = nan;
x11 = x11(:);
end



%% correlation based blink removal 
function f = deblinker2 (f, x, y, th)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Deblinking velocity signal 
    %
    %  s = x*y
    %
    %  s < th   (valid) 
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% expand and connect small regions       
    s = x.*y;
    i = (s > th);
    f(i) = nan;

end


%% remove blinks 
function f = applymask (f, is_mask)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Set Masked points to NaN 
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    chk = isnan(is_mask);
    if (any(chk))
        is_mask(chk) = true;
    end
    
    f(logical(is_mask)) = nan;

end


%% remove blinks 
function f = deblinker (f, is_blinking)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Blinker replacing 
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    chk = isnan(is_blinking);
    if (any(chk))
        is_blinking(chk) = true;
    end
    
    f(logical(is_blinking)) = nan;

end

function f = medianfilter (f, npoint)

        %% median filter and signal reset
        f = medfilt1(f, npoint(3));

end 


%% tidy - adds nans and medfilter
function f = tidy (f, npoint, n_thicken, is_deleted)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % n_point is [ front/back, mask, median filter, expand times ]
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% put nans at the START and END  
        f(is_deleted) = nan;
        f = cleanSignal(f, npoint(1));  
        
        %% expand and connect small regions   
        mask = isnan (f);
        
        %% Widen any Masked Information         
        for k = 1:n_thicken
            mask = logical(conv(mask, logical([ 1 1 1 ]), 'same'));
        end
                
        %% Fill in borders                  
        mask = imfill(mask, [ npoint(2) 1  ]);
        f(mask) = nan;
        
        %% median filter and signal reset
        f = medfilt1(f, npoint(3));
        
        
end


function f1 =  dshift (f)

    %% shift to median
    y  = median(f, 'omitnan');
    f1 = f - y;
    
end


function dfdt = grad (f, t)

        %% ignore first 10 samples and last 10 samples  
        df  = gradient (f);
        dt  = gradient(t);
        dfdt = df./dt;
end


function y = cdp_direction (logs, fname, t)

    y = t*0;
    M = length (logs);
    for k = 1:M

        %% Ignore non-"Disks"        
        if (isstruct(logs))
            each_log = logs(k);
        else
            each_log = logs{k};
        end
        
        %% ignore non-disk trials
        is_name = (~strcmp(each_log.trial_type, 'Disk') || ~contains(each_log.filename, fname));
        if (is_name)
            continue;
        end

        %% information 
        if (~isfield(each_log, 'direction'))                       
            return
        end
        
        %% Process "Disk" fields    
        %i =  ((each_log.start_time <= t) & (t <= each_log.end_time));         
        switch (each_log.direction)        
            case { 'left' } 
                d = +1;
            case { 'right' } 
                d = -1;
            otherwise
                error ('different.');
        end
        y = t*0 + d; 
        return
    end

end


%{ 
function [fX, fY, dfXdt, dfYdt] = update_signal (y0, which_x_field, which_y_field, filter)

    
        which_time_field = 'currentTime';
    
        t = y0.(which_time_field);
        
        %% ignore first 10 samples and last 10 samples  
        N  = 10;
        fX = cleanSignal(y0.finalX, N);
        fY = cleanSignal(y0.finalY, N);
        
        %% Add a raw derivative column 
        %dfXdt_raw = gradient(fX)./gradient(t);
        %dfYdt_raw = gradient(fY)./gradient(t);        
        %y.final_dXdt(rows) = dfXdt_raw; 
        %y.final_dYdt(rows) = dfYdt_raw; 
                
        %% do updates (OPENFACE) fill it in 
        [fX, tfX] = fillmissing(fX, 'linear','SamplePoints', t);
        [fY, tfY] = fillmissing(fY, 'linear','SamplePoints', t);
        
                      
        %% apply the specified filter 
        [fX, fY] = feval(filter, fX, fY);
                
        %% PUT MISSING DATA BACK
        fX(tfX) = nan; fX = fX(:);
        fY(tfY) = nan; fY = fY(:);

        %% NUMERICAL GRADIENTS        
        dfXdt = gradient(fX)./gradient(t);
        dfYdt = gradient(fY)./gradient(t);
                       
        %% RESET SIGNAL ON MAIN SIGNAL 
        fX = signalReset(fX);
        fY = signalReset(fY);
               

end
%}

function f1 = detrender (t, f, poly_order, min_duration)


    %% create regions 
    labels = ~isnan(f);
    bp     = diff(labels);
    bp_start = find (bp > 0) + 1;
    bp_end   = find (bp < 0);

    if (isfinite(f(1)))
        bp_start = [ 1 ; bp_start ];
    end

    if (isfinite(f(end)))
        bp_end = [ bp_end ; length(f) ];
    end


    %% time regions 

    f1 = nan*f;

    M = length(bp_start);
    for k = 1:M

        t_start = t(bp_start(k));    
        t_end   = t(bp_end(k));

        t_duration = t_end - t_start;
        if  (t_duration > min_duration)  %% only keep regions greater than 1 second

            %% show detrended 
            t0 = t(bp_start(k):bp_end(k));
            x0 = f(bp_start(k):bp_end(k));
            x1 = detrend (x0, poly_order, 'omitnan');

            %% detrended 
            f1(bp_start(k):bp_end(k)) = x1 - x1(1); 

        end 

    end
end
