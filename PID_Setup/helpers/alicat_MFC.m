classdef alicat_MFC < handle
    properties
        ID
        Port
        Name
    end

    methods
        function alicat_MFC = MyClass(SerialPort, ID, Name)
            global BpodSystem

            if nargin > 0
                alicat_MFC.port = ['Serial' num2str(SerialPort)];
                alicat_MFC.ID = ID;
                alicat_MFC.Name = Name;
            end
        end

        function set_MFC_flow(flow_rate)
            global BpodSystem

            % Write to the specified MFC and set its flow rate
            % If the flow rate is outside of the allowed bounds, return error

            % After setting the flow rate, poll the MFC and check that the setting both stuck
            % And that the flow rate is correct (+/- 0.05%)

            command = [alicat_MFC.ID 's' num2str(flow_rate)]; % Combine the command bytes in this order: ID 's' FLOWRATE
            send_command_to_MFC(command);

            new_flowrate = poll_MFC('F');

            if new_flowrate ~= flow_rate
                error("Flowrate was not set properly!")
            end

            if (new_flowrate >= flow_rate * 1.05) || (new_flowrate <= flow_rate * 0.95)
                error("Flowrate is currently out of range!")
            end

        end

        function data = poll_MFC(key)
            global BpodSystem

            data = [];

            % Poll MFC and return the requested data
            % A single passed char will determine what data is returned
            % Error on invalid char
            % if multiple chars, only the first is considered
            % A (All), I(ID), F(Flow Rate), P(Pressure)
            % If no char, All is returned by default
            % Error on no response from MFC

            send_command_to_MFC(alicat_MFC.ID); % Request all of the information from the MFC
            response = []; % Response is read from MFC. Dunno how to do this yet

            if length(key) > 1
                key = key(1);
            end

            switch key
                case 'I'

                case 'F'

                case 'P'

                otherwise
                    data = response;

            end
        end

        function command_as_bytes = prep_MFC_command(command_to_prep)
            command_as_bytes = unicode2native(command_to_prep); % Convert to decimal representation of chars
            command_as_bytes = [command_as_bytes 13]; % Add a CR (DEC: 13) per Alicat to end the command
        end

        function send_command_to_MFC(command)
            command = command_as_bytes(command);
            ModuleWrite(alicat_MFC.port, command);
        end
    end
end