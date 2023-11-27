function info  = get_output_consensus_VA (output, VAinfo)

% GET_CONSENSUS_VA  Return the CONSENSUS VA
%
%   info  = get_output_consensus_VA (output, VAinfo)
%
% where
%       activity is the activity flag (separated or chain) 
%       VAinfo   is the sweep information 
%                       
%                   max  : 1.0
%                   min  : 0.0
%                   step : 0.1
%

if (isfield(VAinfo, 'logMAR'))    
    VAinfo.max_logMAR = VAinfo.logMAR.max;
    VAinfo.min_logMAR = VAinfo.logMAR.min;
    VAinfo.ratio      = VAinfo.ratio;       % *VAinfo.sweep_direction;
end

%fprintf ('output consensus\n');


%% determine a overall information from all "sp" data 

for k = 1:length (output)
    
    sp = output(k).activity.sp;
    t  = sp(:,1);
    maxT(k) = max(t); 
    minT(k) = min(t);      
    fps(k)  = 1/mean(diff(t));

end

maxT = min (maxT);
minT = max (minT);
fps  = round(mean(fps));
dT   = 1/fps;

fprintf ('est. fps        = %4.2f\n', fps);
fprintf ('max. valid t    = %4.2f\n', maxT);
fprintf ('min. valid t    = %4.2f\n', minT);

%% determine a standardized time-base

T     = (minT:dT:maxT).';
L     = length (T);
outp  = [];
downp = 0*T;
upp   = 0*T;


%% generate re-based activity information 

outp(:,1) = T; 

for k = 1:length (output)

     %%  a regularized grid  
     t   = output(k).activity.sp(:,1);
     sp  = output(k).activity.sp(:,2);
     ep  = output(k).activity.ep(:,2);   

     %% information        
     [t1, i1] = unique (t);
     d = length (t) - length(t1);
     if (d ~= 0)         
         fprintf ('[WARNING] Detected %d repeated data-point(s) found! (%s)\n', d, output(k).name);
         t  = t1;
         sp = sp(i1);
         ep = ep(i1);
     end

     y   = interp1 (t, double(sp | ep), T);      

     outp(:,k) = y; 
     st(k) = output(k).start_time;
     ed(k) = output(k).end_time;
             
end

% determine the UP/DOWN activity 
i_up        = sign([ output.k ])==1;
up          = mean(outp(:,i_up)',1)'; 
i_up_incl   = up >= 0.5;
st_up       = st (i_up); st_up = st_up(1);
ed_up       = ed (i_up); ed_up = ed_up(1);

i_dwn       = sign([ output.k ])==-1;
dwn         = mean(outp(:,i_dwn)',1)'; 
i_dwn_incl  = dwn >= 0.5;
st_dwn      = st (i_dwn); st_dwn = st_dwn(1);
ed_dwn      = ed (i_dwn); ed_dwn = ed_dwn(1);


% get UP consensus 

ratio = VAinfo.ratio;

info.up.activity        = [ T up i_up_incl ]; 
if  (any(i_up_incl))    
    [min_t, ~]   = min(T(i_up_incl));
    if (st_up < min_t)
        info.up.t       = min_t;    
        info.up.VA      = VAinfo.min_logMAR + abs(ratio)*(info.up.t - st_up);        
        info.up.bounded = true;
    else
        % the time was located before the start 
        info.up.t       = st_up;
        info.up.VA      = VAinfo.min_logMAR;    
        info.up.bounded = false;
    end
else
    info.up.t       =  st_up;
    info.up.VA      = VAinfo.min_logMAR;
    info.up.bounded = false;
end 

% get DWN consensus 

info.dwn.activity        = [ T dwn i_dwn_incl ]; 
if  (any(i_dwn_incl))    
    [max_t, ~]    = max(T(i_dwn_incl));
    if (ed_dwn > max_t)
        info.dwn.t    = max_t;    
        info.dwn.VA   = VAinfo.max_logMAR + 0.1 - abs(ratio)*(info.dwn.t - st_dwn);        
        info.dwn.bounded = true;
    else
        % the time was located before the start 
        info.dwn.t       = ed_dwn;
        info.dwn.VA      = VAinfo.min_logMAR;    
        info.dwn.bounded = false;
    end

else
    info.dwn.t       = ed_dwn;
    info.dwn.VA      = VAinfo.max_logMAR + 0.1;
    info.dwn.bounded = false;
end 

info.meanVA         = (info.up.VA + info.dwn.VA)/2;


end