function res = run_team_inputs(doSave)
%RUN_TEAM_INPUTS  Simulate the design written in team_inputs.m.
%
%   run_team_inputs          % simulate, print the report, show the graphs
%   run_team_inputs(true)    % ... and also save a submission file
%
%   Edit team_inputs.m (just the numbers), save it, then run this.
if nargin < 1, doSave = false; end
here = fileparts(mfilename('fullpath'));
addpath(here);
rehash;                                  % make sure the edited team_inputs.m is used

cfg    = tempering_config();
design = team_inputs();
res    = run_design(design, cfg);

lines = report_text(res, cfg);
fprintf('\n');
for i = 1:numel(lines), fprintf('%s\n', lines{i}); end
fprintf('\n');
plot_tempering(res, cfg);

if doSave
    f = save_submission(res, cfg);
    fprintf('Submission saved to:\n  %s\n', f);
else
    fprintf('(Not saved. Run  run_team_inputs(true)  to create a submission file.)\n');
end
if nargout == 0, clear res; end
end
