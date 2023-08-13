function batch_sweep_webcam_reporter (main_dir, varargin)

% BATCH_SWEEP_WEBCAM_REPORTER Batch analysis of webcam FILES for reporting
%
%   batch_sweep_webcam_reporter (main_dir, which_fn, varargin)
%
%

p = inputParser ();
p.addOptional ('dryrun', false);
p.addOptional ('reporter_manifest', 'reporter.csv');
p.addOptional ('testrun', false);
p.parse(varargin{:});
result = p.Results;


%% read the setup configuration file 
%setups = load_commented_json (fullerfile(main_dir, 'config/setup.config'));   
%profile = getprofile (setups, which_profile);   
%if (isempty(profile))
%  error (sprintf('Invalid profile requested ... %s', which_profile));
%end

%% participant level information 

d.main_dir      = main_dir;
d.overallresult = fullfile (d.main_dir, "result");
createdirectory (d.overallresult);


%% read the manifest FILE 
reporterfile = fullerfile (main_dir, result.reporter_manifest);
inputTbl = readtable(reporterfile, 'delim',','); % log.filename;


%% for each importfile perform the following   
%
%   ignored files have been removed 
%

%clear textprogressbar;
%textprogressbar ('reporting    ');

close all;

eye_code_list = unique (inputTbl.eye_code);
M = length (eye_code_list);
for k = 1:M
    
   %textprogressbar (floor(k/M*100));
   
   %% Information 
   eye_code = eye_code_list{k};   

   i = ismember (inputTbl.eye_code, eye_code);
   thisTbl = inputTbl(i,:);   
   if (size(thisTbl,1) ~= 2)
        error ('Sweep not compatiable!');
   end 


   %% down_sweep 
 
   VA_info = get_bidrectional_VA (thisTbl, d, eye_code);

    output_VA_info(k) = VA_info;

   %% Setup paths for individual files   
   
   %[each_path, each_name, ~] = fileparts (eachfile);           
   %cliplesspath = fileparts (each_path);
   %
   %
   %d.runpath          = fullerfile (main_dir, each_path, each_name);
   d.participantpath    = fullerfile (main_dir, eye_code);   
   d.resultpath         = fullerfile (d.participantpath, 'result');  
   d.sweepfigurespath   = fullerfile (d.resultpath, 'figures');        
   
   %d.videofile        = fullerfile (main_dir, eachfile);   
   %d.clipspath        = fullerfile(d.main_dir, each_path);   
   %d.openfacepath     = fullerfile (d.resultpath, 'openface', each_name);   
   %d.eyetrackpath     = fullerfile (d.resultpath, 'eyetrack', each_name);  
   %d.oknpath          = fullerfile (d.resultpath, 'okn', each_name);        
   %d.flowpath         = fullerfile (d.resultpath, 'flow');            
   % presentation_sweep_visualizer (d, result, setups)

   % inputTbl(k,:)

   presentation_bisweep_visualizer (thisTbl, d, eye_code, VA_info, "okn");
   % presentation_bisweep_visualizer (thisTbl, d, eye_code, VA_info, "keypress");

end

%% ready to output a final table 

VAinfo_tbl = struct2tableAll(output_VA_info);

fprintf ('Automated VA result.\n');
for k = 1:length (output_VA_info)
    this_code = output_VA_info (k);
    printout_result (this_code.eye_code, this_code.okn)

end

fprintf ('Keypress VA result.\n');
for k = 1:length (output_VA_info)
    this_code = output_VA_info (k);
    printout_result (this_code.eye_code, this_code.keypress)
end


%% finish
%textprogressbar (100);
%textprogressbar ('done.');

writetable (VAinfo_tbl, fullfile(d.overallresult, "VA.csv"));


end


function myinfo = get_bidrectional_VA (thisTbl, d, eye_code)


 %% this eye code 
 %i = ismember (inputTbl.eye_code, eye_code);
 %thisTbl = inputTbl(i,:);   
 %if (size(thisTbl,1) ~= 2)
 %   error ('Sweep not compatiable!');
 %end 

