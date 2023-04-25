function VA = t2logMAR (t, dirn, info)

    if (dirn == -1)
        VA = info.max_logMAR + 0.1 - (0.1/2)*(t);
    else
        t_max = (info.max_logMAR - info.min_logMAR)/info.ratio;
        VA = info.max_logMAR  - (0.1/2)*(t_max - t);       
    end 
end

