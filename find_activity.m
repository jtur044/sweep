function [k, i, e] = find_activity (r, q, method, varargin)

% FIND_ACTIVITY Find activity drop 
%
%   function p = find_activity (r, ... )
%
% where 
%           q is the instantaneous activity flag 
%           r is the cumulative activity measure 
%

p = inputParser ();
p.addOptional ('lower_threshold', 0.20);
p.addOptional ('upper_threshold', 0.80);
p.addOptional ('max_logMAR', 1.0);
p.addOptional ('min_logMAR', -0.2);
p.parse (varargin{:});
res = p.Results;

dr = gradient (r);

e = 0;

switch (method)

    case { 'drop-off' }
        
        %% requires a first pickup 
        i = (r >= res.upper_threshold) & (dr > 0);        
        if  (any(i))           
            k = find (i, 1, 'first');        
            i(k:end) = 1;           
        else
            fprintf ('(initial pickup needed - no activity)');
            k = []; i = []; e = 1;
            return
        end
        
        
        %% find drop off below actvity level
        i = (r <= res.lower_threshold) & (dr < 0) & i;    
        if (all(i))
            fprintf ('(no dropoff - no activity)');
            k = []; i = []; e = 1;
            return
        end


        %% find the first 
        if (any(i))        
            k = find (i, 1, 'first');        
            q(k:end) = 0;
            k = find (logical(q), 1, 'last');
        else
            fprintf ('(no dropoff - signal saturation)');
            k = []; i = []; e = 2;
        end 
        return 

    case { 'pick-up' }


        w = true (size(r));
        
        %% upper threshold activity found here 
        i = (r >= res.upper_threshold) & (dr > 0);        
        if  (any(i))           
            k0 = find (i, 1, 'first');        
            w(k0:end) = 0;                       
        else
            fprintf ('(no pickup found - no activity)');
            k = length(r); i = i*0; i(end) = 1; e = 3;
            return
        end
                
        %% find points where rising below threshold is found 
        %% last point is expected to be threshold poitn
        i = (r <= res.lower_threshold) & (dr > 0) & w;        
        if (any(i))

            k0 = find (i, 1, 'last');            
            w(1:k0) = 0;    



            k = find (w & q, 1, 'first');
            
        else 
            error ('Logical error!');
            %fprintf ('(no pickup found - signal saturation)');
            %k = []; i = []; e= 4;
            return        
        end
                

        %% cruised through 
        % disp ('no triggger');
        % k
        % disp ('hi');

    otherwise 
        error ('Unknown information.');

end


end