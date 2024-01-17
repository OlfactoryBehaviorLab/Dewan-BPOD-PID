function update_gui(main_gui, average_voltage, data_samples)
    main_gui.update_voltage(average_voltage);

    estimated_ppm = calculate_PPM(data_samples);
    main_gui.update_PPM(estimated_ppm);
end

function PPM = calculate_PPM(data_samples)
    global BpodSystem;
    PPM = [];

    gain = BpodSystem.Data.update_gui_params.gain;
    calibration = [];
    switch(gain)
        case 'x1'
            calibration = BpodSystem.Data.update_gui_params.calibration_1;
        case 'x5'
            calibration = BpodSystem.Data.update_gui_params.calibration_5;
        case 'x10'
            calibration = BpodSystem.Data.update_gui_params.calibration_10;
    end

    average_sample = mean(data_samples);
    PPM = average_sample / calibration;

end