%% DEMO_SERVER Example of running "run_updater" through the OKN server object  
%
% This demonstration passes data to the OKN_SERVER which in turn - takes 
% action on it. The demo runs 'run_updater'
%
% Note that it just takes filenames as data which are then passed to  
% run_updater 
%
% Ideally (maybe??) we wish to send the actual data via tcp rather than  
% sending a filename instead 
%

close all; clear all;


% okn_server holds the logic in the parse_message function  
%
% presently it has a 'run_updater' cmd which is called by the 
% client.

server = okn_server (4000);


%
%   1 - the updated configuration 
%   2 - the input file which is 'results.patched.csv'
%   3 - the output file which is 'results.updated.csv'
%

message.cmd             = "run_updater";
message.data.inputfile  = 'results.patched.csv';
message.data.outputfile = 'results.updated.csv';
message.data.configfile = 'updater_configuration.json';

client = tcp_client ("localhost", 4000);
client.send_request (message);   %% requests are blocking 

client.stop ();
server.stop ();




