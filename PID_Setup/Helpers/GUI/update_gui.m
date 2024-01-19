function update_gui(main_gui, average_voltage, data_samples)
    main_gui.update_voltage(average_voltage); %% Update the voltage shown on the GUI gauge

    estimated_ppm = calculate_PPM(data_samples); % Convert BITS -> PPM
    main_gui.update_PPM(estimated_ppm); % Update the PPM field in the GUI
end

function PPM = calculate_PPM(data_samples)
    global BpodSystem;

    gain = BpodSystem.Data.update_gui_params.gain;
    CF = BpodSystem.Data.update_gui_params.cf;
    calibration = [];
    switch(gain) % Select the correct calibration for our current gain
        case 'x1'
            calibration = BpodSystem.Data.update_gui_params.calibration_1;
        case 'x5'
            calibration = BpodSystem.Data.update_gui_params.calibration_5;
        case 'x10'
            calibration = BpodSystem.Data.update_gui_params.calibration_10;
    end

    average_sample = mean(data_samples); % Average the samples together
    PPM = double(average_sample / calibration); % Divide average by calibration to get PPM isobutylene
    PPM = round(PPM * CF); % Multiply PPM isobutylene by CF to get PPM odor

end