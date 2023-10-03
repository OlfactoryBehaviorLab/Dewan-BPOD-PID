function dewan_PID_protocol
global BpodSystem;

LoadSerialMessages('ValveModule1', {['B' 48], ['O' 1], ['B' 0]}); %48 = 00110000



end

function sma = generate_state_machine(BpodSystem, Settings)
sma = NewStateMatrix();

pre_trial_time = 0;
odor_duration = 0;

switch Settings.experiment_type
% Open vial 3 & 4 for ~pre_trial duration
% leave 3 & 4 open, switch FV for odor_dur seconds, record data
% turn it all off
case 'CF'
    sma = AddState(sma, 'Name', 'PreTrialDuration', 'Timer', pre_trial_time, 'StateChangeConditions', {'Tup', 'PID_Measurement'}, 'OutputActions', {'ValveModule1', 1});
    sma = AddState(sma, 'Name', 'OdorDuration', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'All_Off'}, 'OutputActions', {'ValveModule1', 2});
    sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {'ValveModule1', 3});
case 'PID'

case 'CAL'

case 'KIN'

end
end

function generate_experiment_parameters(BpodSystem, Settings)

end