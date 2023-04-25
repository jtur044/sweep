%% DEMO_UPDATER


%% The parameters are: 
%
%   1 - the updated configuration 
%   2 - the input file which is 'results.patched.csv'
%   3 - the output file which is 'results.updated.csv'
%
% note that we can also load the configuration into a structure beforhand 
%

run_updater ('updater_configuration.json', 'results.patched.csv', 'results.updated.csv');

% also valid - load into an object beforehand
% run_updater (load_commented_json('updater_configuration.json'), 'results.patched.csv', 'results.updated.csv');