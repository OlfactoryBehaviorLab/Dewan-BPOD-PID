function valve_control(valve, state)
    switch(state)
        case 1
            ModuleWrite('ValveModule1', ['O' valve]);
        case 0
            ModuleWrite('ValveModule1', ['C' valve]);
    end
end