function r = demo_experiment_sweep_set ()

trial    = "";
input_dir = "./DATA/Aug2/cfra_02_08_2023_sweep_left";
info = load_hierarchy (input_dir, "./DATA", strcat("config/",trial,"sweep_settings.json"));

r = run_experiment_sweep_set (input_dir, info)

end

function r = run_experiment_sweep_set (input_dir, info)

% 5x descending/ascending sweeps 

r = analyze_sweep_set (input_dir, info);

%% do the gridding 

r = get_regridded_activity (r, "descending");
r = get_regridded_activity (r, "ascending");

%% get the "OR'ed" metric 

p.descending.activity = get_metrics (r, "descending", "or");
p.ascending.activity  = get_metrics (r, "ascending",  "or");



end


function b = get_metrics (r, which, methods)


    switch (methods)

        case { "or" }
        
            M = length (r);   
            t = r(1).(which).activity(:,1);
        
            b = r(1).(which).activity(:,3);
            for k = 1:M
                y1 = r(k).(which).activity(:,3);
                b = b | y1;
            end    
            b = [ t b ];

        otherwise 
            error ('Information.');

    end

end


function r = get_regridded_activity (r, which)

    y1 = []; y2 = [];
    
    %% Interpolate on a consistent grid  
    
    M = length (r);   
    
    for k = 1:M

        y1          = r(k).(which).activity;
        t_max(k)    = y1(end,1);  
        frames(k)   = size (y1, 1);
        fps(k)      = frames(k)/t_max(k);

        fprintf ('max value t = %4.2f, length = %d, fps=%4.2f\n', t_max(k), frames(k), fps(k));
        
    end

    %% Crop to consistent size
    fps     = round(max(fps));
    T       = min(t_max);

    fprintf ('fps = %4.2f, T = %4.2f sec\n', fps, T);

    dt      = 1/T;
    t       = (0:dt:T).';

    for k1 = 1:M
        
        y1          = r(k1).(which).activity;        
        t0          = y1(:,1);
        y0          = y1(:,2);
        b0          = y1(:,3);
        
        y           = interp1 (t0, y0, t);
        b           = round(interp1 (t0, b0, t));

        r(k1).(which).activity = [ t y b ];

        %plot(t,b);
        %hold on;

    end

end
