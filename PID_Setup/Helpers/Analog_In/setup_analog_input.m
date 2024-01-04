function a_in = setup_analog_input(COM)
    try
        a_in = BpodAnalogIn(COM);
    catch
        a_in = [];
        error('Error connecting to analog input on COM: %s', string(COM));
    end

    a_in.InputRange(1) = {"0V:10V"};
    a_in.nActiveChannels = 1;
    a_in.Thresholds(1) = 10;
    a_in.ResetVoltages(1) = 9.95;
    a_in.SMeventsEnabled(1) = 1;
    a_in.Stream2USB(1) = 1;

end