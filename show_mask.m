function g = show_mask(dataTable, profile, xp, yp)
        
% SHOW_MASK Show the MASK
%
%   h = show_mask(dataTable, profile, xp, yp)
%
% where 
%       dataTable   is the data-table
%         profile   is the profile 
%        (xp, yp)   is location of the graph
%               h   is the scale-factor 
%

    %% get the correct profile 
    t = dataTable.(profile.t);
    x1 = dataTable.(profile.is_tracking);
    x2 = dataTable.(profile.is_blinking);
    
    if (isfield(profile, 'scale_factor'))
        hp = profile.scale_factor;
    else
        hp = 1;
    end
         
    %% plot information     

    g2 = show_timeline (t, t>min(t), yp, 20, [144, 238, 144]/255, 'FaceAlpha', 1.0);      
    g1 = show_timeline (t, ~x1 | x2, yp, 20, [255, 191, 0]/255, 'FaceAlpha', 0.8); hold on;

    % prob = ~x1 | x2;
    % g2 = show_timeline (t, x2, yp, 0.2, [255, 191, 0]/255, 'FaceAlpha', 1.0);        
    g  = [ g1(1) g2(1)  ];
    
return


function g = show_timeline (t, mask, yp, h, col, varargin)

% SHOW_TIMELINE Show the TIMELINE
%
%   h = show_timeline(t, mask, y, h, col)
%
% where 
%       t      is the data-table
%       mask   is the profile 
%       y      is location of the graph
%       h      is the scale-factor 
%       col    is the COLOR 


   labels = bwlabel (mask);        
   M = max(labels);
   for k = 1:M    
        
        each  = (labels == k);          
        start = find(each,1,'first');
        last  = find(each,1,'last');

        bbox = [ t(start) yp-h/2 t(last)-t(start) h ]; 
        pts  = bbox2points(bbox);
        g(k) = patch (pts(:,1), pts(:,2), col, varargin{:});
        
   end
   
return