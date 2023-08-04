function h = show_graph(dataTable, profile, tp, yp, varargin)
        
% SHOW_GRAPH Show the GRAPH 
%
%   h = show_graph(dataTable, profile, xp, yp)
%
% where 
%       dataTable   is the data-table
%         profile   is the profile 
%        (xp, yp)   is location of the graph
%               h   is the scale-factor 
%

    p = inputParser ();
    p.addOptional ('Visible', 'on');    
    p.parse(varargin{:});
    res = p.Results;

    if (~isfield(profile, 'mean_shift'))
        profile.mean_shift = true;
    end
        
    
    f =  gcf(); 
    set(f, 'Visible', res.Visible);  % Creating a figure and not displaying it
    
    
    %% get the correct profile 
    t = dataTable.(profile.t);
    x = dataTable.(profile.x);
    
    if (isfield(profile, 'scale_factor'))
        hp = profile.scale_factor;
    else
        hp = 1;
    end
         
    %% plot information     
    
    if (profile.mean_shift)
        h(1) = plot (tp + (t-t(1)), yp + hp*(x - mean(x, 'omitnan')), 'LineWidth', 1.75);
        hold on;
    else
        h(1) = plot (tp + (t-t(1)), yp + hp*x, 'LineWidth', 1.75);
        hold on;
    end
    set(h(1), 'Tag', 'dataline');
    
    h(2) = line([tp tp+(t(end)-t(1))], [yp yp],  'LineWidth', 1, 'LineStyle', '--');
    set(h(2), 'Tag', 'zeroline');
    hold on;
    
    set(h,'Color','k');

    
    %if (res.DataTip)        
    %    datatip(h(1), 'Content', { });
    %end 
    
    
return

