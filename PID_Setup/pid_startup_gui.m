
%#ok<*NASGU,*STRNU,*DEFNU,*INUSD,*NUSED,*GVMIS> 
function pid_startup_gui

            WINDOW_WIDTH = 500;
            WINDOW_HEIGHT = 300;
            HALF_WINDOW_HEIGHT = WINDOW_HEIGHT/2;
            
            gui = uifigure('Visible', 'off');
            gui.Position = [100 100 WINDOW_WIDTH WINDOW_HEIGHT];
            gui.Name = 'Dewan Lab PID Configurator';
            gui.Resize = 'off';

            main_panel = uipanel(gui);
            % main_panel.BorderWidth = 2;
            main_panel.TitlePosition = 'centertop';
            main_panel.Title = 'Dewan Lab PID Configurator';
            main_panel.FontName = 'Arial';
            main_panel.FontWeight = 'bold';
            main_panel.FontSize = 20;
            main_panel.Position = [1 HALF_WINDOW_HEIGHT WINDOW_WIDTH HALF_WINDOW_HEIGHT]; % 1,1 is bottom left corner.... why not top left???

            MAIN_PANEL_THIRDS = floor((main_panel.Position(4)-50)/3); % Add small ofset for title bar
            OFFSET = floor(MAIN_PANEL_THIRDS/2);
            ExperimentTypeLabel = uilabel(main_panel);
            ExperimentTypeLabel.FontName = 'Arial';
            ExperimentTypeLabel.FontSize = 16;
            ExperimentTypeLabel.FontWeight = 'bold';
            ExperimentTypeLabel.Position = [20 MAIN_PANEL_THIRDS*3-OFFSET 143 22];
            ExperimentTypeLabel.Text = 'Experiment Type: ';

            GROUP_POSITION = ExperimentTypeLabel.Position(1) + ExperimentTypeLabel.Position(3) + 30;
            ButtonGroup = uibuttongroup(main_panel);
            ButtonGroup.BorderType = 'none';
            ButtonGroup.TitlePosition = 'centertop';
            ButtonGroup.Position = [GROUP_POSITION MAIN_PANEL_THIRDS*3-OFFSET 250 22];

            GROUP_FOURTHS = floor(ButtonGroup.Position(3)/4);
            CFButton = uiradiobutton(ButtonGroup);
            CFButton.Text = 'PID';
            CFButton.FontName = 'Arial';
            CFButton.Position = [1 0 42 22];
           
            CFButton = uiradiobutton(ButtonGroup);
            CFButton.Text = 'CF';
            CFButton.FontName = 'Arial';
            CFButton.Position = [GROUP_FOURTHS-5 0 42 22];

            KineticsButton = uiradiobutton(ButtonGroup);
            KineticsButton.Text = 'Kinetics';
            KineticsButton.FontName = 'Arial';
            KineticsButton.Position = [GROUP_FOURTHS*2-20 0 69 22];

            CalibrationButton = uiradiobutton(ButtonGroup);
            CalibrationButton.Text = 'Calibration';
            CalibrationButton.FontName = 'Arial';
            CalibrationButton.Position = [GROUP_FOURTHS*3-10 0 83 22];

            name_label = uilabel(main_panel);
            name_label.FontName = 'Arial';
            name_label.FontSize = 16;
            name_label.FontWeight = 'bold';
            name_label.Position = [20 MAIN_PANEL_THIRDS*2-OFFSET 165 22];
            name_label.Text = 'Experimenter Name: ';

            NAME_EDIT_POSITION = name_label.Position(1) + name_label.Position(3) + 10;
            NAME_EDIT_LENGTH = WINDOW_WIDTH - NAME_EDIT_POSITION - 10;
            name_edit_field = uieditfield(main_panel, 'text');
            name_edit_field.FontName = 'Arial';
            name_edit_field.FontSize = 12;
            name_edit_field.Position = [NAME_EDIT_POSITION MAIN_PANEL_THIRDS*2-OFFSET NAME_EDIT_LENGTH 22];

            odor_label = uilabel(main_panel);
            odor_label.FontName = 'Arial';
            odor_label.FontSize = 16;
            odor_label.FontWeight = 'bold';
            odor_label.Position = [20 MAIN_PANEL_THIRDS-OFFSET 101 22];
            odor_label.Text = 'Odor Name: ';

            ODOR_EDIT_POSITION = odor_label.Position(1) + odor_label.Position(3) + 10;
            ODOR_EDIT_LENGTH = WINDOW_WIDTH - ODOR_EDIT_POSITION - 10;
            odor_edit_field = uieditfield(main_panel, 'text');
            odor_edit_field.FontName = 'Arial';
            odor_edit_field.FontSize = 12;
            odor_edit_field.Position = [ODOR_EDIT_POSITION MAIN_PANEL_THIRDS-OFFSET ODOR_EDIT_LENGTH 22];

            calibration_panel = uipanel(gui);
            %calibration_panel.BorderWidth = 2;
            calibration_panel.TitlePosition = 'centertop';
            calibration_panel.Title = 'Current Calibration Values';
            calibration_panel.FontName = 'Arial';
            calibration_panel.FontWeight = 'bold';
            calibration_panel.FontSize = 18;
            calibration_panel.Position = [1 1 WINDOW_WIDTH HALF_WINDOW_HEIGHT+1]; % Add one to overlap borders

            CAL_PANEL_THIRDS = floor((calibration_panel.Position(4)-60)/3); % Add small ofset for title bar
            LABEL_HORIZONTAL_THIRDS = floor(calibration_panel.Position(3)/3);

            x1_label = uilabel(calibration_panel);
            x1_label.FontName = 'Arial';
            x1_label.FontSize = 16;
            x1_label.FontWeight = 'bold';
            x1_label.Position = [30 CAL_PANEL_THIRDS*3 40 22];
            x1_label.Text = '1x: ';

            X1_EDIT_POSITION = x1_label.Position(1) + x1_label.Position(3) + 10;
            x1_edit_field = uieditfield(calibration_panel, 'numeric', 'Limits', [0 100]);
            x1_edit_field.FontName = 'Arial';
            x1_edit_field.FontSize = 12;
            x1_edit_field.Position = [X1_EDIT_POSITION CAL_PANEL_THIRDS*3 60 22];

            x5_label = uilabel(calibration_panel);
            x5_label.FontName = 'Arial';
            x5_label.FontSize = 16;
            x5_label.FontWeight = 'bold';
            x5_label.Position = [LABEL_HORIZONTAL_THIRDS+30 CAL_PANEL_THIRDS*3 40 22];
            x5_label.Text = '5x: ';

            X5_EDIT_POSITION = x5_label.Position(1) + x5_label.Position(3) + 10;
            x5_edit_field = uieditfield(calibration_panel, 'numeric', 'Limits', [0 100]);
            x5_edit_field.FontName = 'Arial';
            x5_edit_field.FontSize = 12;
            x5_edit_field.Position = [X5_EDIT_POSITION CAL_PANEL_THIRDS*3 60 22];

            X10_POS = WINDOW_WIDTH - 140;
            x10_label = uilabel(calibration_panel);
            x10_label.FontName = 'Arial';
            x10_label.FontSize = 16;
            x10_label.FontWeight = 'bold';
            x10_label.Position = [X10_POS CAL_PANEL_THIRDS*3 40 22];
            x10_label.Text = '10x: ';

            % Create OdorNameEditField
            X10_EDIT_POSITION = x10_label.Position(1) + x10_label.Position(3) + 10;
            x10_edit_field = uieditfield(calibration_panel, 'numeric', 'Limits', [0 100]);
            x10_edit_field.FontName = 'Arial';
            x10_edit_field.FontSize = 12;
            x10_edit_field.Position = [X10_EDIT_POSITION CAL_PANEL_THIRDS*3 60 22];
      
            BUTTON_WIDTH = 80;
            BUTTON_POSITION = WINDOW_WIDTH/2 - BUTTON_WIDTH/2;
            submit_button = uibutton(gui);
            submit_button.Text = 'SUBMIT';
            submit_button.FontName = 'Arial';
            submit_button.FontSize = 18;
            submit_button.FontWeight = 'bold';
            submit_button.Position = [BUTTON_POSITION 30 BUTTON_WIDTH 30];
            submit_button.ButtonPushedFcn = @submit_callback;

            gui.Visible = 'on';


function submit_callback(app, event)

name = name_edit_field.Value;
odor = odor_edit_field.Value;
x1 = x1_edit_field.Value;
x5 = x5_edit_field.Value;
x10 = x10_edit_field.Value;

validate_input(name, odor, x1, x5, x10);

end
    
function valid = validate_input(name, odor, x1, x5, x10)
    RED = [1 0 0];
    BLACK = [0 0 0];
    error = false;

    if isempty(name)
        name_label.FontColor = RED;
        error = true;
    else
        name_label.FontColor = BLACK;
    end

    if isempty(odor)
        odor_label.FontColor = RED;
        error=true;
    else
        odor_label.FontColor = BLACK;
    end

    if x1 == 0
        x1_label.FontColor = RED;
        error=true;
    else
        x1_label.FontColor = BLACK;
    end

    if x5 == 0
        x5_label.FontColor = RED;
        error=true;
    else
        x5_label.FontColor = BLACK;
    end

    if x10 == 0
        x10_label.FontColor = RED;
        error=true;
    else
        x10_label.FontColor = BLACK;
    end

end
    
end

