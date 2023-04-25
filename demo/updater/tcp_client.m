classdef tcp_client < tcp
    
    %TCP_CLIENT client for tcp messages 
    %   This client object is used to communicate with a TCP_SERVER.
    %   This class instantiates a "parse_message" method that contains 
    %   logic required to deal with data send by the server.   
    %   

    methods

        function obj = tcp_client(varargin)
            
            %% Instantiate everything else 
            obj = obj@tcp(tcpclient (varargin{:}));
            obj.logger.info ('tcp_client', 'started.');

        end

        function parse_message (obj, msg)
                
            % PARSE_MESSAGE Main entry point for tcp_client 
            % 
            % Messages appear here as Matlab struct 'msg'. By convention  
            % the msg object has the following format 
            %
            %  cmd   is the command 
            %  data  is additional information 
            %  ....  any other fields added here 
            % 

            unset_waiting (obj)

            
            switch (msg.cmd)

                case { 'ok' }

                  obj.logger.info ('tcp_client (recv)', 'ok');

                otherwise 
            end    

        end


    end
end

