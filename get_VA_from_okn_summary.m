function VA = get_VA_from_okn_summary (input)

% GET_VA_FROM_OKN_SUMMARY Determine summary from input 
%
%
% EXAMPLE 
%
% stri = './DATA/4Aug2023/hwai_04_08_2023_long_right/trials/okn_detector_summary.csv'
% VA = get_VA_from_okn_summary (stri)
%

if (ischar(input) | isstring(input))

    try 
        data = readtable (input);
    catch ME 
        fprintf ('File was not found!');
        return
    end 
else 
    data = input; % direct table input 
end

% find greatest 
logmar = data.logmar_level;

is_okn = cellfun ( @(x) strcmpi(x, 'true' ), data.okn);
VA_max = max(data.logmar_level); 
VA = VA_max + 0.1 - sum(is_okn)*0.02;

VAinfo.VA_max  = VA_max;
VAinfo.correct = sum(is_okn);
VAinfo.VA_min  = min (logmar)

end