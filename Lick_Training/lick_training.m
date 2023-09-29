%% Dewan Lab BPOD Lick Training Protocol
%% Adapted from Dewan Lab Lick Training Voyeur Protocol
%% Austin Pauley, 2023

%#ok<*NASGU,*STRNU,*DEFNU,*INUSD,*NUSED,*GVMIS> 

function lick_training % Protocol Name
global BpodSystem % BPOD System Variable

% Some definitions
LEFT = 1;
RIGHT = 2;
BOTH = 3; 

FINAL_VALVE = 'Valve1';
WATER_SOLENOID = 'Valve2';
LED = 'PWM1';



correct_attempts = 0;

% Settings go here
settings_struct = BpodSystem.ProtocolSettings; % Load settings from file


if isempty(settings_struct) % If the settings file doesn't exist, load some default params
    disp('No settings file found, loading default values!')
    % User Configurables
    settings_struct.GUI.FV_state = 1; % 1 = ON, 2 = OFF
    settings_struct.GUI.trial_type = LEFT; % Trial Types: 1 = LEFT, 2 = RIGHT, 3 = both
    settings_struct.GUI.number_of_trials = 200;
    settings_struct.GUI.water_volume = 1.5; %uL
    settings_struct.GUIMeta.water_volume.Style = 'edit';
    settings_struct.GUIMeta.FV_state.Style = 'popupmenu';
    settings_struct.GUIMeta.FV_state.String = {'ON', 'OFF'};
    settings_struct.GUIMeta.trial_type.Style = 'popupmenu';
    settings_struct.GUIMeta.trial_type.String = {'LEFT', 'RIGHT', 'BOTH'};

    % Controls
    settings_struct.GUI.start_training = 'start_training_func(BpodSystem)'; % button callbacks MUST be their own script it appears....
    settings_struct.GUI.pause_training = 'pause_training_func(BpodSystem)';
    settings_struct.GUIMeta.start_training.Style = 'pushbutton';
    settings_struct.GUIMeta.pause_training.Style = 'pushbutton';


    % Statistics
    settings_struct.GUI.CurrentTrial = 1;
    settings_struct.GUI.CorrectTrials = 0;
    settings_struct.GUI.Performance = '0%';
    settings_struct.GUI.TotalWater = '0uL';
    settings_struct.GUIMeta.CurrentTrial.Style = 'text';
    settings_struct.GUIMeta.CorrectTrials.Style = 'text';
    settings_struct.GUIMeta.Performance.Style = 'text';
    settings_struct.GUIMeta.TotalWater.Style = 'text';


    % Static Settings
    settings_struct.GUI.ITI_seconds = 2;
    settings_struct.GUI.FV_duration_seconds = 2;
    settings_struct.GUIMeta.ITI_seconds.Style = 'text';
    settings_struct.GUIMeta.FV_duration_seconds.Style = 'text';
    settings_struct.grace_period = 0;

    % Reward Settings
    settings_struct.water_solenoid_duration = 0;
    settings_struct.water_solenoid_duration_2 = 0;

    % Panels
    settings_struct.GUIPanels.Configurables = {'FV_state', 'trial_type', 'number_of_trials', 'water_volume'};
    settings_struct.GUIPanels.Static_Settings = {'ITI_seconds', 'FV_duration_seconds'};
    settings_struct.GUIPanels.Controls = {'start_training', 'pause_training'};
    settings_struct.GUIPanels.Statistics = {'CurrentTrial', 'CorrectTrials', 'Performance', 'TotalWater'};
    

    
end

BpodParameterGUI('init', settings_struct); % Initialize the GUI

% Initialize Plots Here
% Dunno what happens here


BpodSystem.Status.Pause = 1; % Auto-Pause the session so we can enter configuration information

while BpodSystem.Status.Pause == 1 
    pause(0.25); % Need to pause locally as well to ensure that the GUI changes are synced
