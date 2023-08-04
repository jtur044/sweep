function batch_webcam_processor (main_dir, which_profile, varargin)

% BATCH_WEBCAM_PROCESSOR Batch analysis of webcam FILES 
%
%   batch_webcam_processor (main_dir, which_fn, varargin)
%
% where 
%
%       main_dir    is the main directory 
%       which_fn    is OpenFace | VideoSplitter | EyeTracker | 
%                      Updater | Okndetector | All
%       
% assumes 
%          config/setup.config 
%

p = inputParser ();
p.addOptional ('dryrun', false);
p.addOptional ('manifest', 'manifest.txt');
p.addOptional ('testrun', false);
p.parse(varargin{:});
result = p.Results;


%% read the setup configuration file 
setups = load_commented_json (fullerfile(main_dir, 'config/setup.config'));   
profile = getprofile (setups, which_profile);   
if (isempty(profile))
  error (sprintf('Invalid profile requested ... %s', which_profile));
end


%% participant level information 
d.main_dir     = main_dir;
%d.protocolfile  = fullerfile (main_dir, 'protocol.simpler.csv');
%try 
%    log = readtable (d.protocolfile);   
%catch ME 
%     error ('WARNING : no protocol file found ... %s\n', d.protocolfile);
%end 


%% read the manifest FILE 
importfiles = {}; count = 1;
manifestfile = fullerfile (main_dir, result.manifest);
totalfiles = importdata(manifestfile); % log.filename;
for k = 1:length (totalfiles)
    eachfile = totalfiles{k};
    if (strcmp(eachfile(1),'#'))
       continue;
    end       

    importfiles {count} = eachfile;
    count = count + 1;    
end

fprintf ('Total files read ... %d\n', length(importfiles));


%% read the ignore FILE 
%{
ignore_count   = 1;
ignore_strings = {};
ignore_flag  = false;
ignorefile = fullerfile (main_dir, 'ignore.txt');
if (exist(ignorefile, 'file'))
    temp = importdata (ignorefile);
    for k = 1:length (temp)        
       eachfile = temp{k};
       if (strcmp(eachfile(1),'#'))
            continue;
       end       
       ignore_strings{ignore_count} = temp{k};
       ignore_count = ignore_count + 1;
    end    
        
    i = contains (importfiles, ignore_strings);
    fprintf ('Total ignore files ... %d\n', sum(i));    
    importfiles = importfiles(~i);
end
%}


fprintf ('Total processing files ... %d\n', length(importfiles));


%% for each importfile perform the following   
%
%   ignored files have been removed 
%


% clear textprogressbar;
% textprogressbar ('analysis    ');

M = length (importfiles);
for k = 1:M
    
    
   %textprogressbar (floor(k/M*100));
   
   eachfile = importfiles{k};   
       
   %% ignore '#' files in manifest.txt 
   % if (strcmp(eachfile(1),'#'))
   %     continue;
   % end
      
   %% Setup paths for individual files   
   [each_path, each_name, ~] = fileparts (eachfile);         
   d.runpath      = fullerfile (main_dir, each_path, each_name);
   d.videofile    = fullerfile (main_dir, eachfile);    
   d.clipspath    = fullerfile(d.main_dir, each_path);   
   d.openfacepath  = fullerfile (d.runpath,   'openface');   
   d.resultpath    = fullerfile (d.runpath,   'result');  
   d.oknpath       = fullerfile (d.runpath,   'okn');     
   d.flowpath      = fullerfile (d.runpath,   'flow');        
   d.participantpath  = fullerfile (main_dir, each_path);   
  
   
   %% Make these directories if they don't exist    
   createdirectory (d.main_dir);
   createdirectory (d.runpath);   
   createdirectory (d.openfacepath);
   createdirectory (d.resultpath);
   createdirectory (d.participantpath);   
   createdirectory (d.oknpath);   
   createdirectory (d.flowpath);
   
   
   %% To CORRECTLY run UPDATER 
   %   
   %       configfile is the location of the configuration file 
   %       inputfile  is the input data .CSV file (results.csv) 
   %       outputfile is the updated data file (results.updated.csv)
   %

      
   %% Analyze EACH INDIVIDUAL CLIP     
   %L = size (log, 1);   
   %for l = 1:L
   
   
      %% Load the appropriate trial parameters  
      % i = contains (log.filename, each_name);       
      % if (any(i))
      %    each_presentation = log(i,:);                      
      %    if (size(each_presentation,1) ~= 1 )
      %       error ('Inconsistent!');                
      %    end                    
      %    each_presentation.filename = each_presentation.filename{1};          
      % else
      %    continue; 
      % end
              
      % d.item = each_presentation.Number;

       each_presentation.filename = eachfile;
       
       
       %% each presentation - openface
       if (profile.openface)
        presentation_openface (each_presentation, d, result, setups);
       end
       
       %% each presentation / video
       if (profile.eyetracker)
        presentation_eyetracker (each_presentation, d, result);
       end
                 
       %% create a FlowAlyzer on the entire "RIGHT" video    
       if (profile.flowalyzer)
           presentation_flowalyzer (each_presentation, d, result);
       end
       
       %% each presentation / updater
       if (profile.updater)
        presentation_updater (each_presentation, d, result);
       end
       
       %% each presentation / okndetecor
       if (profile.okndetector)
        presentation_okn (each_presentation, d, result, setups, 'frontface');
       end

       
       %% check if a testrun      
       if (result.testrun)   
            fprintf ('Called a TESTRUN.\n');       
            return
       end
       
   %end
   
    
    
