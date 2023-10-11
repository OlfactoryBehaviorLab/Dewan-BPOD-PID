%#ok<*NASGU,*STRNU,*DEFNU,*INUSD,*NUSED,*GVMIS> 
function dewan_PID_protocol
global BpodSystem;
trial_manager = BpodTrialManager;
is_streaming = 0;
% analog_in = setup_analog_input('COM9');
% analog_in.scope();

if isempty(analog_in)
    return
end

success = LoadSerialMessages('ValveModule1', {['B' 48], ['B' 192], ['O' 1], ['B' 0]}); 
% 1. B48 = 00110000; Valve 6 & 5 ON; Odor Vial On
% 2. B192 = 11000000; Valve 7 & 8 ON; Solvent Vial On
% 3. O1 = FV ON
% 4. B0 = 00000000; All OFF
if success ~= 1
    disp("Error sending commands to the valve driver module!")
    return
end

%startup = pid_startup_gui(); % Get Startup Parameters
%main_gui = pid_main_gui(startup.session_type); % Launch Main GUI, no need to wait

main_gui = pid_main_gui("PID"); % Launch Main GUI, no need to wait


function sma = generate_state_machine(BpodSystem, Settings)
    sma = NewStateMatrix();

    
    pre_trial_odor_time = 0.5;
    pre_trial_solvent_time = 2;
    odor_duration = 2;
    post_trial_solvent_time = 2;

    switch Settings.experiment_type
        case 'PID'
        case 'CF'
            sma = AddState(sma, 'Name', 'PreTrialDuration', 'Timer', pre_trial_time, 'StateChangeConditions', {'Tup', 'PID_Measurement'}, 'OutputActions', {'ValveModule1', 1}); % Open vial 3 & 4 (valve 5 & 6) and wait for equalization
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'All_Off'}, 'OutputActions', {'ValveModule1', 3}); % Open FV (valve 1) for odor duration
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {'ValveModule1', 4}); % Close everything
        case 'PURE'
            sma = AddState(sma, 'Name', 'PreTrialDuration', 'Timer', pre_trial_time, 'StateChangeConditions', {'Tup', 'PID_Measurement'}, 'OutputActions', {'ValveModule1', 2}); % Open vial 1 & 2 (valve 7 & 8) and wait for equalization8
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'All_Off'}, 'OutputActions', {'ValveModule1', 3}); % Open FV (valve 1) for odor duration
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {'ValveModule1', 4}); % Close everything
        case 'SOLVENT'
            sma = AddState(sma, 'Name', 'PreTrialSolvent', 'Timer', pre_trial_solvent_time, 'StateChangeConditions', {'Tup', 'PreTrialOdor'}, 'OutputActions', {'ValveModule1', 2}); % Turn on vial 1 & 2 (valve 7 & 8) for pre_trial_solvent_time
            sma = AddState(sma, 'Name', 'PreTrialOdor', 'Timer', pre_trial_odor_time, 'StateChangeConditions', {'Tup', 'PID_measurement'}, 'OutputActions', {'ValveModule1', 1}); % Turn on vial 3 & 4 (valve 5 & 6) so odor can equalize
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'OdorOff'}, 'OutputActions', {'ValveModule1', 3}); % Open FV (valve 1) for odor duration
            sma = AddState(sma, 'Name', 'OdorOff', 'Timer', post_trial_solvent_time, 'StateChangeConditions', {'Tup', 'AllOff'}, 'OutputActions', {'ValveModule1', 2}); % Closes odor vial and actuates FV; allows solvent to PID
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {'ValveModule1', 4}); % Close everything
        case 'CAL'
        case 'KIN'
            % Stuff goes here later
        

    end
end

function generate_experiment_parameters(BpodSystem, Settings)

end

function a_in = setup_analog_input(COM)
    try
        a_in = BpodAnalogIn(COM);
    catch
        a_in = [];
        disp('Error connecting to analog input on COM: %s', string(COM));
    end
    a_in.InputRange(1) = {"0V:10V"};
    a_in.nActiveChannels = 1;
    a_in.Thresholds(1) = 10;
    a_in.ResetVoltages(1) = 9.95;
    a_in.SMeventsEnabled(1) = 1;
    a_in.Stream2USB(1) = 1;
    a_in.startModuleStream();
    a_in.startReportingEvents();
    a_in.startUSBStream();
    is_streaming = 1;

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

    num_bytes_to_read = a_in.bytesAvailable;
    num_bytes_per_frame = 4; % num frames (1) * 2 + 2

    if num_bytes_to_read > num_bytes_per_frame
        number_of_bytes_to_read = floor(num_bytes_to_read/num_bytes_per_frame) * num_bytes_per_frame; % Depending on sampling rate, there may be multiple bytes to read
        data = a_in.read(number_of_bytes_to_read, 'uint8'); % Read in the data
        data_prefix = data(1); % The first byte should be an identifier prefix

        if data_prefix == 'R' || data_prefix == '#' % R is raw data, # is sync events
            prefixes = data(1:num_bytes_per_frame:end); % Looks every 4 bytes for prefixes
            [~, prefix_indexes] = intersect(prefixes, data, 'stable'); % Get the indexes for each prefix
            data(prefix_indexes) = []; % Remove prefixes from the data stream
            
        end
    end
        

    end

end