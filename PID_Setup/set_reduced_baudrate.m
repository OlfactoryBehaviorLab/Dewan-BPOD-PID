function set_reduced_baudrate(port, state)
    % Check that the baudrate is within limits for RS232 (currently the baudrate is static)
    % Set the baudrate to reduced or regular

    num_modules = BpodSystem.Modules.nModules;
    port_states = BpodSystem.Modules.Connected;

    % if baudrate > 256000
    %     error(['Baudrate ' baudrate 'is too fast for RS232!']);
    % end

    if port > num_modules || port < num_modules
        error([port ' is not a valid port number!']);
    end

    if port_states(port) ~= 0
        error(['Port ' port 'is already in use!']);
    end

    if (state ~= 0) || (state ~= 1)
        error('Invalid state! Valid states are 1 (reduced baud rate) or 0 (original baud rate)!');
    end

    BpodSystem.SerialPort.write('B', 'char', port, 'uint8', state, 'uint8'); % Send B command with the port to adjust, and the state to place the port in

end