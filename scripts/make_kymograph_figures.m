function outputDir = make_kymograph_figures(source, caseIds)
%MAKE_KYMOGRAPH_FIGURES  Kymographs and strain-time curves (Fig. 2D, 2F, Figs. S10-S13).
%
%   MAKE_KYMOGRAPH_FIGURES(source) draws the r*-time kymographs and the
%   strain-time curves of all 14 recordings from one of two sources:
%
%     'archive'  (default) the archived workspaces of the paper,
%                <dataRoot>/<resultDir>/before_sec9.mat. Gives the
%                published figures.
%     'rerun'    your own results of run_postprocessing_case /
%                run_all_postprocessing, <outputRoot>/processed/
%
%   MAKE_KYMOGRAPH_FIGURES(source, caseIds) draws only the listed
%   recordings, e.g. {'181404', '171925'} (default {} = all).
%
%   SVG files are written to <outputRoot>/figures/kymographs_<source>/<group>/
%   and the folder is returned.

if nargin < 1 || isempty(source)
    source = 'archive';
end
if nargin < 2
    caseIds = {};
end
source = char(source);
setup_paths(false);
paths = resolve_data_paths();

switch source
    case 'archive'
        loader = @(c) load_archived_kymograph(case_file(c, paths, 'archivedWorkspace'));
    case 'rerun'
        loader = @(c) load_processed_kymograph(case_file(c, paths, 'rerunProcessed'));
    otherwise
        error('make_kymograph_figures:Source', ...
            'Unknown source "%s". Use ''archive'' or ''rerun''.', source);
end

outputDir = fullfile(paths.outputRoot, 'figures', ['kymographs_' source]);
plot_kymograph_comparison(loader, outputDir, 'caseIds', cellstr(string(caseIds)));
fprintf('Kymograph figures (%s) written to %s\n', source, outputDir);
end

function file = case_file(caseInfo, paths, field)
files = case_files(caseInfo, paths);
file = files.(field);
if ~isfile(file)
    error('make_kymograph_figures:MissingFile', 'Case %s: file not found: %s', ...
        caseInfo.id, file);
end
end

function k = load_processed_kymograph(file)
S = load(file, 'kymo');
k = struct('evm', S.kymo.evm_grid_smoothed, 'r_star', S.kymo.r_star_grid, ...
    'time', S.kymo.time_grid);
end

function k = load_archived_kymograph(file)
S = load(file, 'evm_grid_smoothed', 'r_star_grid', 'time_grid');
k = struct('evm', S.evm_grid_smoothed, 'r_star', S.r_star_grid, 'time', S.time_grid);
end
