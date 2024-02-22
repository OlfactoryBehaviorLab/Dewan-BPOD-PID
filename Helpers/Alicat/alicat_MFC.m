% Alicat MFC Wrapper Class for Bpod 
% Dewan Lab, Florida State University
% Austin Pauley, 11/2023

classdef alicat_MFC < handle
    properties
        ID
        Port
        Name
    end

    methods
        function MFC = alicat_MFC(SerialPort, ID, Name)
            global BpodSystem

            if nargin > 0
                MFC.Port = ['Serial' num2str(SerialPort)];
                MFC.ID = ID;
                MFC.Name = Name;
            end
        end

        function set_MFC_flow(obj, flow_rate)
            global BpodSystem

            command = [obj.ID 's' num2str(flow_rate)]; % Combine the command bytes in this order: ID 's' FLOWRATE

            send_command_to_MFC(obj, command);
            
            new_setpoint = poll_MFC(obj, 'S'); % Get new setpoint
            current_flowrate = poll_MFC(obj, 'F'); % Get new flowrate
            
            if new_setpoint ~= flow_rate
                error("Flowrate was not set properly!")
            end

            if (current_flowrate >= flow_rate * 1.05) || (current_flowrate <= flow_rate * 0.95)
                error("Flowrate is currently out of range!")
            end
            % After setting the flow rate, poll the MFC and check that the setting both stuck
            % And that the flow rate is correct (+/- 0.05%)

        end

        function data = poll_MFC(obj, key)
            global BpodSystem
            
            BpodSystem.SerialPort.flush(); % Clear everything and then read

            send_command_to_MFC(obj, obj.ID); % Request all of the information from the MFC by sending only its ID

            % The code executes faster than serial can spit bytes out
            last_bytes = [];
            response = [];

            while true % Continue reading in bytes until the response array does not get longer for two cycles
                num_bytes = BpodSystem.SerialPort.bytesAvailable; % Get number of bytes to read, if this is zero we read none
                response = [response BpodSystem.SerialPort.read(num_bytes, 'uint8')]; % Response is read from MFC  
                
                if length(response) == last_bytes % If the length of our response is unchanged since the last loop, we are done reading
                    break;
                else
                    last_bytes = length(response); % Set the length of the response to check against during the next loop
                    pause(0.03); % Wait 30ms before reading again
                end

            end
            
            response = native2unicode(response); % Convert decimal to chars
            response = split(response); % Split response into individual components
            response = response(1:end-1); % Remove empty cell at end
            
            % MFC Dataframe Indexes
            % 1. ID
            % 2. Pressure
            % 3. Temperature
            % 4. Volumetric Flow
            % 5. Mass Flow
            % 6. Set Point
            % 7. Gas

            if length(response) ~= 7 % There should be 7 bytes sent back
                error(['MFC ' obj.ID ' did not respond properly!']);
            end

            if length(key) > 1
                key = key(1); % If multiple bytes are passed, only use the first one
            end

            key = upper(key); % Accept lowercase and upercase keys

            switch key
                case 'I'
                    mfc_ID = char(response(1)); % 1st item is the ID, convert it to a char
                    data = mfc_ID;
                case 'S'
                    set_point = response(6); % 6th item is the Set Point
                    set_point = set_point{1}; % Get data from single cell
                    set_point = set_point(2:end); % Remove the sign (+/-)
                    set_point = str2double(set_point); % Convert to a double

                    data = set_point;
                case 'F'
                    flow_rate = response(5); % 5th item is the Mass Flow
                    flow_rate = flow_rate{1}; % Get data from single cell
                    flow_rate = flow_rate(2:end); % Remove the sign (+/-)
                    flow_rate = str2double(flow_rate); % Convert to a double

                    data = flow_rate;
                case 'P'
                    pressure = response(2); % 2nd item is the Absolute Pressure
                    pressure = pressure{1}; % Get data from single cell
                    pressure = pressure(2:end); % Remove the sign (+/-)
                    pressure = str2double(pressure); % Convert to a double

                    data = pressure;
                otherwise
                    data = response; % Return everything
            end
        end

        function send_command_to_MFC(obj, command)
            byte_command = obj.prep_MFC_command(command); % Prep command to dec form
            ModuleWrite(obj.Port, byte_command); % Send dec command to MFCs
        end
    end

    methods(Static)
        function command_as_bytes = prep_MFC_command(command_to_prep)
            command_as_bytes = unicode2native(command_to_prep); % Convert to decimal representation of chars
            command_as_bytes = [command_as_bytes 13]; % Add a CR (DEC: 13) per Alicat to end the command
        end
    end
end