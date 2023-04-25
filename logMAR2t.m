function t = logMAR2t (VA, dirn, info)

% logMAR2t Time from beginning over which OKN has been present 


    if (dirn == -1)
        t = (VA - info.max_logMAR - 0.1)/(-(0.1/2));
    else
        t_max = (info.max_logMAR - info.min_logMAR + 0.1)/info.ratio;        
        t =  t_max - (VA - info.max_logMAR - 0.1)/(-(0.1/2));       
    end 
end
