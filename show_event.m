function g = show_event(t_start, t_end, h, varargin)
        
% SHOW_EVENT Show a passed EVENT 
%
%   h = show_event(event, profile, xp, yp)
%
% where 
%       dataTable   is the data-table
%         profile   is the profile 
%        (xp, yp)   is location of the graph
%               h   is the scale-factor 
%

bbox = [ t_start 0-h/2 t_end-t_start h ]; 
pts  = bbox2points(bbox);
g = patch ('XData', pts(:,1), 'YData', pts(:,2), varargin{:});

return