end

settings_struct = BpodParameterGUI('sync', settings_struct); % Update the default settings with the user's selections

session_parameters = get_session_params(settings_struct); % Determine the settings for this training session per the entered values


for current_trial = 1:settings_struct.GUI.number_of_trials % Loop through all trials

    HandlePauseCondition; % Pause here if the user paused 

    % Update settings GUI
    settings_struct.GUI.CurrentTrial = current_trial;
    settings_struct.GUI.CorrectTrials = correct_attempts;
    performance = append(num2str((correct_attempts/current_trial) * 100), '%');
    settings_struct.GUI.Performance = performance;
    total_water = num2str(correct_attempts * settings_struct.GUI.water_volume);
    settings_struct.GUI.TotalWater = append(total_water, 'uL'); 
    BpodParameterGUI('sync', settings_struct); % Update GUI


    sma = NewStateMatrix(); % Create new state machine

    sma = AddState(sma, 'Name', 'ResponsePeriod', 'Timer', settings_struct.GUI.FV_duration_seconds, 'StateChangeConditions', {'Tup', 'ITI', session_parameters.active_in, 'GiveWater'}, ...
                'OutputActions', {FINAL_VALVE, session_parameters.final_valve_state, LED, 255}); 
    % State 1: Response Window
    % Give the animal FV_duration_seconds seconds to respond by licking
    % If the animal does not lick within the window, we skip to the ITI
    % If the animal does lick within the window, we provide a water reward
    % Final Valve is automatically set based on user settings
    % Tup occurs when the internal timer elapses


    sma = AddState(sma, 'Name', 'GiveWater', 'Timer', session_parameters.water_solenoid_duration, 'StateChangeConditions', {'Tup', 'ITI'}, 'OutputActions', {WATER_SOLENOID, 1}); % I DON'T NEED IT, I DON'T NEED IT..... I NEEEDDD ITTTTTTTT
    % State 2: Water Reward
    % If the animal licks during the response period, open the water valve for the length of the state and then jump to ITI
    % When the State ends, Josh indicated the valves will automatically deenergize

    sma = AddState(sma, 'Name', 'ITI', 'Timer', settings_struct.GUI.ITI_seconds, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {}); %>exit to end trial
    % State 3: ITI
    % If the animal fails to lick in time, or a water award has been provided, wait the ITI, and then start another response window

    SendStateMatrix(sma); % Send the state machine to the BPOD to run for this trial

    trial_data = RunStateMatrix; % Get return data

    if ismember(2, trial_data.States)   % Good job buddy; if the animal licks correctly, trial 2 will be present in this list, if it isn't then only 1,3 is present
        BpodSystem.Data.trial_result(current_trial) = 1; % Mark this trial as successful in the experiment data file
        correct_attempts = correct_attempts + 1; % Local counter for live statistics
    else
        BpodSystem.Data.CorrectAttempts(current_trial) = 0; % mark this trial as unsucessful if the animal didn't lick
    end
        
    BpodSystem.Data = AddTrialEvents(BpodSystem.Data, trial_data); % Add the returned data to the global data store

    SaveBpodSessionData; % Save the data to disk

    if BpodSystem.Status.BeingUsed == 0 % Exit if the user has ended the experiment
        return
    end    
end


function session_parameters = get_session_params(settings_struct)
    session_parameters = struct;

    % session_parameters.water_solenoid_duration = GetValveTimes(settings_struct.GUI.water_volume, 2); %% Uncomment once calibrated
    session_parameters.water_solenoid_duration = 0.1;

    switch settings_struct.GUI.FV_state
        case 1
            session_parameters.final_valve_state = 1;
        case 2
            session_parameters.final_valve_state = 0;
    end

    switch settings_struct.GUI.trial_type
        case 1 %left
            session_parameters.active_in = 'Port1In';
        case 2 %right
            session_parameters.active_in = 'Port2In';
    end
 