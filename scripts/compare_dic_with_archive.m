function T = compare_dic_with_archive(caseIds)
%COMPARE_DIC_WITH_ARCHIVE  Compare your DIC results with the DIC result of the paper.
%
%   T = COMPARE_DIC_WITH_ARCHIVE() compares, for every recording that has
%   a result <outputRoot>/dic/<id>_dic_results.mat (written by run_dic_case
%   or run_all_dic), each frame increment with the archived DIC result
%   <dataRoot>/<resultDir>/before_sec8.mat:
%     meshDiffer    increments whose quadtree mesh (nodes or elements)
%                   differs
%     maxDiffU      largest |U_new - U_archived| (px) over the increments
%                   with identical meshes; Inf if a value is NaN on one
%                   side only
%     maxAbsU       largest |U_archived| (px), for scale
%   COMPARE_DIC_WITH_ARCHIVE({'181404'}) compares selected recordings.
%
%   Identical code, images, masks and parameters should give identical or
%   nearly identical displacements (differences at round-off level from
%   other MATLAB versions or compilers).
%
%   Writes <outputRoot>/validation/dic_vs_archive.csv.

if nargin < 1
    caseIds = {};
end
setup_paths(false);
paths = resolve_data_paths();
cases = select_cases(caseIds);
rows = cell(numel(cases), 1);

for k = 1:numel(cases)
    c = cases(k);
    files = case_files(c, paths);
    if ~isfile(files.rerunDic)
        rows{k} = {c.id, c.material, NaN, NaN, NaN, NaN, 'MISSING'};
        fprintf('%s %-11s MISSING (no result in %s)\n', c.id, c.material, files.rerunDic);
        continue
    end
    N = load(files.rerunDic, 'ResultDisp', 'ResultFEMeshEachFrame');
    A = load(files.archivedDic, 'ResultDisp', 'ResultFEMeshEachFrame');
    nInc = numel(A.ResultDisp);
    if numel(N.ResultDisp) ~= nInc
        rows{k} = {c.id, c.material, nInc, NaN, NaN, NaN, 'FAIL'};
        fprintf('%s %-11s %d increments, archive has %d\n', c.id, c.material, ...
            numel(N.ResultDisp), nInc);
        continue
    end

    meshDiffer = 0;
    maxDiffU = 0;
    maxAbsU = 0;
    for i = 1:nInc
        meshNew = N.ResultFEMeshEachFrame{i};
        meshOld = A.ResultFEMeshEachFrame{i};
        uNew = N.ResultDisp{i}.U(:);
        uOld = A.ResultDisp{i}.U(:);
        maxAbsU = max([maxAbsU; abs(uOld)]);  % max ignores NaN
        sameMesh = max_abs_diff(meshNew.coordinatesFEM, meshOld.coordinatesFEM) < 1e-9 && ...
            isequaln(meshNew.elementsFEM, meshOld.elementsFEM) && numel(uNew) == numel(uOld);
        if ~sameMesh
            meshDiffer = meshDiffer + 1;
            continue
        end
        maxDiffU = max(maxDiffU, max_abs_diff(uNew, uOld));
    end
    if meshDiffer == 0 && maxDiffU < 1e-6
        status = 'PASS';
    else
        status = 'CHECK';
    end
    rows{k} = {c.id, c.material, nInc, meshDiffer, maxDiffU, maxAbsU, status};
    fprintf('%s %-11s %d increments | mesh differs in %d | max |dU| %.2e px (max |U| %.2f px) | %s\n', ...
        c.id, c.material, nInc, meshDiffer, maxDiffU, maxAbsU, status);
end

T = cell2table(vertcat(rows{:}), 'VariableNames', {'id', 'material', 'increments', ...
    'meshDiffer', 'maxDiffU', 'maxAbsU', 'status'});
outDir = fullfile(paths.outputRoot, 'validation');
if ~isfolder(outDir)
    mkdir(outDir);
end
writetable(T, fullfile(outDir, 'dic_vs_archive.csv'));
end
