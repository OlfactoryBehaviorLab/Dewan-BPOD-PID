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

FINAL_VALVE = 'Valve1';
WATER_SOLENOID = 'Valve2';

% Settings go here
settings_struct = struct; % Create settings struct
settings = BpodSystem.ProtocolSettings; % Load settings from file
if isempty(fieldnames(settings_struct)) % If the settings file doesn't exist, load some default params
    % User Configurables
    settings_struct.GUI.FV_state = 1; % 1 = OFF, 2 = ON
    settings_struct.GUI.trial_type = 1; % Trial Types: 1 = LEFT, 2 = RIGHT, 3 = both
    settings_struct.GUI.number_of_trials = 200;
    settings_struct.GUI.reward_volume = 1.5; %uL

    settings_struct.GUI.start_training = 'StartTraining(1)'; % Button placeholder
    settings_struct.GUI.pause_training = 'PauseTraining(1)'; % Button placeholder


    settings_struct.GUIMeta.FV_state.Style = 'popupmenu';
    settings_struct.GUIMeta.FV_state.String = {'ON', 'OFF'};

    settings_struct.GUIMeta.trial_type.Style = 'popupmenu';
    settings_struct.GUIMeta.FV_state.String = {'LEFT', 'RIGHT', 'BOTH'};

    settings_struct.GUIMeta.start_training.Style = 'pushbutton';
    settings_struct.GUIMeta.start_training.String = 'Start!';

    settings_struct.GUIMeta.pause_training.Style = 'pushbutton';
    settings_struct.GUIMeta.pause_training.String = 'Pause!';

    
    settings_struct.GUIPanels.Configurables = {'FV_state', 'trial_type', 'number_of_trials'};
    settings_struct.GUIPanels.Controls = {'start_training', 'pause_training'};
    

    % Static Settings
    settings_struct.ITI_seconds = 2;
    settings_struct.FV_duration_seconds = 2;
    settings_struct.grace_period = 0;

    % Reward Settings
    settings_struct.water_solenoid_duration = 0;
    settings_struct.water_solenoid_duration_2 = 0;
    

    % Print default settings
    disp('No settings file found, loading default values!')
    % print_settings(settings_struct)
    
end

BpodParameterGUI('init', settings_struct)

% Initialize Plots Here
% Dunno what happens here

session_parameters = get_session_params(settings_struct);


for current_trial = 1:settings_struct.number_of_trials
    % Update settings GUI

    % Get trial parameters

    % Tup occurs when the itnernal timer elapses

    sma = NewStateMatrix(); % Create new state machine

    sma = AddState(sma, 'Name', 'ResponsePeriod', 'Timer', settings_struct.FV_duration_seconds, 'StateChangeConditions', {'Tup', 'ITI', session_parameters.active_in, 'GiveWater'}, ...
                'OutputActions', {FINAL_VALVE, session_parameters.final_valve_state}); 
    % State 1: Response Window
    % Give the animal FV_duration_seconds seconds to respond by licking
    % If the animal does not lick within the window, we skip to the ITI
    % If the animal does lick within the window, we provide a water reward
    % Final Valve is automatically set based on user settings

    sma = AddState(sma, 'Name', 'GiveWater', 'Timer', session_parameters.water_solenoid_duration, 'StateChangeConditions', {'Tup', 'ITI'}, 'OutputActions', {WATER_SOLENOID, 1}); % I DON'T NEED IT, I DON'T NEED IT..... I NEEEDDD ITTTTTTTT
    % State 2: Water Reward
    % If the animal licks during the response period, open the water valve for the length of the state and then jump to ITI
    % When the State ends, Josh indicated the valves will automatically deenergize

    sma = AddState(sma, 'Name', 'ITI', 'Timer', settings_struct.ITI_seconds, 'StateChangeConditions', {'Tup', 'ResponsePeriod'});
    % State 3: ITI
    % If the animal fails to lick in time, or a water award has been provided, wait the ITI, and then start another response window

    SendStateMatrix(sma); % Send the state machine to the BPOD to run for this trial

    trial_data = RunStateMatrix; % Get return data

    BpodSystem.Data = AddTrialEvents(BpodSystem.Data, trial_data); % Add the returned data to the global data store

    SaveBpodSessionData; % Save the data to disk
    HandlePauseCondition; % Pause here if the user paused 

    if BpodSystem.BeingUsed == 0 % Exit if the user has ended the experiment
        return
    end
 
end

    
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


function session_parameters = get_session_params(settings_struct)
    session_parameters = struct;

    session_parameters.water_solenoid_duration = GetValveTunes(settings_struct.GUI.reward_volume, [2]);

    switch settings_struct.FV_state
        case 'ON'
            session_parameters.final_valve_state = 1;
        case 'OFF'
            session_parameters.final_valve_state = 0;
    end

    switch settings_struct.trial_type
        case 'LEFT' %left
            session_parameters.active_in = 'port1In';
        case 'RIGHT' %right
            session_parameters.active_in = 'port2In';
    end

       
end