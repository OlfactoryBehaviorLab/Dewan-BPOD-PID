%#ok<*NASGU,*STRNU,*DEFNU,*INUSD,*NUSED,*GVMIS> 
function dewan_PID_protocol
global BpodSystem;

%% Make sure all our helper scripts are loaded
addpath(genpath('Helpers/'));

%% If Bpod has not been loaded, load it
if isempty(BpodSystem)
    Bpod;
end


%% Reset a_in object if it is still being held by the Bpod
if any([isprop(BpodSystem, 'PluginObjects'), isprop(BpodSystem.PluginObjects, 'a_in')])
    BpodSystem.PluginObjects.a_in = [];
end


%% Load needed modules
BpodSystem.PluginObjects.a_in = setup_analog_input('COM9'); % Just going to keep the analog in module inside the Bpod object to allow proper destructor function
load_valve_driver_commands();
load_analog_in_commands();


% Framework of Data to save
BpodSystem.Data = [];
BpodSystem.Data.analog_stream_swap = [];
BpodSystem.Data.Settings = [];
BpodSystem.Data.update_gui_params = [];

BpodSystem.Status.SafeClose = 1;

%% Create Trial manager
trial_manager = BpodTrialManager;


%% Launch GUIs
startup_gui = pid_startup_gui(); % Get Startup Parameters
waitfor(startup_gui, 'finished', true); % Wait for user to successfully submit information

if isvalid(startup_gui)
    startup_params = startup_gui.session_info; % Get the parameters
    BpodSystem.Data.ExperimentParams = startup_params;
    delete(startup_gui); % Close GUI    
else
    dialog = errordlg('Startup GUI closed early, halting protocol!', 'Error!', {'WindowStyle', 'modal'});
    beep; % No Man, you're thinking of "Beep boop boop bop, boop boop bop"
    uiwait(dialog);
    soft_shutdown([]); % There is no main GUI to close, so we just give it a whole lotta nothing to delete 
    return;
end

main_gui = pid_main_gui(startup_params, @run_PID, @valve_control, @soft_shutdown); % Launch Main GUI, no need to wait


% Timer Objects
stream_timer = timer('Name', 'Analog_Input_Poll', 'TimerFcn', {@(h,e)get_analog_data()}, 'ExecutionMode', 'fixedRate', 'Period', 0.05); % Stream analog in data
gui_timer = timer('Name', 'Update_GUI', 'TimerFcn', {@(h,e)update_gui(main_gui)}, 'ExecutionMode', 'fixedRate', 'Period', 0.3, 'BusyMode', 'queue'); % Async GUI update during trials


%% Function DEFS below
function run_PID(~, ~, main_gui)
    BpodSystem.Status.SafeClose = 0;

    Settings = get_settings(main_gui, startup_params); % Settings wont change for duration of trials, so this will be valid for trial 1
    start_streaming();
    main_gui.lock_gui();

    BpodSystem.Data.Settings = [BpodSystem.Data.Settings Settings];

    sma = generate_state_machine(BpodSystem, Settings); % Generate first trial's state machine

    trial_manager.startTrial(sma);

    for i = 2:Settings.number_of_trials % Main Loopdy Loop and pull; start at 2 since trial one is exectued before the loop
        if BpodSystem.Status.BeingUsed == 0
            break
        end
        
        HandlePauseCondition();

        SendStateMachine(sma, 'RunASAP');
        
        raw_events = trial_manager.getTrialData();
        
        if BpodSystem.Status.BeingUsed == 0
            break
        end

        BpodSystem.Data = AddTrialEvents(BpodSystem.Data, raw_events);
        SaveBpodSessionData;

        BpodSystem.Data.Settings = [BpodSystem.Data.Settings Settings];
        
        trial_manager.startTrial();
    end
    
    if BpodSystem.Status.BeingUsed == 1  %% Only look for and save this last piece of data if the state machine was NOT manually stopped, otherwise there is nothing to find  
        raw_events = trial_manager.getTrialData();
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data, raw_events);
    end

    stop_streaming(); % Stop all timers and stop streaming
    get_analog_data(); % Get any straggling data
    %update_gui(main_gui, 0, 0);

    SaveBpodSessionData;

    if BpodSystem.Status.Shutdown_flag == 1
        soft_shutdown(main_gui)
    else
        main_gui.unlock_gui();
        BpodSystem.Status.SafeClose = 1;
    end

end


function soft_shutdown(main_gui)
    msg = msgbox("Shutting down, please wait...");
    BpodSystem.Status.BeingUsed = 0; % Make sure current protocol is stopped
    BpodSystem.PluginObjects.a_in = []; % Manually release a_in object
    evalin('base', 'EndBpod;') % Execute EndBpod in the base environment to shutdown the system
    delete(main_gui)
    delete(msg);
end


function Settings = get_settings(main_gui, startup_params) % This is kinda defunct and needs to just be removed
    Settings = main_gui.get_params(); % Get settings from the GUI
end


