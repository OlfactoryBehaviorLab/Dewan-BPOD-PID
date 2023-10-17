classdef alicat_MFC < handle
    properties
        ID
        Port
        Name
    end

    methods
        function alicat_MFC = MyClass(SerialPort, ID, Name)
            if nargin > 0
                alicat_MFC.port = SerialPort;
                alicat_MFC.ID = ID;
                alicat_MFC.Name = Name;
            end

            % Check here that the specified Serial Port is:
            %   1) Available
            %   2) Set to an acceptable speed

        end

        function state = set_MFC_flow(flow_rate)
            state = 0;
            % Write to the specified MFC and set its flow rate
            % If the flow rate is outside of the allowed bounds, return error

            % After setting the flow rate, poll the MFC and check that the setting both stuck
            % And that the flow rate is correct (+/- 0.01%)

        end

        function data = pollMFC(data_to_return)
            data = [];

            % Poll MFC and return the requested data
            % A single passed char will determine what data is returned
            % Error on invalid char
            % if multiple chars, only the first is considered
            % A (All), I(ID), F(Flow Rate), P(Pressure)
            % If no char, All is returned by default
            % Error on no response from MFC
        end

        
    end
end