f3 = false;

 %% get down sweep 
 i = ismember(thisTbl.sweep_direction, "right_down");
 downTbl = thisTbl(i,:);
    
 downDir = sprintf ('result/okn/%s/%s/', downTbl.clip_direction{1}, downTbl.type{1});
 d.descending.dir = fullfile(d.main_dir, eye_code, downDir);
 fileVA = fullfile(d.descending.dir, "VA.json");
 VAinfo = loadjson(fileVA);

 thiseyeinfo = VAinfo.(downTbl.eye{1}).(downTbl.okn_direction{1}); 
 v1 = thiseyeinfo.VA;
 t1 = thiseyeinfo.t;
 f1 = thiseyeinfo.found_activity;
 if (isempty(v1) | ~f1)
     v1 = NaN;
 end

 if (isfield(VAinfo, 'keypress'))
    k1VA = VAinfo.keypress.VA; 
    k1t  = VAinfo.keypress.t; 
    f3   = true;
 else 
    k1VA = NaN;
    k1t  = NaN;
    f3 = false;
 end
 
 %% get up sweep  
 i = ismember(thisTbl.sweep_direction, "right_up");
 upTbl = thisTbl(i,:);

 upDir = sprintf ('result/okn/%s/%s/', upTbl.clip_direction{1}, upTbl.type{1});
 d.ascending.dir = fullfile(d.main_dir, eye_code, upDir);
 fileVA = fullfile(d.ascending.dir, "VA.json");
 VAinfo = loadjson(fileVA);
 %t0 = VAinfo.(upTbl.eye).(upTbl.okn_direction).t;
 
 thiseyeinfo = VAinfo.(upTbl.eye{1}).(upTbl.okn_direction{1}); 
 v2 = thiseyeinfo.VA;
 t2 = thiseyeinfo.t; 
 f2 = thiseyeinfo.found_activity;
 if (isempty(v2) | ~f2)
     v2 = NaN;
 end

 if (isfield(VAinfo, 'keypress'))
    k2VA = VAinfo.keypress.VA; 
    k2t  = VAinfo.keypress.t; 
    f4 = true;

 else
    k2VA = NaN;
    k2t  = NaN;     
    f4 = false;
 end

  
 %% get overall VA summary    

 myinfo.eye_code     = eye_code;
 myinfo.okn.down_VA  = v1;
 myinfo.okn.down_t   = t1;
 myinfo.okn.up_VA    = v2;
 myinfo.okn.up_t     = t2; 
 myinfo.okn.found_VA = f1 & f2; 
 myinfo.okn.VA       = (v1+v2)/2;
 myinfo.keypress.found_VA = f3 & f4;
 myinfo.keypress.VA       = (k1VA+k2VA)/2;
 myinfo.keypress.down_t   = k1t;
 myinfo.keypress.down_VA  = k1VA;
 myinfo.keypress.up_t     = k2t; 
 myinfo.keypress.up_VA    = k2VA;
  

 %% stringify the output 
 % printout_result (eye_code, myinfo.okn); %% standard 



end

function printout_result (eye_code, info)

 v1 = info.down_VA;
 v2 = info.up_VA;
 v3 = info.VA;
 
 dv = abs(v1-v2);

 if (isnan(v2))
      v2_str = '---';
 else
     v2_str = sprintf('%4.2f', v2);
 end

 if (isnan(v1))
      v1_str = '---';
 else
      v1_str = sprintf('%4.2f', v1);
 end

 if (isnan(v3))
      v3_str = '---';
 else
      v3_str = sprintf('%4.2f', v3);
 end

 %% Show VA result for analysis  
 fprintf ('Name:%s VA↓:%s, VA↑:%s, mean VA:%s logMAR ', eye_code, v1_str, v2_str, v3_str);
 if (dv >=0.3)
     fprintf ('[%s]\n',sprintf('Warning: VAs exceed difference threshold (%4.2f). Check data.', abs(dv)));
 elseif (isnan(v1) | isnan (v2))
    fprintf ('[%s]\n','Warning: VA not found. Check data.');
 else
     fprintf ('[%s]\n','OK');
 end


end


%% PRESENTATION SWEEP VISUALIZER 
function presentation_bisweep_visualizer (thisTbl, d, eye_code, VAinfo, which_VA)
  

figure; clf;

%% RIGHT DOWN SWEEP 

i = ismember(thisTbl.sweep_direction, "right_down");
downTbl = thisTbl(i,:);
downDir = sprintf ('result/okn/%s/%s/', downTbl.clip_direction{1}, downTbl.type{1});
d.descending.dir = fullfile(d.main_dir, eye_code, downDir);
okn_string = sprintf ('%s.%s', downTbl.eye{1}, downTbl.okn_direction{1});
okn_sweep_direction = downTbl.sweep_direction{1};


VAokn = VAinfo.(which_VA);

a(1) = subplot (2,1,1);
inputDir = d.descending.dir;
t0 = VAokn.down_t; % OD.rightward.t;

