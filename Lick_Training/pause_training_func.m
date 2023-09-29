function [] = pause_training_func(BpodSystem)
    pause_state = BpodSystem.Status.Pause;

    switch pause_state
        case 0
            BpodSystem.Status.Pause = 1;
            disp('Pausing Session!')
        case 1
            BpodSystem.Status.Pause = 0;
            disp('Continuing Session!')
    end
