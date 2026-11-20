function T = validate_against_archive(caseIds)
%VALIDATE_AGAINST_ARCHIVE  Check this code against the archived analysis (minutes).
%
%   T = VALIDATE_AGAINST_ARCHIVE() checks all 14 recordings;
%   VALIDATE_AGAINST_ARCHIVE({'181404', '171925'}) checks selected ones.
%
%   For every case, the archived workspace before_sec9.mat holds the state
%   of the original analysis after its last frame. The last frame is
%   recomputed with this code and compared:
%     A) primary-bubble refinement
%        -> must equal the archived Xc0, Yc0, R0
%     B) particle-induced von Mises strain
%        -> must equal the archived strain_vonMises_secondary
%     C) r* fit (re-implemented fit_rstar_profile)
%        -> must equal the archived DICpara.fitResults(end)
%     D) kymograph smoothing of the archived fitResults (all frames)
%        -> must equal the archived evm_grid_smoothed
%     E) R-t data read by load_rt_data, and the initial guess of the
%        primary bubble taken from it
%        -> must equal the arrays and Xc0_initial / Yc0_initial of the archive
%
%   Status per case:
%     PASS   everything identical (to round-off)
%     PASS*  identical except the r* fit coefficients, which differ by
%            less than 1e-3. This can only happen for frames that need the
%            constrained fit (lsqcurvefit), if your MATLAB version stops
%            the optimizer at a slightly different point.
%     FAIL   anything else
%
%   Prints one line per case and writes
%   <outputRoot>/validation/validation_summary.csv.
%   To compare all frames, re-run the post-processing (run_all_postprocessing)
%   and use compare_rerun_with_archive.

setup_paths(false);
TOL_COEFF = 1e-8;      % absolute tolerance on fit coefficients
TOL_COEFF_LOOSE = 1e-3;  % constrained fit, other MATLAB version (PASS*)
TOL_FIELD = 1e-10;     % absolute tolerance on strain fields / kymographs

paths = resolve_data_paths();
params = default_params();
if nargin < 1
    caseIds = {};
end
cases = select_cases(caseIds);
rows = cell(numel(cases), 1);

for k = 1:numel(cases)
    c = cases(k);
    files = case_files(c, paths);
    A = load(files.archivedWorkspace, ...
        'DICpara', 'FStrainWorld', 'coordinatesFEMWorld', 'UWorld', 'Xc0', 'Yc0', ...
        'R0', 'R', 'Xc0_initial', 'Yc0_initial', 'CircleR_primary', ...
        'CircleR_secondary', 'CircleCenterSave_secondary', 'ImgSeqNum', ...
        'strain_vonMises_secondary', 'radius_upper_bound', 'evm_grid_smoothed');
    f = A.ImgSeqNum;
    H1 = 251;  % image height + 1 of all recordings (400 x 250 px)

    % A) primary bubble refinement
    [x0, y0, r0] = optimize_bubble_4params(A.UWorld, A.coordinatesFEMWorld, ...
        A.Xc0_initial, A.Yc0_initial, A.CircleR_primary(1), A.CircleR_primary(f), ...
        'center_search_range', params.post.centerSearchRange, ...
        'center_resolution', params.post.centerResolution, ...
        'radius_search_range', params.post.radiusSearchRange, ...
        'radius_resolution', params.post.radiusResolution, ...
        'max_iterations', params.post.maxIterations, ...
        'local_radius', params.post.localRadiusFactor * A.CircleR_primary(f));
    dPrimary = max_abs_diff([x0, y0, r0], [A.Xc0, A.Yc0, A.R0]);

    % B) particle-induced strain
    s = compute_secondary_strain(A.FStrainWorld, A.coordinatesFEMWorld, A.Xc0, A.Yc0, ...
        A.R0, A.R);
    dField = max_abs_diff(s.secondary.vonMises, A.strain_vonMises_secondary);

    % C) r* fit
    opts = struct('radiusUpperBound', A.radius_upper_bound, ...
        'vonMisesStrainBounds', params.post.vonMisesStrainBounds, ...
        'rstarOuterFactor', params.post.rstarOuterFactor);
    coordsCurrent = A.coordinatesFEMWorld + [A.UWorld(1:2:end), A.UWorld(2:2:end)];
    C = A.CircleCenterSave_secondary(f, :);
    fitNew = fit_rstar_profile(coordsCurrent, s.secondary.vonMises, s.secondary.principalMax, ...
        [C(2), H1 - C(1)], A.CircleR_secondary(f), A.CircleR_secondary(1), f, opts);
    fitOld = A.DICpara.fitResults(end);
    dFit = max(max_abs_diff(fitNew.vonmises_coeff, fitOld.vonmises_coeff), ...
        max_abs_diff(fitNew.principal_coeff, fitOld.principal_coeff));

    % D) kymograph
    kymo = build_kymograph(A.DICpara.fitResults, c.fpsMHz, params.kymo);
    dKymo = max_abs_diff(kymo.evm_grid_smoothed, A.evm_grid_smoothed);

    % E) R-t data and initial guess, as used by run_postprocessing_case
    rt = load_rt_data(fullfile(paths.dataRoot, c.resultDir));
    rtSame = isequal(rt.primaryR(:), A.CircleR_primary(:)) && ...
        isequal(rt.secondaryR(:), A.CircleR_secondary(:)) && ...
        isequal(rt.secondaryCenter, A.CircleCenterSave_secondary) && ...
        abs(rt.primaryCenter(f, 2) - A.Xc0_initial) < TOL_FIELD && ...
        abs(H1 - rt.primaryCenter(f, 1) - A.Yc0_initial) < TOL_FIELD;

    others = dPrimary < TOL_FIELD && dField < TOL_FIELD && dKymo < TOL_FIELD && rtSame;
    status = validation_status(others, dFit, TOL_COEFF, TOL_COEFF_LOOSE);
    rows{k} = {c.id, c.material, c.fpsMHz, dPrimary, dField, dFit, dKymo, rtSame, status};
    fprintf('%s %-11s primary %.2e | field %.2e | fit %.2e | kymograph %.2e | R-t %d | %s\n', ...
        c.id, c.material, dPrimary, dField, dFit, dKymo, rtSame, status);
end

T = cell2table(vertcat(rows{:}), 'VariableNames', {'id', 'material', 'fpsMHz', ...
    'maxDiffPrimary', 'maxDiffSecondaryVM', 'maxDiffFitCoeff', 'maxDiffKymograph', ...
    'rtDataIdentical', 'status'});
outDir = fullfile(paths.outputRoot, 'validation');
if ~isfolder(outDir)
    mkdir(outDir);
end
writetable(T, fullfile(outDir, 'validation_summary.csv'));
fprintf('\n%d / %d cases pass (PASS or PASS*).\n', sum(~strcmp(T.status, 'FAIL')), height(T));
end

function status = validation_status(othersOk, dFit, tolStrict, tolLoose)
if othersOk && dFit < tolStrict
    status = 'PASS';
elseif othersOk && dFit < tolLoose
    status = 'PASS*';
else
    status = 'FAIL';
end
end
