function T = compare_rerun_with_archive(caseIds)
%COMPARE_RERUN_WITH_ARCHIVE  Compare your post-processing results with the paper, all frames.
%
%   T = COMPARE_RERUN_WITH_ARCHIVE() compares, for every recording that has
%   a result <outputRoot>/processed/<id>_postprocessing.mat (written by
%   run_postprocessing_case or run_all_postprocessing), all frames with
%   the archived analysis <dataRoot>/<resultDir>/before_sec9.mat:
%     fit     r* fit coefficients (von Mises and principal) of every frame
%     kymo    smoothed kymograph evm_grid_smoothed
%     primary primary-bubble Xc0, Yc0, R0 of the last frame (the only
%             frame stored in the archive)
%   COMPARE_RERUN_WITH_ARCHIVE({'181404'}) compares selected recordings.
%
%   Status per case:
%     PASS     everything identical (to round-off)
%     PASS*    primary bubble identical; r* fit coefficients differ by less
%              than 1e-3 (frames with the constrained fit, lsqcurvefit,
%              on another MATLAB version) and the kymograph by at most the
%              corresponding amount, 13 x 1e-3 (a r*^2 + b r* + c, r* <= 3)
%     FAIL     anything else
%     MISSING  no result file
%   With the archived DIC result (default of run_postprocessing_case)
%   PASS or PASS* is expected. After re-running DIC
%   (run_postprocessing_case(id, 'dic', 'rerun')) the displacements differ
%   at round-off level, so FAIL is expected; judge the result by the size
%   of the maxDiff* columns instead.
%
%   Writes <outputRoot>/validation/rerun_vs_archive.csv.

if nargin < 1
    caseIds = {};
end
setup_paths(false);
TOL_STRICT = 1e-8;        % fit coefficients
TOL_FIELD = 1e-10;        % primary bubble, kymograph
TOL_LOOSE = 1e-3;         % fit coefficients, PASS*
TOL_KYMO_LOOSE = 13 * TOL_LOOSE;  % |delta(a r*^2 + b r* + c)| <= 13 delta for r* <= 3

paths = resolve_data_paths();
cases = select_cases(caseIds);
rows = cell(numel(cases), 1);

for k = 1:numel(cases)
    c = cases(k);
    files = case_files(c, paths);
    if ~isfile(files.rerunProcessed)
        rows{k} = {c.id, c.material, '', NaN, NaN, NaN, NaN, 'MISSING'};
        fprintf('%s %-11s MISSING (no result in %s)\n', c.id, c.material, files.rerunProcessed);
        continue
    end
    R = load(files.rerunProcessed, 'fitResults', 'primaryFit', 'kymo', 'dicFile');
    A = load(files.archivedWorkspace, 'DICpara', 'evm_grid_smoothed', 'Xc0', 'Yc0', 'R0', 'ImgSeqNum');

    [dFit, nFramesDiffer] = fit_difference(R.fitResults, A.DICpara.fitResults, TOL_STRICT);
    dKymo = max_abs_diff(R.kymo.evm_grid_smoothed, A.evm_grid_smoothed);
    last = R.primaryFit([R.primaryFit.frame] == A.ImgSeqNum);
    if isempty(last)
        dPrimary = Inf;
    else
        dPrimary = max_abs_diff([last.Xc0, last.Yc0, last.R0], [A.Xc0, A.Yc0, A.R0]);
    end

    if dPrimary < TOL_FIELD && dFit < TOL_STRICT && dKymo < TOL_FIELD
        status = 'PASS';
    elseif dPrimary < TOL_FIELD && dFit < TOL_LOOSE && dKymo < TOL_KYMO_LOOSE
        status = 'PASS*';
    else
        status = 'FAIL';
    end
    rows{k} = {c.id, c.material, char(R.dicFile), dPrimary, dFit, nFramesDiffer, dKymo, status};
    fprintf('%s %-11s primary %.2e | fit %.2e (%d frames > %.0e) | kymograph %.2e | %s\n', ...
        c.id, c.material, dPrimary, dFit, nFramesDiffer, TOL_STRICT, dKymo, status);
end

T = cell2table(vertcat(rows{:}), 'VariableNames', {'id', 'material', 'dicFile', ...
    'maxDiffPrimaryLastFrame', 'maxDiffFitCoeff', 'framesFitDiffer', 'maxDiffKymograph', 'status'});
outDir = fullfile(paths.outputRoot, 'validation');
if ~isfolder(outDir)
    mkdir(outDir);
end
writetable(T, fullfile(outDir, 'rerun_vs_archive.csv'));
end

function [dMax, nDiffer] = fit_difference(new, old, tol)
% Match frames by their 'frame' field; NaN in both counts as equal.
dMax = 0;
nDiffer = 0;
oldFrames = arrayfun(@frame_index, old);
for i = 1:numel(new)
    if isnan(new(i).frame)
        continue  % frame not analysed in this run
    end
    j = find(oldFrames == new(i).frame, 1);
    if isempty(j)
        d = Inf;
    else
        d = max([max_abs_diff(new(i).vonmises_coeff, old(j).vonmises_coeff), ...
                 max_abs_diff(new(i).principal_coeff, old(j).principal_coeff)]);
    end
    dMax = max(dMax, d);
    nDiffer = nDiffer + (d >= tol);
end
end

function f = frame_index(entry)
% Frame number of one fitResults entry (NaN if missing or empty).
if isfield(entry, 'frame') && isnumeric(entry.frame) && isscalar(entry.frame)
    f = double(entry.frame);
else
    f = NaN;
end
end
