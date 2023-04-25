function final = recursive_load (filepath, filename, varargin)


%% RECURSIVE_LOAD Traverse down the tree looking for file-pattern 
%
%   y = recursive_load (filename)
% 
% where 
%       filepath is the path to the dir 
%       filename is the pattern to match 
%
%   Optional: 
%       loader = @load_commented_json  (set for commented JSON)
%

   p = inputParser ();
   p.addOptional ('loader', @load_commented_json);
   p.parse(varargin{:});
   result = p.Results;
   
   thiscd = pwd();
   javaFileObj = java.io.File(filepath);
   if (~javaFileObj.isAbsolute ())   
       filepath = fullfile (thiscd, filepath);
   end
   
   %% each-file
   eachfile = fullfile(filepath, filename);        
   fprintf ('starting ... %s', eachfile);
      
   while (~isempty(filepath))
          
      if (exist (eachfile, 'file'))
          final = result.loader (eachfile);
          return          
      end

      
      % checker 
      if (strcmpi (filepath, thiscd)) 
          disp('file not found on path.');
          final = [];
          return
      end
      
      % shorten the filepath 
      [filepath, ~, ~] = fileparts (filepath);
      eachfile = fullfile(filepath, filename);      
      
      
end
    









