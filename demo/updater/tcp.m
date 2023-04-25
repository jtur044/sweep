classdef tcp < handle
    %TCP Summary of this class goes here
    %   Detailed explanation goes here


    properties (Constant)

        ERROR = 1
        OK    = 0

    end 

    properties
        object; 
        logger;
    end

    properties
        iswaiting; 
    end


    methods (Abstract)
    
        parse_message(obj)
    
    end

    methods
        function obj = tcp(object)

            obj.object = object;
            pause(2);

            %% LOGGER 
            obj.logger = log4m.getLogger ();
            obj.logger.setCommandWindowLevel(log4m.ALL);

            %% CONFIGURE CALLBACK 
            configureCallback(obj.object, "terminator", @(x,y) obj.process_message(x,y)); 
        end

        function stop (obj)
            flush(obj.object);
            clear obj.object;
            obj.logger.error(class(obj), 'stopped.');
        end

        function unset_waiting (obj)
            obj.iswaiting = false;                        
        end 


        % function log (obj,varargin)        
        %    obj.logger (varargin{:});
        % end

        function process_message (obj, src, ~)

            message = readline (src);
            
            %% Take action if it fails 
            try 
                parsed_message = jsondecode (message);
            catch ME 
                send_error ("Error in message JSON");
                return
            end

            %% try and process the message 
            parse_message (obj, jsondecode(parsed_message.msg));

        end

    end 


    % We could write SPECIFIC methods for sending different types of data 
    % e.g., a table ot struct - Im not sure!
    
    methods

        function send_error (obj, msg)

            % message 
            message.return = tcp.ERROR;
            message.msg    = msg;      
            obj.logger.error(class(obj), msg);
            str = jsonencode (message);
            obj.object.writeline(str);
        end

        % A request is blocking 
        
        function send_request (obj, m)
            str = jsonencode(m);
            send_message (obj, str);
            obj.logger.error(class(obj), 'request started.');

            %% blocking until reply
            obj.iswaiting = true;
            waitfor(obj, 'iswaiting', false);
            obj.logger.error(class(obj), 'request ended.');

        end

        % A response is non-blocking 
        
        function send_ok (obj)

            % send a response

            m.cmd    = "ok";
            m.status = tcp.OK;     
            
            str = jsonencode(m);
            send_message (obj, str);
            
        end

        
        function send_message (obj, msg)

            % message             
            message.return  = tcp.OK;
            message.msg     = msg;    
            str = jsonencode (message);            
            obj.logger.info(class(obj), msg);
            obj.object.writeline(str);
        end


        %% We could WRITE specific data methods here


    end
end

