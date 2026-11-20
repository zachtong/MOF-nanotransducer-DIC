function outDir = export_processed_from_archive(caseIds)
%EXPORT_PROCESSED_FROM_ARCHIVE  Compact per-case results from the archived workspaces.
%
%   EXPORT_PROCESSED_FROM_ARCHIVE() reads, for every recording,
%   <dataRoot>/<resultDir>/before_sec9.mat (full MATLAB workspace of the
%   original analysis, ~140 MB) and writes
%   <outputRoot>/dataset_processed/processed/<id>_postprocessing.mat
%   in the same layout as run_postprocessing_case:
%     caseInfo, params, fitResults, primaryFit, kymo, imageNames, dicFile
%   primaryFit is only known for the last frame in the archive.
%
%   These small files are the processed/ folder of the data set, read by
%   make_kymograph_figures('dataset'). This function is only needed to
%   build the data set; it is not part of reproducing the analysis.

if nargin < 1
    caseIds = {};
end
setup_paths(false);
paths = resolve_data_paths();
outDir = fullfile(paths.outputRoot, 'dataset_processed', 'processed');
if ~isfolder(outDir)
    mkdir(outDir);
end
params = default_params();
cases = select_cases(caseIds);

for k = 1:numel(cases)
    caseInfo = cases(k);
    files = case_files(caseInfo, paths);
    A = load(files.archivedWorkspace, 'DICpara', 'evm_raw', 'evm_grid_smoothed', 'r_star_grid', ...
        'time_grid', 'file_name', 'Xc0', 'Yc0', 'R0', 'R', 'Xc0_initial', ...
        'Yc0_initial', 'CircleR_primary', 'ImgSeqNum', 'residual_mean_opt');

    fitResults = A.DICpara.fitResults;
    kymo = struct('r_star_grid', A.r_star_grid, 'time_grid', A.time_grid, ...
        'time_us', A.time_grid / caseInfo.fpsMHz, 'evm_raw', A.evm_raw, ...
        'evm_grid_smoothed', A.evm_grid_smoothed, 'params', params.kymo);

    nIncrements = numel(fitResults);
    primaryFit = repmat(struct('frame', NaN, 'Xc0_initial', NaN, 'Yc0_initial', NaN, ...
        'R0_initial', NaN, 'Xc0', NaN, 'Yc0', NaN, 'R0', NaN, 'R', NaN, ...
        'residual', NaN), nIncrements, 1);
    primaryFit(end) = struct('frame', A.ImgSeqNum, 'Xc0_initial', A.Xc0_initial, ...
        'Yc0_initial', A.Yc0_initial, 'R0_initial', A.CircleR_primary(1), ...
        'Xc0', A.Xc0, 'Yc0', A.Yc0, 'R0', A.R0, 'R', A.R, 'residual', A.residual_mean_opt);

    imageNames = A.file_name(1, :);
    dicFile = fullfile(caseInfo.resultDir, 'before_sec8.mat');  % relative to dataRoot
    outFile = fullfile(outDir, sprintf('%s_postprocessing.mat', caseInfo.id));
    save(outFile, 'caseInfo', 'params', 'fitResults', 'primaryFit', 'kymo', 'imageNames', 'dicFile');
    fprintf('%s -> %s\n', files.archivedWorkspace, outFile);
end
end
