function timer_callback(main_gui)
    %% Callback function to execute shared tasks instead of lumping everything in one place
    avg_volt, samples = get_analog_data(); % Get data back from the analog input module and save it
    update_gui(main_gui, avg_volt, samples); % Update the GUI
end