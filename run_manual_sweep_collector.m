function run_manual_sweep_collector (participant_file, data_dir)

% RUN_MANUAL_SWEEP_COLLECTOR  Generate a random lists of SWEEPS  
%
% This output of this file is JSON. Intent is to send that info to a 
% mustache templating engine. This is prior to manual inspection.
%
% 
%   run_manual_sweep_collector (participant_file, data_dir)
%
% where  
%       participant_file  is the list of participants to include 
%       data_dir          is the general location of data 
%

%% participant information 


inputTbl    = readtable(participant_file);

[mypath, basename, extname] = fileparts (participant_file);

output_dir = fullerfile(mypath, basename, 'manual');
createdirectory (output_dir);

output_images_dir = fullerfile(mypath, basename, 'manual', 'images');
createdirectory (output_images_dir);


%{

fprintf ('looking for ignore file ...');

if (isempty(res.ignorefile))
   [mypath, mybase, myext] = fileparts (participant_file);
   participant_ignore_file = fullerfile(mypath,strcat(mybase, '.ignore', myext));  
else
   participant_ignore_file = res.ignorefile;
end
fprintf ('%s\n', participant_ignore_file);

if (exist(participant_ignore_file, 'file'))
    exclTbl     = readtable(participant_ignore_file);
    fprintf ('found.\n');
else
    exclTbl = [];
    fprintf ('not found.\n');
end

%}


M = size(inputTbl,1);
count = 1;
for k =1:M

    each_dir = fullerfile(data_dir, inputTbl.Date{k}, inputTbl.File{k});

    for l = 1:5

        sweepbasename = sprintf('fig_%s_%d',inputTbl.File{k}, l);
        sweepfile     = strcat(sweepbasename, '.png'); 
        inputfile   = fullerfile (each_dir, 'results/figures/', sweepfile);
        outputfile  = fullerfile (output_dir, 'images', sweepfile);
        copyfile(inputfile, outputfile);        
        
        output(count).id        = count; 
        output(count).main      = inputTbl.File{k};         
        output(count).basename  = sweepbasename;
        output(count).inputfile = sweepfile;
        output(count).pair      = l;

        count = count + 1;
    end


end

% list 1
n = randperm(length(output));
scrambled = output(n);
txt = jsonencode(scrambled);
writelines(txt, fullerfile(output_dir,'data_1.json'));

% list 2 
n = randperm(length(output));
scrambled = output(n);
txt = jsonencode(scrambled);
writelines(txt, fullerfile(output_dir,'data_2.json'));



end
