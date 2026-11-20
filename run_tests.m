function results = run_tests()
%RUN_TESTS  Run the unit tests in tests/ (no data set or MEX needed).
%
%   results = RUN_TESTS() requires the Optimization, Image Processing and
%   Signal Processing Toolboxes (lsqcurvefit, imgaussfilt, medfilt1).

root = fileparts(mfilename('fullpath'));
addpath(root);
setup_paths(false);
results = runtests(fullfile(root, 'tests'));
disp(table(results));
if any([results.Failed])
    error('run_tests:Failed', '%d test(s) failed.', sum([results.Failed]));
end
end