function sma = generate_state_machine(BpodSystem, Settings)
    sma = NewStateMatrix();

    odor_preduration = Settings.odor_preduration / 1000; % Convert ms to s otherwise you'll be waiting a LONG time
    odor_duration = Settings.odor_duration / 1000;
    solvent_preduration = odor_duration - odor_preduration;
    solvent_duration = odor_duration;


    switch Settings.trial_type
        case 'Odor'
            sma = AddState(sma, 'Name', 'PreTrialDuration', 'Timer', odor_preduration, 'StateChangeConditions', {'Tup', 'PID_Measurement'}, 'OutputActions', {'AnalogIn1', 1, 'ValveModule1', 4}); % Open vial 3 & 4 (valve 5 & 6) and wait for equalization
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'All_Off'}, 'OutputActions', {'AnalogIn1', 2,'ValveModule1', 5}); % Open FV (valve 1) for odor duration
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', 'ITI'}, 'OutputActions', {'AnalogIn1', 3,'ValveModule1', 6}); % Close everything
            sma = AddState(sma, 'Name', 'ITI', 'Timer', 2, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {});
        case 'Pure'
            sma = AddState(sma, 'Name', 'PreTrialDuration', 'Timer', odor_preduration, 'StateChangeConditions', {'Tup', 'PID_Measurement'}, 'OutputActions', {'AnalogIn1', 1, 'ValveModule1', 1}); % Open vial 1 & 2 (valve 7 & 8) and wait for equalization8
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'All_Off'}, 'OutputActions', {'AnalogIn1', 2, 'ValveModule1', 2}); % Open FV (valve 1) for odor duration
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', 'ITI'}, 'OutputActions', {'AnalogIn1', 3, 'ValveModule1', 5}); % Close everything
            sma = AddState(sma, 'Name', 'ITI', 'Timer', 2, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {});
        case 'Solvent'
            sma = AddState(sma, 'Name', 'PreTrialSolvent', 'Timer', solvent_preduration, 'StateChangeConditions', {'Tup', 'PreTrialOdor'}, 'OutputActions', {'AnalogIn1', 1, 'ValveModule1', 1}); % Turn on vial 1 & 2 (valve 7 & 8) for solvent measurement
            sma = AddState(sma, 'Name', 'PreTrialOdor', 'Timer', odor_preduration, 'StateChangeConditions', {'Tup', 'PID_Measurement'}, 'OutputActions', {'AnalogIn1', 4, 'ValveModule1', 3}); % Turn on vial 3 & 4 (valve 5 & 6) so odor can equalize; leave solvent valves on
            sma = AddState(sma, 'Name', 'PID_Measurement', 'Timer', odor_duration, 'StateChangeConditions', {'Tup', 'OdorOff'}, 'OutputActions', {'AnalogIn1', 2, 'ValveModule1', 5}); % Open FV (valve 1) for odor duration; turn off valve 7 & 8
            sma = AddState(sma, 'Name', 'OdorOff', 'Timer', solvent_duration, 'StateChangeConditions', {'Tup', 'All_Off'}, 'OutputActions', {'AnalogIn1', 5, 'ValveModule1', 1}); % Closes odor vial and actuates FV; allows solvent to PID 
            sma = AddState(sma, 'Name', 'All_Off', 'Timer', 0, 'StateChangeConditions', {'Tup', 'ITI'}, 'OutputActions', {'AnalogIn1', 3, 'ValveModule1', 6}); % Close everything
            sma = AddState(sma, 'Name', 'ITI', 'Timer', 2, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {});
        case 'CAL'
        case 'KIN'
            % Stuff goes here later

    end
end


function load_valve_driver_commands()
    % 1. B192 = 11000000; Valve 7 & 8 ON; Solvent Vial On
    % 2. B193 = 11000001; Valve 7 & 8 ON | FV ON; Solvent Vial On
    % 3. B240 = 11110000; All Valves ON except FV; for solvent trial + odor pretrial duration
    % 4. B48 = 00110000; Valve 6 & 5 ON; Odor Vial On
    % 5. B49 = 00110001; Valve 6 & 5 ON | FV ON; Odor Vial On
    % 6. B0 = 00000000; All OFF

    commands = {[66 192], [66 193], [66 240], [66 48], [66 49], [66 0]};

    success = LoadSerialMessages('ValveModule1', commands); 

    if success ~= 1
        error("Error sending commands to the valve driver module!");
    end
end


function load_analog_in_commands()
    %   Analog1In event key:
    %   1. S: Trial Start
    %   2. F: FV Actuation (Odor Duration)
    %   3. E: Trial End (Close everything)
    %   4. P: Solvent odor pretrial duration
    %   5. C: FV Close for second solvent duration

    commands = {['#' 'S'], ['#' 'F'], ['#' 'E'], ['#' 'P'], ['#' 'C']};

    success = LoadSerialMessages('AnalogIn1', commands);

    if success ~= 1
        error("Error sending commands to the analog input module!");
    end
end


function stop_streaming()

    a_in = BpodSystem.PluginObjects.a_in;
   
    a_in.stopUSBStream();
    stop(stream_timer);
    stop(gui_timer)
    is_streaming = 0;

    %a_in.stopModuleStream();
    %a_in.stopReportingEvents();
end


function start_streaming()

    a_in = BpodSystem.PluginObjects.a_in;

    a_in.startUSBStream();
    start(stream_timer);
    start(gui_timer);
    is_streaming = 1;

   % a_in.startModuleStream();
   % a_in.startReportingEvents();
end


end