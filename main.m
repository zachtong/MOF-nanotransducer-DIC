%MAIN  Reproduce the DIC analysis of the paper.
%
%   1. Unzip the data set (Zenodo) into the folder data/ of this
%      repository (see data/README.md).
%   2. Choose below what to compute.
%   3. Run this script (Editor: Run, or type "main" in the Command Window).
%
%   Results and figures are written to output/. Expected results of each
%   step are described in docs/reproduce.md.

here = fileparts(mfilename('fullpath'));
if isempty(here)
    here = pwd;   % code run by selection: assume the repository folder
end

%% ============================== Settings ==============================

% Recordings: 'all' or a list of IDs, e.g. {'181404', '171925'}.
% IDs, materials and figures: config/case_table.m
cases = 'all';

% What to compute (true / false)
runUnitTests        = true;       % unit tests, no data needed (< 1 min)
makeFigures         = true;       % kymographs and strain-time curves,
                                  % Fig. 2D, 2F, Figs. S10-S13 (minutes)
validateArchive     = true;       % recompute the last frame of each recording
                                  % and compare with the paper (minutes)
rerunPostprocessing = false;      % all frames from the archived DIC result
                                  % (~1 h per recording)
saveVonMisesMaps    = false;      % with the post-processing: full-field maps
                                  % (Fig. 2C, Fig. S9, Movie S2)
rerunDIC            = false;      % DIC from the images (hours per recording,
                                  % needs a C++ compiler); the post-processing
                                  % then runs on your own DIC result

% Folders (default: inside this repository)
dataRoot   = fullfile(here, 'data');
outputRoot = fullfile(here, 'output');

%% ================================ Run =================================

addpath(here);
setup_paths(rerunDIC);                 % the MEX files are only needed for DIC
set_data_paths(dataRoot, outputRoot);
if ischar(cases) && strcmp(cases, 'all')
    caseIds = {};
else
    caseIds = cellstr(string(cases));
end

if runUnitTests
    run_tests();
end

if makeFigures
    make_kymograph_figures('archive', caseIds);
end

if validateArchive
    validate_against_archive(caseIds);
end

dicSource = 'archive';
if rerunDIC
    run_all_dic(caseIds);
    compare_dic_with_archive(caseIds);
    dicSource = 'rerun';
end

if rerunPostprocessing || rerunDIC
    run_all_postprocessing('cases', caseIds, 'dic', dicSource, ...
        'saveFigures', saveVonMisesMaps);
    compare_rerun_with_archive(caseIds);
    make_kymograph_figures('rerun', caseIds);
end

fprintf('\nDone. Results and figures: %s\n', outputRoot);
