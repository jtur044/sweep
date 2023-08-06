function run_updater (config, inputfile, outputfile, varargin)

% RUN_UPDATER Generate updated signals 
%
%   run_updater (configfile|config, inputfile, outputfile, varargin)
%
% where 
%       configfile | config is the location of the configuration file 
%                           or the config object
%       inputfile           is the input data .CSV file (e.g., results.csv) 
%       outputfile          is the updated data file (e.g., results.updated.csv)
%
%
% see 
%       run_updater.m 
%
% EXAMPLE 
%
%   configfile = './DATA/BROOKS.PROCESSED/kj_4_18_23/config/eyetracker.webcam-brooks.json';
%   inputfile  = './DATA/BROOKS.PROCESSED/kj_4_18_23/result/eyetracker/results.csv';
%   outputfile = './DATA/BROOKS.PROCESSED/kj_4_18_23/result/eyetracker/results.updated.csv';
%   run_updater (configfile, inputfile, outputfile)
%


p = inputParser ();
p.addOptional ('ProgressTitle', 'updating');
p.parse(varargin{:});
res = p.Results;


%% load configuration file 

if (ischar(config)| isstring(config))
    config  = load_commented_json (config); %% default 
end

if (ischar(inputfile) | isstring(inputfile))
   dataTbl  = readtable (inputfile); 
end


%%  SETUP Basic Information 

% cdp_timeline = fullfile (each_path, each_name, 'steps.json');
[each_path, each_name, ~] = fileparts (inputfile);        


%% extra information 
%extra.logfile    = fullfile (each_path, '../../clips/log.json');
%extra.log        = load_commented_json(extra.logfile);
extra.inputfile  = inputfile;
extra.outputfile = outputfile;
extra.config     = config;

clear textprogressbar;
textprogressbar(sprintf('%s:', res.ProgressTitle));

%% Update each Tracker similarly    
total_table = table();    


is_tracker_column = ismember('TrackerId',dataTbl.Properties.VariableNames);

K = 1;
if (is_tracker_column)
    ids = unique(dataTbl.TrackerId);    
    K = length(ids); 
end

eachTbl = dataTbl;

M = length(config.filters);
counter = 0;
for k = 1:K
    
        %% which rows 
        
        if (is_tracker_column)
            rows = dataTbl.TrackerId == ids(k);
            eachTbl = dataTbl(rows, :);
        end
               
        
        %% run each Filter 
        %M = length(config.filters);

        
        for l = 1:M                    
            each_filter = config.filters{l};         

            % fprintf ('%d. id = %d, function = %s, updated = %s ', l, ids(k), each_filter.function, each_filter.output);                                    
            if (isfield(each_filter, 'Enabled'))            
                if (~each_filter.Enabled)
                    %fprintf ('[Pass]\n');                                            
                    continue;
                end            
            end

            %% Logging 
            
            if (is_tracker_column)
                if (isfield(each_filter,'output'))
                    rlog ('debug', '', '%d. id = %d, function = %s, updated = %s ', l, ids(k), each_filter.function, each_filter.output);            
                else
                    rlog ('debug', '', '%d. id = %d, function = %s, updated = "rows"', l, ids(k), each_filter.function);                                
                end                
            else                
                if (isfield(each_filter,'output'))
                    rlog ('debug', '', '%d. function = %s, updated = %s ', l, each_filter.function, each_filter.output);
                else
                    rlog ('debug', '', '%d. function = %s, updated = "rows" ', l, each_filter.function);                    
                end
            end
            
            %% Run the function 
            
            eachTbl = dispatch_function (each_filter, eachTbl, extra);   

            percent_progress = floor(100*(counter/(K*M)));
            textprogressbar(percent_progress);            
            counter = counter + 1;
        end
        
        
        
        %% build individual tables
        total_table = [ total_table ; eachTbl ];
        
end
    

textprogressbar(100);
textprogressbar('done');    
        

