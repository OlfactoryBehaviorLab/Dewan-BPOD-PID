%% Dewan Lab BPOD Lick Training Protocol
%% Adapted from Dewan Lab Lick Training Voyeur Protocol
%% Austin Pauley, 2023

%#ok<*NASGU,*STRNU,*DEFNU,*INUSD,*NUSED> 

function lick_training % Protocol Name
global BpodSystem % BPOD System Variable

% Some definitions
LEFT = 1;
RIGHT = 2;
BOTH = 3; 

% Settings go here
settings_struct = struct; % Create settings struct
settings = BpodSystem.ProtocolSettings; % Load settings from file
if isempty(fieldnames(settings_struct)) % If the settings file doesn't exist, load some default params
    % Times
    settings_struct.number_of_trials = 200;
    settings_struct.ITI_seconds = 2;
    settings_struct.FV_duration = 0;
    settings_struct.grace_period = 0;
    settings_struct.trial_duration = 1000000;
    settings.FV_duration_seconds = 2;

    % "Punish" Settings
    settings_struct.ITI_punish_multiplier = 1.5;
    settings_struct.punish = false;

    % Reward Settings
    settings_struct.water_solenoid_duration = 0;
    settings_struct.water_solenoid_duration_2 = 0;
    settings_struct.reward_volume = 20; 

    % ???
    settings_struct.correct_choice = LEFT;

    % Print default settings
    disp('No settings file found, loading default values!')
    % print_settings(settings_struct)
    
end
% TODO: add GUI for some settings
% BpodParameterGUI('init', settings_struct)

% Trial Types: 1 = LEFT, 2 = RIGHT, 3 = both
trial_types = repelem([1 2 3], ceil(settings_struct.number_of_trials/3)); % Generate list of num_of_trials/3 repeats of each trial type
trial_types = trial_types(randPerm(length(trial_types))); % Shuffle the list of trial types


% Final Valve States: 1 = ON, 2 = OFF
final_valve_states = repelem([1 2], settings_struct.number_of_trials/2); % Generate list of num_of_trials/2 repeats of each final valve state
final_valve_states = final_valve_states(randperm(length(final_valve_states))); % Shuffle the list of final_valve_states



% Get Water Valve Timing
reward_times = GetValveTiems(settings_struct.reward_volume, [1, 2]);
settings_struct.water_solenoid_duration = reward_times(1);
settings_struct.water_solenoid_duration_2 = reward_times(2); 

% Initialize Plots Here
% Dunno what happens here

for current_trial = 1:settings_struct.number_of_trials
    % Update settings GUI

    % Get trial parameters
    tiral_parameters = get_current_trial_params(settings_struct, trial_types, final_valve_states, current_trial);

    % Tup occurs when the itnernal timer elapses

    sma = NewStateMatrix(); % Create new state machine

    sma = AddState(sma, 'Name', 'Wait', 'Timer', 0, 'StateChangeConditions', {'SOME START EVENT HERE', 'SetFV'}, 'OutputActions', {}); % Wait State; probably not needed, but here for now
    sma = AddState(sma, 'Name', 'SetFV', 'Timer', 0, 'StateChangeConditions', {'Tup', 'Wait4Response'}, 'OutputActions', {'FinalValve', tiral_parameters.final_valve_state}); % Actuate (or don't) Final Valve for pressure spike
    sma = AddState(sma, 'Name', 'Wait4Response', 'Timer', settings_struct.trial_duration, 'StateChangeConditions', {'Tup', 'GiveWater', 'LICKY LICK', 'RewardAnimal'}, 'OutputActions', {}); % Wait for licky licky tube
    sma = AddState(sma, 'Name', 'GiveWater', 'Timer', settings_struct.water_solenoid_duration, 'StateChangeConditions', {'Tup', 'DeactivateFV'}, 'OutputActions', {'ValveState', 1}); % I DON'T NEED IT, I DON'T NEED IT..... I NEEEDDD ITTTTTTTT
    sma = AddState(sma, 'Name', 'DeactivateFV', 'Timer', 0, 'StateChangeConditions', {}, 'OutputActions', {'FinalValve', 0}); % Turn off FV, if its already off, it stays off
    sma = AddState(sma, 'Name', 'ITI', 'Timer', settings_struct.ITI, 'StateChangeConditions', {}, 'OutputActions', {}); % And now, we wait...

    SendStateMatrix(sma); % Send the state machine to the BPOD to run for this trial

    trial_data = RunStateMatrix; % Get return data

    BpodSystem.Data = AddTrialEvents(BpodSystem.Data, trial_data); % Add the returned data to the global data store

    SaveBpodSessionData; % Save the data to disk
    HandlePauseCondition; % Pause here if the user paused 

    if BpodSystem.BeingUsed == 0 % Exit if the user has ended the experiment
        return
    end
 
end

% 1. Wait for start
% 2. Wait for ITI
% 2a. When ITI is over, set start time -> now, turn LED on
% 3. Do we turn the FV on for this trial?
% 4. Chose trial type:
    % right
    % left
    % right/left
% 5: Trial Types:
    %5a: Right Lick Circuit Trial
        % If animal licks right, give H2O, if animal licks left, no H2O
    %5b: Left Lick Circuit Trial
        % If animal licks left, give H2O, if animal licks right, no H2O
    %5c: Left or Right Lick Circuit Trial
        % If animal licks either left/right, they get H2O
% Shut everything off
    % LED, FV
    
end

function [] = print_settings(settings_struct)
    struct_items = fieldnames(settings_struct);

    for i = 1:length(struct_items)
        value = settings_struct.(char(struct_items(i)));
        % text = sprintf("%s: %d", char(struct_items(i)), char(value));
        % disp(text);
        fprintf("%s: %d", char(struct_items(i)), char(value))
    end
end


function trial_parameters = get_current_trial_params(settings_struct, trial_types, final_valve_states, current_trial)
    trial_parameters = struct;

    switch trial_types(current_trial)        
        case 1 % LEFT
            trial_parameters.left_lick_action = 'water';
            trial_parameters.right_lick_action = 'punish';
        case 2 % RIGHT
            trial_parameters.left_lick_action = 'punish';
            trial_parameters.right_lick_action = 'water';
        case 3 % EITHER
            trial_parameters.left_lick_action = 'water';
            trial_parameters.right_lick_action = 'water';
    end

    switch final_valve_states(current_trial)
        case 1 % OFF
            trial_parameters.final_valve_state = 1;
        case 2 % OFF
            trial_parameters.final_valve_state = 2;
    end

end % Protocol Definition End
