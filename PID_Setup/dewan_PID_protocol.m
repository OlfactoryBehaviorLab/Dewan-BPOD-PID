%#ok<*NASGU,*STRNU,*DEFNU,*INUSD,*NUSED,*GVMIS> 
function dewan_PID_protocol
global BpodSystem;
trial_manager = BpodTrialManager;
% analog_in = setup_analog_input('COM9');
% analog_in.scope();

% if isempty(analog_in)
%     disp("Error connecting to analog input module!")
%     return
% end

success = LoadSerialMessages('ValveModule1', {['B' 48], ['B' 192] ['O' 1], ['B' 0]}); 
% 1. B48 = 00110000; Valve 6 & 5 ON; Odor Vial On
% 2. O1 = FV ON
% 3. B0 = 00000000; All OFF
% 4. B192 = 11000000; Valve 7 & 8 ON; Solvent Vial On
if success ~= 1
    disp("Error connecting to the valve driver module!")
    return
end

%startup = pid_startup_gui(); % Get Startup Parameters
%main_gui = pid_main_gui(startup.session_type); % Launch Main GUI, no need to wait

main_gui = pid_main_gui("PID"); % Launch Main GUI, no need to wait

for i = 0:10
    main_gui.update_voltage(i)
end

for j = 10:-1:0
    main_gui.update_voltage(j)
end


disp("test");

end

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
        

    end
end

function generate_experiment_parameters(BpodSystem, Settings)

end

function analog_in = setup_analog_input(COM)
    analog_in = BpodAnalogIn(COM);
    analog_in.InputRange(1) = {"0V:10V"};
    analog_in.nActiveChannels = 1;
    analog_in.Thresholds(1) = 10;
    analog_in.ResetVoltages(1) = 9.95;
    analog_in.SMeventsEnabled(1) = 1;
end