end


%% finish
%textprogressbar (100);
%textprogressbar ('done.');


end


%% PRESENTATION OPENFACE


function presentation_openface (eachItem, d, result, setups)

       

       %% analyze each        
       [~,eachbasename,~] = fileparts (eachItem.filename);
       
       
       if (iscell(eachItem.filename))
           cfilename = eachItem.filename{1};
       else
           cfilename = eachItem.filename;           
       end              
       inputvideo         = fullerfile (d.clipspath, cfilename);
       outputpath        = d.openfacepath; 

       %% Clips
       if (isempty(dir(d.clipspath)))
          fprintf ('WARNING : no CLIPS for  %s\n', inputvideo);            
          return
       end

       
       %, eachbasename, strcat(eachbasename, '.csv'));
       %configfile   = fullerfile (d.main_dir, 'eyetracker.json');       
       %outputpath   = fullerfile (d.resultpath, eachbasename); %%, 'results.csv');
       
       %% run openface
       
       if (ismac())
       
           %% Mac version
           %setups = load_commented_json (d.setupfile);

           oldcd = cd();   
           try 
             cd(setups.directories.openface.bin);        
             
             %% Absolute or relative 
             
             if (startsWith(inputvideo,'.'))             
                inputvideo = fullerfile(oldcd, inputvideo);
                outputpath = fullerfile(oldcd, outputpath);   
             elseif (startsWith(inputvideo,'/'))
                inputvideo = fullerfile(inputvideo);
                outputpath = fullerfile(outputpath);   
             else
                error ('Needs to SPECIFIED as relative or absolute');
             end
             
             cmd_str = sprintf('./example.sh "%s" "%s"', inputvideo, outputpath); 
             
             %% Execute 
             
             disp (cmd_str);             
             if (~result.dryrun)
                system(cmd_str);
             end
      
           catch ME
               cd(oldcd);
               fprintf ('Error processing OPENFACE');
               throw (ME);
           end
           cd(oldcd);

       elseif (ispc())
            
            %% PC              
            inputvideo = strrep(inputvideo, '\','/');
            outputpath = strrep(outputpath, '\','/');            
            cmd_str = sprintf('example.sh "%s" "%s"', inputvideo, outputpath);             

            %% EXECUTE            
            disp (cmd_str);            
            if (~result.dryrun)
                system(cmd_str);
            end
       else
           
           error ('OpenFace ERROR');
            
       end

       %% TRY INFORMATION 
       %fprintf(cmd_str);      
       %system(cmd_str);                    
       %fprintf ('%d.  \tconfig = %s\n', d.item, configfile);
       %fprintf ('%d.\tinput    = %s\n', d.item, inputvideo);
       fprintf ('\topenface = %s\n', outputpath);

end


%% PRESENTATION EYETRACKER 


function presentation_eyetracker (eachItem, d, result)

       %% analyze each 
       
       [~,eachbasename,~] = fileparts (eachItem.filename);
              
       videofile    = fullerfile (d.clipspath, eachItem.filename);
       openfacefile = fullerfile (d.openfacepath, eachbasename, strcat(eachbasename, '.csv'));
       configfile   = fullerfile (d.main_dir, 'eyetracker.json');       
       outputpath   = fullerfile (d.resultpath, eachbasename); %%, 'results.csv');
       logfile      = fullerfile (outputpath, 'output.log');
       
       if (~exist(openfacefile, 'file'))
            fprintf ('WARNING: No OpenFace ...%s\n', openfacefile);
            return
       end
             
       
       %% EXECUTE                         
       if (~result.dryrun)
            if (exist(logfile, 'file'))
                delete (logfile);
            else                
                createdirectory(outputpath);
            end
            
            %% generate a log file
            rlog (logfile);                               
            config = load_hierarchy(d.clipspath, d.main_dir, 'eyetracker.json');                        
            run_of_tracker (config, videofile, openfacefile, outputpath); %, 'OverWrite', true);      
       else 
           %fprintf ('analyzing ... %s\n', videofile);
       end
       
