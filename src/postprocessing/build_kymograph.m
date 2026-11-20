function kymo = build_kymograph(fitResults, fpsMHz, kp)
%BUILD_KYMOGRAPH  Reconstruct and smooth the r*-time von Mises strain map.
%
%   kymo = BUILD_KYMOGRAPH(fitResults, fpsMHz, kp)
%
%   fitResults  struct array from fit_rstar_profile (one entry per frame)
%   fpsMHz      frame rate in MHz (time in microseconds = frame index / fps)
%   kp          kymograph parameters (default_params().kymo):
%                 rStarGrid, frameCut, sigmaR, sigmaT, medianWindow
%
%   evm_raw(:, i) = polyval(vonmises_coeff of frame i, rStarGrid)
%   evm_grid_smoothed: temporal median filter (window medianWindow) and
%   2-D Gaussian filter [sigmaR sigmaT], except for the first frameCut
%   frames, which keep the raw values (fast initial transient).
%   This is the "median + Gaussian, piecewise" option selected in the
%   original analysis (variable evm_grid_smoothed in before_sec9.mat).
%
%   Requires the Image Processing Toolbox (imgaussfilt) and the Signal
%   Processing Toolbox (medfilt1).

nFrames = numel(fitResults);
time_grid = 1:nFrames;                  % frame index after the reference frame
r_star_grid = kp.rStarGrid;

evm_raw = zeros(numel(r_star_grid), nFrames);
for i = time_grid
    evm_raw(:, i) = polyval(fitResults(i).vonmises_coeff, r_star_grid);
end

evm_med = medfilt1(evm_raw', kp.medianWindow, [], 1)';
evm_med_gauss = imgaussfilt(evm_med, [kp.sigmaR, kp.sigmaT]);

idx_raw = 1:min(kp.frameCut, nFrames);
evm_grid_smoothed = evm_med_gauss;
evm_grid_smoothed(:, idx_raw) = evm_raw(:, idx_raw);

kymo = struct( ...
    'r_star_grid', r_star_grid, ...
    'time_grid', time_grid, ...
    'time_us', time_grid / fpsMHz, ...
    'evm_raw', evm_raw, ...
    'evm_grid_smoothed', evm_grid_smoothed, ...
    'params', kp);
end
