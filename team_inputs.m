function design = team_inputs()
%TEAM_INPUTS  <<< EDIT THE NUMBERS IN THIS FILE, SAVE, THEN RUN  run_team_inputs >>>
%
%   You do not need to know MATLAB.  Change the numbers below and keep the
%   square brackets and the semicolons.  The batch starts as fully melted
%   chocolate at 45 degC, then runs through the stages in order.
%
%   Each stage has three settings:
%     setpoint_C    the temperature the heating/cooling JACKET is told to hold.
%                   (The chocolate itself lags behind the jacket!)
%     duration_min  how long the stage lasts. 0 = skip the stage.
%     stir_rpm      stirrer speed. Stirring speeds up heat transfer and helps
%                   crystals form - but it adds heat and costs energy.
%
%   Limits (see the README): total time <= 35 min, total energy <= 40 Wh.
%   Allowed ranges: set-point 10-50 degC, duration 0-60 min, stirrer 0-150 rpm.
%
%   Hint: stage 1 is usually a "cool down", stage 2 a "crystal-forming hold",
%   stage 3 a "reheat" and stage 4 a "working temperature hold".

team_name = 'Team Name';                 % <-- your team's name

%                 Stage:   1    2    3    4    5
setpoint_C   =           [ 22   26   30   30   30 ];   % jacket temperature (degC)
duration_min =           [  8    5    4    4    0 ];   % stage length (min)
stir_rpm     =           [ 40   40   40   40    0 ];   % stirrer speed (rpm)

% ---- do not edit below this line ----
design = struct('team_name', team_name, 'setpoint_C', setpoint_C, ...
                'duration_min', duration_min, 'stir_rpm', stir_rpm);
end