end




%% PRESENTATION UPDATER 


function presentation_updater (eachItem, d, result)

       %% analyze each 
       [eachdir, eachbasename, ~] = fileparts(fullerfile (d.resultpath, eachItem.filename));       
       inputfile  = fullerfile (eachdir, eachbasename, 'results.patched.csv');
       outputfile = fullerfile (eachdir, eachbasename, 'results.updated.csv');
       configfile = fullerfile (d.main_dir, 'eyetracker.json');
       
       [~, progresstitle,~] = fileparts(fileparts(fileparts(eachdir)));
              
       %% EXECUTE       
       if (~result.dryrun)
            run_updater (configfile, inputfile, outputfile, 'ProgressTitle', sprintf('%s (%s)\t',progresstitle, eachbasename));       
       end
              
       %fprintf ('%d.\tconfig = %s\n', d.item, configfile);
       %fprintf ('\tinput  = %s\n', inputfile);
       %fprintf ('\toutput = %s\n', outputfile);

       rlog ('rlog','updater','%d.\tconfig = %s\n', d.item, configfile);
       rlog ('rlog','updater','\tinput  = %s\n', inputfile);
       rlog ('rlog','updater','\toutput = %s\n', outputfile);

       

end



%% PRESENTATION FLOWALYZER 


function presentation_flowalyzer (eachItem, d, result)

       %% analyze each 
       
       
       videofile    = fullerfile (d.clipspath, eachItem.filename);
       configfile   = fullerfile (d.main_dir, 'flowalyzer-config.tiled.json');       

       [~,eachbasename,~] = fileparts (eachItem.filename);
       outputpath   = fullerfile (d.flowpath, eachbasename); %%, 'results.csv');
       logfile      = fullerfile (outputpath, 'output.log');
              
%       if (~exist(openfacefile, 'file'))
%            fprintf ('WARNING: No OpenFace ...%s\n', openfacefile);
%            return
%       end
             
       
       %% EXECUTE                         
       if (~result.dryrun)
            if (exist(logfile, 'file'))
                delete (logfile);
            else                
                createdirectory(outputpath);
            end
            
            %% generate a log file
            rlog (logfile);              
            %run_flowalyzer (configfile, videofile, outputpath); %, 'OverWrite', true);      
            
            flowbasename = strrep (eachbasename, 'clip', 'flow');                   
            outputVideo    = fullerfile (outputpath, strcat(flowbasename,'.mp4'));
            outputDataFile = fullerfile (outputpath, strcat(flowbasename,'.csv'));            
            run_flowalyzer(videofile, outputVideo, outputDataFile, configfile);
            
            
            %run_flowalyzer (configfile, videofile, outputpath, 'ProgressTitle', sprintf('%s (%s)\t',progresstitle, eachbasename)); %, 'OverWrite', true);                   
       end
       
       
       fprintf ('%d.\tconfig = %s\n', d.item, configfile);
       fprintf ('\tinput    = %s\n', videofile);
       fprintf ('\toutput   = %s\n', outputpath);


