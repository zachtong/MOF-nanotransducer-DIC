function ResultDisp = compute_cumulative_displacement(ResultDisp, ResultFEMeshEachFrame)
%COMPUTE_CUMULATIVE_DISPLACEMENT  Accumulate incremental DIC displacements.
%
%   ResultDisp = COMPUTE_CUMULATIVE_DISPLACEMENT(ResultDisp, ResultFEMeshEachFrame)
%
%   Incremental STAQ-DIC returns, for every frame k, the displacement from
%   frame k-1 to frame k on that frame's mesh. Material points of the first
%   mesh are advected through the sequence with thin-plate RBF
%   interpolation, and the cumulative displacement is stored in
%   ResultDisp{k}.U_accum (interleaved [u1; v1; u2; v2; ...]).
%
%   Unchanged from the original analysis, except that the interactive
%   "pause" on a poor RBF fit is replaced by a warning (the original
%   continued after a key press).

RBF_CHECK_TOL = 1e-3;

coord = ResultFEMeshEachFrame{1}.coordinatesFEM(:, 1:2);
coordCurr = coord;

for k = 1:numel(ResultDisp)
    tempx = ResultFEMeshEachFrame{k}.coordinatesFEM(:, 1);
    tempy = ResultFEMeshEachFrame{k}.coordinatesFEM(:, 2);
    tempu = ResultDisp{k}.U(1:2:end);
    tempv = ResultDisp{k}.U(2:2:end);

    op_x = rbfcreate([tempx, tempy]', tempu', 'RBFFunction', 'thinplate');
    check_rbf(op_x, RBF_CHECK_TOL, k, 'u');
    disp_x = rbfinterp([coordCurr(:, 1), coordCurr(:, 2)]', op_x);

    op_y = rbfcreate([tempx, tempy]', tempv', 'RBFFunction', 'thinplate');
    check_rbf(op_y, RBF_CHECK_TOL, k, 'v');
    disp_y = rbfinterp([coordCurr(:, 1), coordCurr(:, 2)]', op_y);

    coordCurr = coordCurr + [disp_x(:), disp_y(:)];
    U_accum = (coordCurr - coord)';
    ResultDisp{k}.U_accum = U_accum(:);
end
end

function check_rbf(op, tol, k, component)
maxdiff = rbfcheck(op);
if maxdiff > tol
    warning('compute_cumulative_displacement:RbfCheck', ...
        'RBF interpolation check failed for %s at increment %d (max diff %.3g > %.1g).', ...
        component, k, maxdiff, tol);
end
end
