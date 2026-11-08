function file = save_submission(res, cfg, folder)
%SAVE_SUBMISSION  Write a team's design to a file the organisers can rank.
%
%   file = save_submission(res)            % saves into ./submissions next to the code
%   file = save_submission(res, cfg, folder)
%
%   The .mat file stores the DESIGN (the inputs) plus the team's own result for
%   reference.  rank_teams.m ignores the stored score and re-runs the design
%   with the organisers' settings, so a submission cannot claim a score it
%   did not earn.  A plain-text report is saved alongside.
if nargin < 2 || isempty(cfg), cfg = tempering_config(); end
if nargin < 3 || isempty(folder)
    folder = fullfile(fileparts(mfilename('fullpath')), 'submissions');
end
if ~exist(folder, 'dir'), mkdir(folder); end

stamp = datestr(now, 'yyyymmdd_HHMMSS'); %#ok<DATST,TNOW1>
safe  = regexprep(res.design.team_name, '[^A-Za-z0-9_-]', '_');
base  = fullfile(folder, sprintf('%s_%s', safe, stamp));

sub.team_name    = res.design.team_name;
sub.design       = res.design;
sub.timestamp    = stamp;
sub.claimed      = struct('quality', res.score.quality, 'time_min', res.t_total_min, ...
                          'energy_Wh', res.E_total_Wh, 'valid', res.score.valid);
file = [base '.mat'];
save(file, 'sub');

fid = fopen([base '.txt'], 'w');
if fid > 0
    lines = report_text(res, cfg);
    for i = 1:numel(lines), fprintf(fid, '%s\n', lines{i}); end
    fclose(fid);
end
end