end






%% PRESENTATION GAZE-UPDATER 

function presentation_gazeupdater (varargin)

       %% analyze each       
       if (nargin == 3)
           
           eachItem = varargin{1};
           d        = varargin{2};
           result   = varargin{3};
           this_filename = eachItem.filename;
           [eachdir, eachbasename, ~] = fileparts(fullerfile (d.gazepath, this_filename));       
           eachbasename = strrep (eachbasename, 'clip', 'gaze');       
           inputfile  = fullerfile (eachdir, strcat(eachbasename, '.csv'));
           outputfile = fullerfile (eachdir, strcat(eachbasename, '.updated.csv'));
           
           configfile = fullerfile (d.main_dir, 'gazefilters.json');
           [~, progresstitle,~] = fileparts(fileparts(fileparts(eachdir)));       
           this_title = sprintf('%s (%s)\t',progresstitle, eachbasename);

           rlog ('rlog','gazeupdater','%d.\tconfig = %s\n', d.item, configfile);
           rlog ('rlog','gazeupdater','\tinput  = %s\n', inputfile);
           rlog ('rlog','gazeupdater','\toutput = %s\n', outputfile);
           
       elseif (nargin == 2) 
       
           d        = varargin{1};
           result   = varargin{2};
           configfile = fullerfile (d.main_dir, 'gazefilters.json');
           inputfile  = fullerfile (d.gazepath, 'gaze.converted.csv');       
           outputfile = fullerfile (d.gazepath, 'gaze.converted.updated.csv');           
           this_title = 'glboal updater';

           rlog ('rlog','gazeupdater','%d.\tconfig = %s\n', 0, configfile);
           rlog ('rlog','gazeupdater','\tinput  = %s\n', inputfile);
           rlog ('rlog','gazeupdater','\toutput = %s\n', outputfile);
           
       end
       
       %% information 
       if (~result.dryrun)
          run_updater (configfile, inputfile, outputfile, 'ProgressTitle', this_title);       
       end
                     

       

end



%% PRESENTATION VIDEO-SPLITTER 


