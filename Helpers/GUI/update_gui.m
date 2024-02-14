function update_gui(main_gui)

    gain = main_gui.get_params.pid_gain;

    [voltage, estimated_ppm] = get_data(gain);
    % disp(sprintf('Estimated PPM: %g', estimated_ppm));
    % disp(sprintf('Voltage: %g', voltage));

    main_gui.update_voltage(voltage); %% Update the voltage shown on the GUI gauge
    main_gui.update_PPM(estimated_ppm); % Update the PPM field in the GUI
end


function [voltage, PPM] = get_data(gain)
    global BpodSystem;
    
    voltage = 0;
    PPM = 0;

    analog_data_index = length(BpodSystem.Data.analog_stream_swap);

    if isempty(analog_data_index)% Wait for there to be at least one packet
        disp('return early');
    else
        analog_data = BpodSystem.Data.analog_stream_swap(analog_data_index);
        samples = analog_data.samples; % Get the samples (bits)
        samples_volts = analog_data.samples_volts; % Get the samples (volts)
        voltage = mean(samples_volts); % Average all the voltage samples
        PPM = calculate_PPM(samples, gain); % Calculate the PPM
    end
    
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