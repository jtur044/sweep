function [r, q0] = get_sweep_activity (dataTbl, win_length, varargin)

%% GET_SWEEP_ACTIVITY Return the sweep activity signal 
%
%   function [r, q] = get_sweep_activity (dataTbl, win_length)
%
% where 
%         dataTbl is the input SIGNAL.csv file 
%         win_length is the summation window 
%

p = inputParser ();
p.addOptional  ('fps', 50);
p.parse (varargin{:});
res = p.Results; 

N = win_length*res.fps;

q0 = cellfun (@(x) strcmpi(x, 'true'), dataTbl.is_sp);
q1 = cellfun (@(x) strcmpi(x, 'true'), dataTbl.is_qp);
q0 = q0 | q1;
t  = dataTbl.t;
r = movsum (q0, N, 'omitnan')/N;


end