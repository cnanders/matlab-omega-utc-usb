classdef UTCUSB < handle
    
    %UTCUSB Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        
        % {char 1xm} 
        cPort = 'COM4'
        
        % {serial 1x1}
        s
        
        
        
    end
    
    methods
        
        function this = UTCUSB(varargin)
            
            % Override properties with varargin
            for k = 1 : 2: length(varargin)
                % this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
            
        end
        
        function init(this)
            
            this.s = serial(this.cPort);
            set(this.s, 'BaudRate', 38400);
            set(this.s, 'Parity', 'none');
            set(this.s, 'DataBits', 8);
            set(this.s, 'StopBits', 1);
            set(this.s, 'Terminator', 'CR/LF');
            
        end
        
        
        
        function connect(this)
            if ~strcmp(this.s.Status, 'open')
                try
                    fopen(this.s); 
                catch ME
                    this.msg('connect ERROR');
                    rethrow(ME)
                end
            end
            this.clearBytesAvailable();
        end
        
        
        function disconnect(this)
            
            if strcmp(this.s.Status, 'open')
                
                this.msg('disconnect()');
                this.clearBytesAvailable();
            
                try
                    fclose(this.s);
                catch ME
                    this.msg('disconnect ERROR');
                    rethrow(ME)
                end
            end
        end
        
        % @return {struct 1x1} st with two props
        % @return {char 1xm} st.model - model number, e.g. "UTCUSB2"
        % @return {char 1xm} st.firmware - firmware number, e.g.,
        % "131009"
        
        function st = getModelAndFirmware(this)

            this.send('ENQ'); 

            % Need to scan twice because return is in format
            % USBUSB2 CRLF
            % 090713 CRLF

            cModel = fscanf(this.s);
            cFirmware = fscanf(this.s);

            % Remove terminator from returned value
            st = struct(...
                'model', this.removeTerminator(cModel), ...
                'firmware', this.removeTerminator(cFirmware) ...
            );
        end
        
        function c = getThermocoupleType(this)
            this.send('TCTYPE');
            c = fscanf(this.s);
            c = this.removeTerminator(c);
        end
        
        % Returns the temperature in Celcius with a resolution of 1 deg C
        function d = getTemperatureC(this)
            
            
            %{
            this.send('C');
            c = fscanf(this.s);
            c = this.removeTerminator(c);
            c = this.removeGreaterThanCharacter(c);
            d = str2double(c);
            %}
            
            % Convert Farenheight to C for better resolution
            d = this.getTemperatureF();
            d = this.farenheightToCelcius(d);
            
        end
        
        % Returns the temperature in Farenheight with a resolution of 1 deg
        % F
        function d = getTemperatureF(this)

            this.send('F')
            c = fscanf(this.s);
            c = this.removeTerminator(c);
            c = this.removeGreaterThanCharacter(c);
            d = str2double(c);
        end
                    
        
        function delete(this)
            this.msg('delete()');
            this.disconnect();
            delete(this.s);
        end
        
        % Returns the equivalent Celcius temperature of provided
        % Farenheight temperature
        function d = farenheightToCelcius(this, dF)
            d = (dF - 32) * 5/9;
        end
    end
    
    methods (Access = private)
       
        % Writes the provided value to the serial device
        % @param {char 1xm} c - value to write to serial device
        function send(this, c)
            this.clearBytesAvailable()
            fprintf(this.s, c);
        end
        
        
        % Returns a {char} 1 x m-2 that has the last two characters removed
        % assumes that last tco characters are CRLF which is how the
        % hardware packages all responses
        % @param {char 1xm} c - a single response from hardware
        % @return {char 1 x m-2} 
        function c = removeTerminator(this, c)
           c = c(1 : end - 2); 
        end
        
        % Returns a {char} 1 x m - 1 that has the first character removed
        % The response from the "C" and "F" commands have a ">" character
        % in front.  Omega tech support was contacted and could not explain
        % why this character is present
        function c = removeGreaterThanCharacter(this, c)
            if strcmp(c(1), '>')
                c = c(2 : end); 
            end
        end
        
        function clearBytesAvailable(this)
            
            % This doesn't alway work.  I've found that if I overfill the
            % input buffer, call this method, then do a subsequent read,
            % the results come back all with -1.6050e9.  Need to figure
            % this out
                        
            while this.s.BytesAvailable > 0
                cMsg = sprintf(...
                    'clearBytesAvailable() clearing %1.0f bytes', ...
                    this.s.BytesAvailable ...
                );
                this.msg(cMsg);
                fread(this.s, this.s.BytesAvailable);
            end
        end
        
        function msg(this, cMsg)
           fprintf('omega.UTCUSB %s\n', cMsg); 
        end
        
        function l = hasProp(this, c)
            l = false;
            if length(findprop(this, c)) > 0
                l = true;
            end
            
        end
    end
    
end

