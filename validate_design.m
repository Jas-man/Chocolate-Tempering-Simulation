function [d, warn] = validate_design(d, cfg)
%VALIDATE_DESIGN  Check a design struct and clip values to the allowed ranges.
%
%   [d, warn] = validate_design(d, cfg)
%
%   Out-of-range values are clipped (not rejected) and reported in the cell
%   array of strings WARN, so a typo never crashes the interface.  Wrong
%   vector lengths or non-numeric values raise an error with a clear message.
if nargin < 2, cfg = tempering_config(); end
warn = {};
n = cfg.proc.n_stages;
L = cfg.limits;

if ~isfield(d, 'team_name') || isempty(d.team_name)
    d.team_name = 'Unnamed team';
end
d.team_name = char(d.team_name);

[d.setpoint_C,   w1] = fix_vector(d, 'setpoint_C',   n, L.sp_min_C,    L.sp_max_C,    'Jacket set-point (degC)');
[d.duration_min, w2] = fix_vector(d, 'duration_min', n, L.dur_min_min, L.dur_max_min, 'Duration (min)');
[d.stir_rpm,     w3] = fix_vector(d, 'stir_rpm',     n, L.rpm_min,     L.rpm_max,     'Stirrer speed (rpm)');
warn = [warn, w1, w2, w3];

if sum(d.duration_min) <= 0
    d.duration_min(1) = 1;
    warn{end+1} = 'All stage durations were zero - stage 1 set to 1 min.';
end
end

function [v, w] = fix_vector(d, field, n, lo, hi, label)
w = {};
if ~isfield(d, field)
    error('Design is missing the field "%s".', field);
end
v = d.(field);
if ~isnumeric(v) || numel(v) ~= n || any(~isfinite(v(:)))
    error('"%s" must be %d finite numbers (one per stage).', label, n);
end
v = double(v(:)');                      % force a 1 x n row vector
vc = min(max(v, lo), hi);
if any(vc ~= v)
    w{end+1} = sprintf('%s: values outside [%g, %g] were clipped.', label, lo, hi);
end
v = vc;
end
