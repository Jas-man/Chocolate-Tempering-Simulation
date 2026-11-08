function d = default_design()
%DEFAULT_DESIGN  The "starter" design shown when the interface first opens.
%
%   It is deliberately average (a score in the 70s) so there is plenty of
%   room to improve.
%
%   The design has this structure: 
%     team_name     text
%     setpoint_C    1x5  jacket temperature set-point for each stage   [degC]
%     duration_min  1x5  how long each stage lasts (0 = skip stage)    [min]
%     stir_rpm      1x5  stirrer speed during each stage               [rpm]
d.team_name    = 'Team Name';
d.setpoint_C   = [22  26  30  30  30];
d.duration_min = [ 8   5   4   4   0];
d.stir_rpm     = [40  40  40  40   0];
end
