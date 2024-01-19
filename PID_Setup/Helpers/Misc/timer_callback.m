function timer_callback(main_gui)

    avg_volt, samples = get_analog_data();
    update_gui(main_gui, avg_volt, samples);

end