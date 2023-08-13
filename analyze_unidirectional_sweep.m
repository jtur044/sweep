function ret_info = analyze_unidirectional_sweep (dataTbl, dirn, info)
   
% ANALYZE_UNIDRECTIONAL_SWEEP Determine activity and VA information for a given sweep 
%
%   ret_info = analyze_unidirectional_sweep (dataTbl, dirn, info)
%
% where 
%       dataTbl     is the data table  
%       dirn        is the direction of the  
%       info        is SWEEP information 


    %% general setup  
    
    VA          = @(t, xstart, dirn, ratio) xstart+dirn*ratio*t;
    ratio       = info.logmar_step/info.win_length;
    n_points    = (info.max_logMAR - info.min_logMAR)/0.1 + 1;
    time_points = (0:(n_points+1))*info.win_length;
    
    %% read descending sweep - look for activity "drop off"
    
    lower = info.lower_threshold;
    upper = info.upper_threshold;
    
    
    switch (dirn)
    
        case { "descend", "right_down", "left_down" }
    
            t = dataTbl.t;
            [r, q] = get_sweep_activity (dataTbl, info.win_length);
            [k, i] = find_activity (r, q, 'drop-off', 'lower_threshold', lower, 'upper_threshold', upper);
            ret_info.descending.VA = t2logMAR (t(k), -1, info);
            ret_info.descending.t  = t(k); 
            ret_info.descending.k  = k; 
            ret_info.descending.activity = [ t r q ];
    
        case { "ascend", "right_up", "left_up" }
   
            
            %% read ascending sweep - look for activity "pick up"
            
            t = dataTbl.t;
            [r, q] = get_sweep_activity (dataTbl, info.win_length);
            [k, i] = find_activity (r, q, 'pick-up', 'lower_threshold', lower, 'upper_threshold', upper);
            
            ret_info.VA = VA (t(k), info.min_logMAR, +1, ratio)
            ret_info.t  = t(k); 
            ret_info.k  = k; 
            ret_info.activity = [ t r q ];
    
    end

end

