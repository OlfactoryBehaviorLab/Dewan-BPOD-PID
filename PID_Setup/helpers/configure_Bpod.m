function configure_Bpod(port, state)
    global BpodSystem;
    
    num_modules = BpodSystem.Modules.nModules;
    port_states = BpodSystem.Modules.Connected;

    if port > num_modules || port < num_modules
        error([port ' is not a valid port number!']);
    end

    if port_states(port) ~= 0
        error(['Port ' port 'is already in use!']);
    end

    if ((state ~= 0) && (state ~= 1))
        error('Invalid state! Valid states are 1 (reduced baud rate) or 0 (original baud rate)!');
    end

    set_reduced_baudrate(port, state); % Send command to Bpod

    if state == 1
        BpodSystem.StartModuleRelay(['Serial' num2str(port)]);
    elseif state == 0
        BpodSystem.StopModuleRelay(['Serial' num2str(port)]);
    end

end

function set_reduced_baudrate(port, state)
    global BpodSystem;

    BpodSystem.SerialPort.flush();
    BpodSystem.SerialPort.write('B', 'char', port, 'uint8', state, 'uint8'); % Send B command with the port to adjust, and the state to place the port in

    new_baud = BpodSystem.SerialPort.read(1, 'uint32'); % Read 1 uint32 (4 bytes) from the BPOD; new baudrate
    success_byte = BpodSystem.SerialPort.read(1, 'uint8'); % Read 1 uint8 (1 byte) from the BPOD; success byte

    if new_baud ~= 57600 || success_byte ~= 1
        error(['Error setting reduced baudrate for port: ' num2str(port)]);
    end
end