show_webcam_signal_data  (fullfile(inputDir, okn_string,'signal.updated.csv'), okn_sweep_direction, "showTimePoint", t0); 
ylabel ('Displacement');   ylim([-10 10]);
set(gca,'FontSize',22);

if (isfinite(VAokn.down_VA))
    VA_string = sprintf ('VA↓ = %4.2f logMAR', VAokn.down_VA); % OD.rightward.VA);
else
    VA_string = sprintf ('VA↓ not found.', VAokn.down_VA); % OD.rightward.VA);
end



a1 = a(1).Position;
k  = a1(4)/a1(3);
a1(3) = 0.99*a1(3);
a1(4) = 0.95*a1(4);

t = annotation('textbox','String',VA_string,'Position',a1,'Vert','top','HorizontalAlignment', 'right','FitBoxToText','on');

t.FontSize = 22;
t.BackgroundColor = 'w';

%% add labels 

xlabel('');
title (sprintf('%s [%s]',eye_code, which_VA), 'Interpreter', 'none');


%% RIGHT UP SWEEP 


i = ismember(thisTbl.sweep_direction, "right_up");
upTbl = thisTbl(i,:);
upDir = sprintf ('result/okn/%s/%s/', upTbl.clip_direction{1}, upTbl.type{1});
d.ascending.dir = fullfile(d.main_dir, eye_code, upDir);
okn_string = sprintf ('%s.%s', upTbl.eye{1}, upTbl.okn_direction{1});
okn_sweep_direction = upTbl.sweep_direction{1};


a(2) = subplot (2,1,2);
inputDir = d.ascending.dir; 
t0 = VAokn.up_t; % OD.rightward.t;

show_webcam_signal_data  (fullfile(inputDir, okn_string,'signal.updated.csv'), okn_sweep_direction, "showTimePoint", t0); 
set(gca,'FontSize',22); ylim([-10 10]);

if (isfinite(VAokn.up_VA))
    VA_string = sprintf ('VA↑ = %4.2f logMAR', VAokn.up_VA); % OD.rightward.VA);
else
    VA_string = sprintf ('VA↑ not found.', VAokn.up_VA); % OD.rightward.VA);
end


a1 = a(2).Position;
k  = a1(4)/a1(3);
a1(3) = 0.99*a1(3);
a1(4) = 0.95*a1(4);

t = annotation('textbox','String',VA_string,'Position',a1,'Vert','top','HorizontalAlignment', 'right', 'FitBoxToText','on');

t.FontSize = 22;
t.BackgroundColor = 'w';

if (VAokn.found_VA)

    %% back into the first SWEEP 
    VA_string = sprintf ('mean VA = %4.2f logMAR', VAokn.VA);

else

    VA_string = 'Couldnt get mean VA'; % sprintf ('mean VA = %4.2f logMAR', VA_mean);
end

axes (a(1));

a1 = a(1).Position;
k  = a1(4)/a1(3);
a1(1) = 1.05*a1(1);
a1(2) = 0.975*a1(2);

t = annotation('textbox','String',VA_string,'Position',a1,'Vert','top','HorizontalAlignment', 'left','FitBoxToText','on');
t.FontSize = 22;
t.BackgroundColor = 'w';

f = gcf;
f.Position =  [ 4         562        1400         500 ];

%% PRINT THE RESULTS 

outputdir = fullfile(d.sweepfigurespath, which_VA);
createdirectory (outputdir);
savefig (fullfile(outputdir, 'sweep.fig'));
exportgraphics (gcf,fullfile(outputdir, 'sweep.png'));

end




%% READEVENTS

function event = readevents (eventlist)
 count = 1;
 M = length (eventlist);
 for k = 1:M
    try 
     event{count} = loadjson (eventlist{k});
     count = count + 1;
    catch ME 
    end
 end
end



%% GETPROFILE 

function y = getprofile (setups, which_profile)
    y = [];
    profiles = setups.Profiles;
    if (isfield(profiles, which_profile))
        y = profiles.(which_profile);        
    end    
end


%% GET STANDARD NAME 

function strf = get_standard_name (each_presentation)

    switch (each_presentation.type)
        
        case { 'fixation' }
            
            strf = sprintf('clip-%d-%s-%s.csv', each_presentation.number, each_presentation.id, each_presentation.data.type);

        case { 'disks' }
            
            strf = sprintf('clip-%d-%s-%s.csv', each_presentation.number, each_presentation.ref_id, each_presentation.data.type);
            
        otherwise
            error ('this error.');
    end
    
       
end

