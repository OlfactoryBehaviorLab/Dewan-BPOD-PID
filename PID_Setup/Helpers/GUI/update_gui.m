function update_gui(main_gui)

    [voltage, estimated_ppm] = get_data();
    disp([estimated_ppm]);


    main_gui.update_voltage(voltage); %% Update the voltage shown on the GUI gauge
    main_gui.update_PPM(estimated_ppm); % Update the PPM field in the GUI
end

function PPM = calculate_PPM(data_samples, gain)
    global BpodSystem;

    CF = BpodSystem.Data.ExperimentParams.CF;
    calibration = [];
    switch(gain) % Select the correct calibration for our current gain
        case 'x1'
            calibration = BpodSystem.Data.ExperimentParams.x1;
        case 'x5'
            calibration = BpodSystem.Data.ExperimentParams.x5;
        case 'x10'
            calibration = BpodSystem.Data.ExperimentParams.x10;
    end

    average_sample = mean(data_samples); % Average the samples together
    PPM = double(average_sample / calibration); % Divide average by calibration to get PPM isobutylene
    PPM = round(PPM * CF); % Multiply PPM isobutylene by CF to get PPM odor

end

function [voltage, PPM] = get_data()
    global BpodSystem;

    all_analog_data = BpodSystem.Data.analog_stream_swap; %Get the most recent data packet
    analog_data_index = length(all_analog_data);

    if analog_data_index == 0 % Wait for there to be at least one packet
        voltage = 0;
        PPM = 0;
        return
    end

    try
        gain = BpodSystem.Data.Settings(end).pid_gain;

        analog_data = all_analog_data(analog_data_index);
        samples = analog_data.samples; % Get the samples (bits)
        samples_volts = analog_data.samples_volts; % Get the samples (volts)

        voltage = mean(samples_volts); % Average all the voltage samples
        PPM = calculate_PPM(samples, gain); % Calculate the PPM
    catch error
        disp(error);
    end

end