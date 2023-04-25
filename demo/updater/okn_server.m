classdef  okn_server < tcp % tcp_server
    
    %OKN_SERVER A server class for receiving and passing messages 
    %   Implements the 'parse_message' method that will process information 
    %   from the client and execute particular coomands.
    
    methods

        function obj = okn_server (varargin)

            obj = obj@tcp (tcpserver(varargin{:}));
            obj.logger.info ('okn_server', 'started.');

        end

        function parse_message(obj, msg)
        
            % PARSE_MESSAGE Main entry point for okn_server 
            % 
            % Messages appear here as Matlab struct msg. By convention  
            % the msg object has the following format 
            %
            %  cmd   is the command 
            %  data  is additional information 
            %  ....  any other fields added here 
            %
            % After processing we must send a REPLY e.g., send_ok
            % to unblock the client 
            %

            switch (msg.cmd)
            
                case { "dummy" }

                    %% REPLY 
                    send_response(obj, tcp.OK);

                case { "run_updater" }

                       inputfile  = msg.data.inputfile;
                       outputfile = msg.data.outputfile;
                       configfile = msg.data.configfile;

                       obj.logger.info (class(obj), 'calling ... run_updater');
                       obj.logger.info (class(obj), sprintf('config = %s', configfile));
                       obj.logger.info (class(obj), sprintf('input  = %s', inputfile));
                       obj.logger.info (class(obj), sprintf('output = %s', outputfile));

                       run_updater (configfile, inputfile, outputfile);

                       %% note: no data is sent  
                       send_ok(obj);
                                               
                otherwise
                    send_error (obj,'Unknown message');
            end

        end
    
   
    end

    methods 



    end
   
end


