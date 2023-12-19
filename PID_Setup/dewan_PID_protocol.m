%#ok<*NASGU,*STRNU,*DEFNU,*INUSD,*NUSED,*GVMIS> 
function dewan_PID_protocol
global BpodSystem;

%% If Bpod has not been loaded, load it
if isempty(BpodSystem)
    Bpod;
end

trial_manager = BpodTrialManager;
is_streaming = 0;

%% Load needed modules
analog_in = setup_analog_input('COM9');
load_valve_driver_commands();

global startup_params;
%startup_params = pid_startup_gui(); % Get Startup Parameters
%main_gui = pid_main_gui(startup_params.session_type); % Launch Main GUI, no need to wait

main_gui = pid_main_gui("PID", @run_PID); % Launch Main GUI, no need to wait


function run_PID(~, ~, main_gui)
        Settings = get_settings(main_gui, startup_params);
        sma = generate_state_machine(BpodSystem, Settings); % Generate first trial's state machine
        disp(sma);
        trial_manager.startTrial(sma);
        Events = trial_manager.getTrialData;
        disp(Events);

    % for i = 1:3
    %     Events = trial_manager.getTrialData;
    %     Settings = get_settings(main_gui, startup_params);
    %     sma = generate_state_machine(BpodSystem, Settings); % Generate first trial's state machine
    %     trial_manager.startTrial(sma)
    % end
    % for current_trial = 1:Settings.number_of_trials
    %     data = trial_manager.getTrialData();
    % end
end

function Settings = get_settings(main_gui, startup_params)
    global Settings;
    user_params = main_gui.get_params(); % Get settings from the GUI
    Settings = merge_structs(startup_params, user_params); % Merge startup config with users settings
end


function sma = generate_state_machine(BpodSystem, Settings)
    sma = NewStateMatrix();

    % Analog1In event key:
    %   S: Trial Start
    %   P: Solvent odor pretrial duration
    %   F: FV Actuation (Odor Duration)
    %   C: FV Close for second solvent duration
    %   E: Trial End (Close everything)

    odor_preduration = Settings.odor_preduration / 1000;
    odor_duration = Settings.odor_duration / 1000;
    solvent_preduration = odor_duration - odor_preduration;
    solvent_duration = odor_duration;

    disp(odor_preduration)
    disp(odor_duration)

    switch Settings.trial_type
        case 'Odor'
            sma = AddState(sma, 'Name', 'PreTrialDuration', 'Timer', odor_preduration, 'StateChangeConditions', {'Tup', 'PID_Measurement'}, 'OutputActions', {'AnalogIn1', ['#' 'S'], 'ValveModule1', [66 48]}); % Open vial 3 & 4 (valve 5 & 6) and wait for equalization
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'All_Off'}, 'OutputActions', {'AnalogIn1', ['#' 'F'],'ValveModule1', [66 49]}); % Open FV (valve 1) for odor duration
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 00, 'StateChangeConditions', {'Tup', 'End'}, 'OutputActions', {'AnalogIn1', ['#' 'E'],'ValveModule1', [66 0]}); % Close everything
            sma = AddState(sma, 'Name', 'End', 'Timer', 0, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {}); % Close everything
        case 'Pure'
            sma = AddState(sma, 'Name', 'PreTrialDuration', 'Timer', odor_preduration, 'StateChangeConditions', {'Tup', 'PID_Measurement'}, 'OutputActions', {'AnalogIn1', ['#' 'S'], 'ValveModule1', 1}); % Open vial 1 & 2 (valve 7 & 8) and wait for equalization8
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'All_Off'}, 'OutputActions', {'AnalogIn1', ['#' 'F'], 'ValveModule1', 2}); % Open FV (valve 1) for odor duration
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {'AnalogIn1', ['#' 'E'], 'ValveModule1', 5}); % Close everything
        case 'Solvent'
            sma = AddState(sma, 'Name', 'PreTrialSolvent', 'Timer', solvent_preduration, 'StateChangeConditions', {'Tup', 'PreTrialOdor'}, 'OutputActions', {'AnalogIn1', ['#' 'S'], 'ValveModule1', 1}); % Turn on vial 1 & 2 (valve 7 & 8) for solvent measurement
            sma = AddState(sma, 'Name', 'PreTrialOdor', 'Timer', odor_preduration, 'StateChangeConditions', {'Tup', 'PID_measurement'}, 'OutputActions', {'AnalogIn1', ['#' 'P'], 'ValveModule1', 3}); % Turn on vial 3 & 4 (valve 5 & 6) so odor can equalize; leave solvent valves on
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'OdorOff'}, 'OutputActions', {'AnalogIn1', ['#' 'F'], 'ValveModule1', 5}); % Open FV (valve 1) for odor duration; turn off valve 7 & 8
            sma = AddState(sma, 'Name', 'OdorOff', 'Timer', solvent_duration, 'StateChangeConditions', {'Tup', 'AllOff'}, 'OutputActions', {'AnalogIn1', ['#' 'C'], 'ValveModule1', 1}); % Closes odor vial and actuates FV; allows solvent to PID 
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {'AnalogIn1', ['#' 'E'], 'ValveModule1', 6}); % Close everything
        case 'CAL'
        case 'KIN'
            % Stuff goes here later

    end
end

function generate_trial_parameters(BpodSystem, Settings)
    parameters = {}; % Container for all the trial parameters