function presentation_videosplitter (d, result)
      
    
   %%% convert CDP_REPORT to a STEPS report instead (to be read by VIDEOSPLITTER)     
   %try 
   %  cdp_report = loadcdptxtreport (d.cdp.timefile);
   %catch ME       
   %  %% add to an Exclusion List
   %  fprintf ('WARNING missing .... %s', d.cdp.timefile);
   %  return
   %end
   %
   %%% add the eye to the steps file 
   %all_steps = cdp_report.steps_run;   
   %for p = 1:length(all_steps)
   %    all_steps(p).eye = cdp_report.eye; 
   %end
   %
   %savejson ([], all_steps, d.cdp.stepsfile);
   %fprintf ('created steps.json file ... %s\n', d.cdp.stepsfile);  
   
   
   %% converted   
   try 
        
        %% input files 
        clipspath    = d.clipspath;         % strrep(clipspath, '\','/');
        videofile    = d.videofile;         % strrep(inputfile, '\','/');
        timefile     = d.timeline;          % strrep(cdp_timeline, '\','/');        
        %cdp_format   = d.cdp.formatfile;    % strrep(cdp_format, '\','/');           
               
        %% check if PC 
        if (ispc())                       
            clipspath     = strrep(clipspath, '\','/');
            videofile     = strrep(videofile, '\','/');
            timefile      = strrep(timefile, '\','/');            
            %stepsfile     = strrep(stepsfile, '\','/');
            %cdp_format    = strrep(cdp_format, '\','/');           
        end 

        %% video-splitter (no cdp_format field)
        fprintf ('inputfile = %s\ntimeline = %s\nclips = %s\n', videofile, timefile, clipspath);           
        cmd_str = sprintf('videosplitter -i "%s" -t "%s" -o "%s"\n', videofile, timefile, clipspath);               
        %cmd_str = sprintf('videosplitter -i "%s" -t "%s" -p "%s" -o "%s"\n', videofile, stepsfile, cdp_format, clipspath);       
        fprintf (cmd_str);
        
        if (~result.dryrun)
            system(cmd_str);                 
        end
        
   catch ME                   
       %fprintf ('error');                   
       throw (ME);
   end
    

end



%% PRESENTATION VIDEO-SPLITTER 


function presentation_adjust (d, result, setups)
      
   %% enabled 
   if   (isfield(setups, 'adjust'))        
       parms = setups.adjust;
       if (~parms.Enable)       
            fprintf ('Parameters not ENABLED.\n');
            return
       end
   end
    
   
   %% converted   
   try 
        
        %% input files 
        % clipspath    = d.clipspath;         % strrep(clipspath, '\','/');
        videofile         = d.videofile;         % strrep(inputfile, '\','/');
        updatedfile       = d.updatedfile;        
        timefile          = d.timeline;          % strrep(cdp_timeline, '\','/');        
        % cdp_format   = d.cdp.formatfile;    % strrep(cdp_format, '\','/');           
               
        %% check if PC 
        if (ispc())                       
            %clipspath     = strrep(clipspath, '\','/');
            updatedfile     = strrep(updatedfile, '\','/');
            videofile      = strrep(videofile,  '\','/');
            timefile       = strrep(timefile,   '\','/');  
            
            %cdp_format    = strrep(cdp_format, '\','/');           
        end 

        %% video-splitter (no cdp_format field)
        % fprintf ('inputfile = %s\ntimeline = %s\nclips = %s\n', videofile, timefile, clipspath);           

        fnames = fieldnames (parms.arguments);                
        
        %fnames
        
        strn = sprintf ('eq=%s=%4.2f', fnames{1}, parms.arguments.(fnames{1}));        
        M = length (fnames);
        
        if (M > 1)
           for k = 2:M               
               % parms.arguments.(fnames{k})               
               strn = strcat (strn, sprintf(':%s=%4.2f', fnames{k}, parms.arguments.(fnames{k})));
           end
        end
 
        %fprintf ('copy ... %s to %s\n', videofile, backupfile);        
        %copyfile (videofile, backupfile);
        
        cmd_str = sprintf('ffmpeg -y -i "%s" -vf %s -vcodec libx264 -pix_fmt yuv420p "%s"\n', videofile, strn, updatedfile);
        system (cmd_str);
        fprintf (cmd_str);
                
        %cmd_str = sprintf('ffmpeg -y -i "%s" -vf %s  -c:a copy "%s"\n', updatedfile, strn, updatedfile); %  sprintf('videosplitter -i "%s" -t "%s" -o "%s"\n', videofile, timefile, clipspath);               
        %system (cmd_str);
        %fprintf (cmd_str);
        
        %cmd_str = sprintf('videosplitter -i "%s" -t "%s" -p "%s" -o "%s"\n', videofile, stepsfile, cdp_format, clipspath);       
        % result
        
        %% MV/RENAME THE OLD VIDEO 
        
        
        %% CONVERT the VIDEO 
        % USE FFMPEG 
                
        
        if (~result.dryrun)
            system(cmd_str);                 
        end
        
   catch ME                   
       %fprintf ('error');                   
       throw (ME);
   end
    

end




%% PRESENTATION OKN


function presentation_okn(eachItem, d, result, setup, source)

       
       %% Create a merged okndetector.config in the OUTPUT directory

       [~,eachbasename,~] = fileparts (eachItem.filename);              

       %% oknpath            = fullfile (d.oknpath, source, eachbasename);
       
       %tempconfigfile     = fullfile (oknpath, 'okndetector.merged.config');         
       oknpath            = fullerfile (d.oknpath);
       createdirectory(oknpath);
              
       %% updated data file 
       
       switch (source)
       
               
           case { 'frontface' } 
               
                              
               %% this is the INPUT file 
               [eachdir, eachbasename, ~] = fileparts(fullerfile (d.resultpath, eachItem.filename));       
               inputdir   = fullerfile (eachdir, eachbasename);       
               inputfile  = fullerfile (inputdir, 'results.updated.csv');       
               if (~exist(inputfile, 'file'))
                    fprintf ('WARNING: No Input File  ...%s\n', inputfile);
                    return
               end
               

           otherwise 

                error ('Unknown SOURCE Requetsed.');
                
       end
                    
       %% Execute                           
       if (~result.dryrun)
                       
           
            %% generate a temporary OKN config File from the 'okndetector.config' FILES 
            %oknsetup = load_setup_by_path (inputdir, d.main_dir, oknconfigfile);            
            %savejson ([], oknsetup, tempconfigfile);       
            
            switch (source)
                
                
                case { 'gaze' }

                    run_okndetector (tempconfigfile, inputfile, oknpath); %, 'OverWrite', true);                                   
                    
                    
                case { 'frontface', 'standard' }
            
                    
                    %% These are the configuration files 
                    each_oknpath = fullerfile (d.oknpath, 'EC');
                    oknconfig_obj = load_hierarchy (each_oknpath, d.main_dir, 'okndetector.frontface.EC.config'); 
                    merged_configfile = fullerfile(each_oknpath, 'okndetector.config');
                    savejson ([], oknconfig_obj, merged_configfile);
                    run_okndetector (merged_configfile, inputfile, each_oknpath);                                                      

                    each_oknpath = fullerfile (d.oknpath, 'NT');
                    oknconfig_obj = load_hierarchy ( each_oknpath, d.main_dir, 'okndetector.frontface.NT.config');                    
                    merged_configfile = fullerfile(each_oknpath, 'okndetector.config');
                    savejson ([], oknconfig_obj, merged_configfile);
                    run_okndetector (merged_configfile, inputfile, each_oknpath);                                                      

                    
            end
            
       end

end


%% PRESENTATION GAZE-SPLITTER 


function presentation_gazesplitter (d, result, setups)
      
   %% enabled 
   %if   (isfield(setups, 'adjust'))        
   %    parms = setups.adjust;
   %    if (~parms.Enable)       
   %         fprintf ('Parameters not ENABLED.\n');
   %         return
   %    end
   %end
    
   
   %% converted   

        %% input files 
        %videofile         = d.videofile;         
        %updatedfile       = d.updatedfile;        
        %timefile          = d.timeline;         
        % gazefile          = fullerfile(d.runpath,'../gaze.csv');      
        
        videopath = d.runpath; %,'../gaze.csv';      
                
        %% check if PC 
        if (ispc())                       

            %updatedfile    = strrep(updatedfile, '\','/');
            %videofile      = strrep(videofile,  '\','/');        
            %timefile       = strrep(timefile,   '\','/');  
            videopath       = strrep(videopath, '\','/');  
            
        end 

        %% video-splitter (no cdp_format field)
        %fnames = fieldnames (parms.arguments);                
        

        %% Produce the relevant GAZE information  
        %
        % load log.json 
        %
        % form the OUTPUT gaze: 
        %   gaze-<id>-<index>-<trial_type>.csv 
        %
        % form the INPUT gaze: 
        %  
        %
        
        %% This will reconstruct events from the gazefile 
        
        [gazetable, final, events] = easy_loadgaze(videopath);      

        %% save full-gazetable
        outfile = fullerfile (d.gazepath, 'gaze.converted.csv');
        writetable (gazetable, outfile);                  
        
        %% output information 
        M = length (final);
        for k = 1:M 
         
             id        = str2num(final(k).end_event.trial_index)+1;
             index_str = final(k).start_event.trial_index;
             type_str  = final(k).start_event.trial_type;
        
             % form the OUTPUT gaze: 
             %   gaze-<id>-<index>-<trial_type>.csv 
             %
                     
             outputfile = sprintf('gaze-%d-%s-%s.csv', id, index_str, type_str); 
             if (~result.dryrun)
                
                 i = (gazetable.event_id == id);
                 thistable = gazetable(i,:);
                 outfile = fullerfile (d.gazepath, outputfile);
                 writetable (thistable, outfile);                  
             end
         end
  
        
        
    

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

