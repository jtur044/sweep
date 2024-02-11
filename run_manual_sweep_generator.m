function run_manual_sweep_generator (participant_file, data_dir)

% RUN_MANUAL_SWEEP_GENERATOR 
%
%   run_manual_sweep_generator (participant_file, data_dir)
%
% where 
%       participant_file is the participant_info file 
%       data_dir         is the data directory 
%

%% participant information 


inputTbl    = readtable(participant_file);

[mypath, basename, extname] = fileparts (participant_file);

output_dir = fullerfile(mypath, basename, 'manual');
createdirectory (output_dir);

output_images_dir = fullerfile(mypath, basename, 'manual', 'images');
createdirectory (output_images_dir);


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

perm1file = fullerfile(output_dir,'data_1.json');
if (~exist ("perm1file",'file'))
    writelines(txt, fullerfile(output_dir,'data_1.json'));
else
    error ('It is not allowed to overwrite');
end

% list 2 
n = randperm(length(output));
scrambled = output(n);
txt = jsonencode(scrambled);

perm2file = fullerfile(output_dir,'data_2.json');
if (~exist ("perm2file",'file'))
    writelines(txt, perm2file);
else
    error ('It is not allowed to overwrite');
end

end
