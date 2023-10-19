% Bpod Baudrate Tools
% Dewan Lab, Florida State University
% Austin Pauley, 10/19/2023

function bpod_baudrate_tools()
end

function set_reduced_baudrate(port, state)
    % Check that the baudrate is within limits for RS232 (currently the baudrate is static)
    % Set the baudrate to reduced or regular

    num_modules = BpodSystem.Modules.nModules;
    port_states = BpodSystem.Modules.Connected;

    % if baudrate > 256000
    %     error(['Baudrate ' baudrate 'is too fast for RS232!']);
    % end

    % Some input validation
    if port > num_modules || port < num_modules
        error([port ' is not a valid port number!']);
    elseif port_states(port) ~= 0
        error(['Port ' port 'is already in use!']);
    elseif (state ~= 0) || (state ~= 1)
        error('Invalid state! Valid states are 1 (reduced baud rate) or 0 (original baud rate)!');
    else
        BpodSystem.SerialPort.write('B', 'char', port, 'uint8', state, 'uint8'); % Send B command with the port to adjust, and the state to place the port in
        response = BpodSystem.SerialPort.read(1, 'uint8'); % status byte

        switch response
            case 1 % Success
                disp("Successfully updated baudrate!");
            case 3 % Invalid arg 2 (state)
                error("Invalid baud state!")
            case 4 % Invalid arg1 (port no or command byte)
                error("Invalid port number or command byte!");
        end
    end
end

function baudrate = get_baudrate(port)
    if port > num_modules || port < num_modules
        error([port ' is not a valid port number!']);
    else
        BpodSystem.SerialPort.write('B', 'char', '?', 'char', port, 'uint8'); % Command: B (baudrate), arg1: ? for query, arg2: port number
        baudrate = BpodSystem.SerialPort.read(1, 'uint8'); % Baudrate Bpod returned
        response = BpodSystem.SerialPort.read(1, 'uint8'); % Status byte

        switch response % We check before, but need to parse these just incase!
            case 1 % Success
                disp(['The baudrate of port ' port ' is ' baudrate])
            case 2 % Invalid Port
                error('Invalid port number!');
            case 4 % Invalid Port
                error('Invalid port number or command byte!');
        end
    end
end