end

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
    %a_in.startModuleStream();
    %a_in.startReportingEvents();
    %a_in.startUSBStream();


end

function load_valve_driver_commands()
    % 1. B192 = 11000000; Valve 7 & 8 ON; Solvent Vial On
    % 2. B193 = 11000001; Valve 7 & 8 ON | FV ON; Solvent Vial On
    % 3. B240 = 11110000; All Valves ON except FV; for solvent trial + odor pretrial duration
    % 4. B48 = 00110000; Valve 6 & 5 ON; Odor Vial On
    % 5. B49 = 00110001; Valve 6 & 5 ON | FV ON; Odor Vial On
    % 6. B0 = 00000000; All OFF

    success = LoadSerialMessages('ValveModule1', {[66 192], [66 193], [66 240], [66 48], [66 49], [66 0]}); 


    if success ~= 1
        error("Error sending commands to the valve driver module!")
    end
end

function stop_streaming(a_in)
    is_streaming = 0;
    a_in.stopModuleStream();
    a_in.stopReportingEvents();
    a_in.stopUSBStream();
end

function start_streaming(a_in)
    a_in.startModuleStream();
    a_in.startReportingEvents();
    a_in.startUSBStream();
    is_streaming = 1;
end

function stream_analog_data(a_in)
    % Adapted from BpodAnalogIn updatePlot function
    % Copyright (C) 2023 Sanworks LLC, Rochester, New York, USA
    % Modified and redistributed under GNU General Public License v3

    if is_streaming == 0
        fprintf('Error, the Analog input module is not streaming data!');
        return
    end

    num_bytes_to_read = a_in.Port.bytesAvailable;
    num_bytes_per_frame = 4; % num frames (1) * 2 + 2

    if num_bytes_to_read > num_bytes_per_frame % Are there at least 4 bytes (1 frame) available to read?
        number_of_bytes_to_read = floor(num_bytes_to_read/num_bytes_per_frame) * num_bytes_per_frame; % Depending on sampling rate, there may be multiple bytes to read
        data = a_in.Port.read(number_of_bytes_to_read, 'uint8'); % Read in the data
        data_prefix = data(1); % The first byte should be an identifier prefix

        if data_prefix == 'R' || data_prefix == '#' % R is raw data, # is sync events
            prefixes = data(1:num_bytes_per_frame:end); % Looks every 4 bytes for prefixes
            data(1:num_bytes_per_frame:end) = []; % Remove prefixes from the data stream
            sync_signals = data(1:num_bytes_per_frame-1:end); % Sync byte is now every third byte in frame (originally the second byte)
            data(1:num_bytes_per_frame-1:end) = []; % Remove the sync data from the data stream

            data_samples = typecast(data(1:end), 'uint16'); % Cast all the data to ints
            num_data_samples = length(data_samples); % Get the number of samples

            sync_prefixes = (prefixes == '#'); % Look and see if any of the frames received are for sync events
            num_sync_events = sum(sync_prefixes); % Number of sync events present
            sync_prefixes_index = find(sync_prefixes); % Get sync events indexes
           
            data_samples_volts = bits2volts(a_in, data_samples); % Convert raw signal in bits to volts

            if a_in.USBstream2File % If streaming to USB
                data_to_write(1, :) = data_samples; %  raw bits
                data_to_write(2, :) = data_samples_volts; % volts
            end

            if num_sync_events > 0
                a_in.USBstreamFile.SyncEvents(1, a_in.USBFile_EventPos:a_in.USBFile_EventPos+num_sync_events-1) = double(sync_signals(sync_prefixes)); % Save the sync signals
                a_in.USBstreamFile.SyncEventTimes(1, a_in.USBFile_EventPos:a_in.USBFile_EventPos+num_sync_events-1) = double((sync_prefixes_index + a_in.USBFile.USBFile_SamplePos -1)); % Not really sure how, but the indexes and sample indexes are used to save times?
                a_in.USBFile_EventPos = a_in.USBFile_EventPos + num_sync_events;
            end

            a_in.USBFile_SamplePos = a_in.USBFile_SamplePos + num_data_samples;
        else
            stop(a_in.Timer);
            delete(a_in.Timer);
            error('Error: invalid frame returned.')
        end
    end
        

    end

    function voltage = bits2volts(a_in, new_samples)
        % 16-bit ADC
        % 0V-10V: 0-65,536 bits
        % 1V = 6,553.6 bits
        % bits / 6,553.6 = volts

        voltage = 0;

        range_index = a_in.RangeIndex(1); % Get range index for channel 1

        voltage_range = a_in.RangeVoltageSpan(range_index); % Get voltage range (usually 0V-10V) for channel 1
        voltage_offset = a_in.RangeOffsets(range_index); % Get the voltage offset (if there is one) for channel 1

        voltage = ((double(new_samples)/a_in.chBits -1) * voltage_range) - voltage_offset; % samples / num_of_bits * range - offset = volts

    end

end

function Settings = merge_structs(startup, trial_props)
    % Adapted from Stack Overflow user Barpa's Mar. 17, 2013 Answer
    % https://stackoverflow.com/questions/15456627/how-to-simply-concatenate-two-structures-with-different-fields-in-matlab

    field_names = [fieldnames(startup); fieldnames(trial_props)];
    combined_settings = [struct2cell(startup); struct2cell(trial_props)];

    Settings = cell2struct(combined_settings, field_names, 1);
end