%% OutputCOPY RESULT FILE 
writetable(total_table, outputfile);

    
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

        case { 'reduce' }
            
            M = size(y, 1);
            t = (1:2:M).';
            y = y(t,:);
            return
            
            
        case { 'dwnsample' }
            
            t = y.(this_filter.input);
            n = this_filter.target_samplerate;  % target sample rate 
                        
            dT = mean(diff(t), 'omitnan');
            T  = 1/dT;                  % main sample rate 
            r  = log2(floor(T/n));      % reductions 

            fprintf ('Target samplerate       = %4.3f\n', n);
            fprintf ('Estiametd samplerate    = %4.3f\n', T);
            fprintf ('Approximated reductions = %4.3f\n', r);
            
            if (r == 0)
                return
            end
            
            p =  dwnsample (size(y,1), r);            
            y = y(p,:);

        case { 'detectblinkv' } 
            
            x1 = y.(this_filter.input{1});
            x2 = y.(this_filter.input{2});            
            x1 = medfilt1 (x1, 3);
            x2 = medfilt1 (x2, 3);

            yyaxis left; plot (x1);
            yyaxis right; plot (x2);
            
            %[maxtab, mintab] = peakdet(x1, 0.1*th);
            
            
            disp ('here.');
            
            % [t, V, maxtab] = detectblinkv (t, V, fps, varargin)

            
        case { 'deblinker2' } 

            x0 = y.(this_filter.input{1});
            y0 = y.(this_filter.input{2});
            th = this_filter.threshold;
            
            i = deblinker2 (x0, y0, th);
            y.(this_filter.output) = i;
                        
        
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

        case { 'spikeRemover' }

            f = y.(this_filter.input{1});
            is_blinking = y.(this_filter.input{2});
            y.(this_filter.output) = spikeRemover (f, is_blinking);
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

function spikeRemover (f)

%% remove an



end


%% detect blink using the displacement signal

function [t, V, maxtab] = xdetectblink (x1, V, fps, varargin)

p = inputParser ();
p.addOptional ('blink_duration', 0.5);
p.addOptional ('blink_threshold', 1);
p.parse(varargin{:});
res = p.Results;
th  = res.blink_threshold;
T   = res.blink_duration;


[maxtab, mintab] = peakdet(x1, 0.1*th);



%% time constant 
%t = ((1:length(V))-1) / fps;

%% detect Blink Like features 
sigma = T/5;  %% 5 standard 
t0  = linspace(-T/2,T/2,T*fps); 
f   = wavepacket (t0,T,sigma);

%% The correlation 
[c0, lags] = xcorr (V, f);
i  = (lags >= 0);
c  = c0(i);

%% Maxima correspond to peaks 
%
% this is from "eyetrack/extra/peakdet.m"
[maxtab, mintab] = peakdet(V, 0.1*th);

i = mintab(:,2) < -th;
mintab = mintab(i,:);
t = t(mintab(:,1));
V = V(mintab(:,1));

end




function [t, V, maxtab] = detectblinkv (t, V, fps, varargin)


p = inputParser ();
p.addOptional ('blink_duration', 0.5);
p.addOptional ('blink_threshold', 1);
p.parse(varargin{:});
res = p.Results;
th  = res.blink_threshold;
T   = res.blink_duration;

%% time constant 
%t = ((1:length(V))-1) / fps;

%% detect Blink Like features 
sigma = T/5;  %% 5 standard 
t0  = linspace(-T/2,T/2,T*fps); 
f   = wavepacket (t0,T,sigma);

%% The correlation 
[c0, lags] = xcorr (V, f);
i  = (lags >= 0);
c  = c0(i);

%% Maxima correspond to peaks 
%
% this is from "eyetrack/extra/peakdet.m"
[maxtab, mintab] = peakdet(V, 0.1*th);

i = mintab(:,2) < -th;
mintab = mintab(i,:);
t = t(mintab(:,1));
V = V(mintab(:,1));

end



function f = dwnsample (M, N)

    f = 1:M.';
    F = size(f,1);    
    for k = 1:N    
        f = f(1:2:F', :);    
    end

    
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
function i = deblinker2 (x, y, th)

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
