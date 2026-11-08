function res = run_design(design, cfg)
%RUN_DESIGN  Simulate a design and score it.  The one call everything else uses.
%
%   res = run_design(design)          % uses tempering_config()
%   res = run_design(design, cfg)
%
%   res.score holds the quality score, its breakdown, the constraint check
%   (res.score.valid, res.score.reasons) and the ranking metrics.
if nargin < 2, cfg = tempering_config(); end
res = simulate_tempering(design, cfg);
res.score = score_tempering(res, cfg);
end
