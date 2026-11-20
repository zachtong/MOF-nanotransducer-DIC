function cases = case_table()
%CASE_TABLE  Experimental cases analysed with LIC + DIC in the manuscript.
%
%   cases = CASE_TABLE() returns a struct array with one entry per
%   high-speed recording. All paths are relative to the data root defined
%   in config/data_paths.m (see config/data_paths_template.m).
%
%   Fields
%     id               six-digit recording ID (HHMMSS of the acquisition)
%     folder           raw image folder name, 'Jin_HH_MM_SS'
%     material         'ZIF-8' | 'ZIF-67' | 'NU-1003' | 'Microbubble'
%     gasLoaded        true / false (NaN for the microbubble control)
%     fpsMHz           camera frame rate in million frames per second
%     imageDir         folder with the TIFF frames used for DIC
%     maskDir          folder with the binary image masks used for DIC
%     resultDir        folder with R-t data and archived DIC results
%     secondaryTrack   'detected' (circle fit) or 'manual' (see
%                      src/rt/manual_secondary_tracks.m)
%     radiusUpperBound outer bound (px) of the r*-fit region, see
%                      src/postprocessing/fit_rstar_profile.m
%     vonMisesClim     color range of the particle-induced von Mises maps
%     kymographClim    color range of the r*-time kymographs
%     figures          manuscript figure panels that use this recording
%
%   The values below were recovered from the archived MATLAB workspaces
%   (before_sec9.mat) of the analysis that produced the published figures.

caseRows = {
%   id        folder          material       gas   fps  maskSubdir                secondary   vmClim      kymoClim    figures
    '171925', 'Jin_17_19_25', 'ZIF-8',       0,    10,  'smoothed_2',             'detected', [0 0.30],   [0 0.20],   'Fig. 2D; Fig. S9'
    '181404', 'Jin_18_14_04', 'ZIF-8',       1,    10,  'smoothed',               'detected', [0 0.30],   [0 0.20],   'Fig. 2C-D; Fig. S9'
    '172655', 'Jin_17_26_55', 'ZIF-8',       0,    1,   'mask_smoothed',          'detected', [0 0.30],   [0 0.20],   'Fig. 2F; Fig. S10'
    '180814', 'Jin_18_08_14', 'ZIF-8',       1,    1,   '',                       'detected', [0 0.30],   [0 0.20],   'Fig. 2F; Fig. S10'
    '162005', 'Jin_16_20_05', 'NU-1003',     0,    10,  'mask1',                  'manual',   [0 0.30],   [0 0.20],   'Fig. S12'
    '155040', 'Jin_15_50_40', 'NU-1003',     1,    10,  'mask_smoothed',          'detected', [0 0.30],   [0 0.20],   'Fig. S12'
    '162445', 'Jin_16_24_45', 'NU-1003',     0,    1,   'mask_smoothed',          'manual',   [0 0.35],   [0 0.20],   'Fig. S12'
    '160901', 'Jin_16_09_01', 'NU-1003',     1,    1,   'mask_temporal_smoothed', 'detected', [0 0.35],   [0 0.20],   'Fig. S12'
    '163902', 'Jin_16_39_02', 'ZIF-67',      0,    10,  'mask_smoothed',          'manual',   [0 0.30],   [0 0.15],   'Fig. S11'
    '113847', 'Jin_11_38_47', 'ZIF-67',      1,    10,  'mask_smoothed',          'detected', [0 0.30],   [0 0.15],   'Fig. S11'
    '164311', 'Jin_16_43_11', 'ZIF-67',      0,    1,   'mask_smoothed',          'manual',   [0 0.30],   [0 0.15],   'Fig. S11'
    '115047', 'Jin_11_50_47', 'ZIF-67',      1,    1,   'mask_combine_smoothed',  'detected', [0 0.30],   [0 0.15],   'Fig. S11'
    '111031', 'Jin_11_10_31', 'Microbubble', NaN,  10,  'mask_smoothed',          'detected', [0 0.20],   [0 0.15],   'Fig. S13'
    '112138', 'Jin_11_21_38', 'Microbubble', NaN,  1,   'mask_smoothed',          'detected', [0 0.40],   [0 0.25],   'Fig. S13'
};

RADIUS_UPPER_BOUND_PX = 70;  % identical for all recordings in the archive

nCases = size(caseRows, 1);
cases = repmat(emptyCase(), nCases, 1);
for k = 1:nCases
    row = caseRows(k, :);
    material = row{3};
    folder = row{2};
    maskRoot = fullfile(material, [folder '_masks']);
    cases(k) = struct( ...
        'id', row{1}, ...
        'folder', folder, ...
        'material', material, ...
        'gasLoaded', row{4}, ...
        'fpsMHz', row{5}, ...
        'imageDir', fullfile(material, folder), ...
        'maskDir', fullfile(maskRoot, row{6}), ...
        'resultDir', fullfile(material, [folder '_DIC_results']), ...
        'secondaryTrack', row{7}, ...
        'radiusUpperBound', RADIUS_UPPER_BOUND_PX, ...
        'vonMisesClim', row{8}, ...
        'kymographClim', row{9}, ...
        'figures', row{10});
end
end

function c = emptyCase()
c = struct('id', '', 'folder', '', 'material', '', 'gasLoaded', NaN, ...
    'fpsMHz', NaN, 'imageDir', '', 'maskDir', '', 'resultDir', '', ...
    'secondaryTrack', '', 'radiusUpperBound', NaN, 'vonMisesClim', [], ...
    'kymographClim', [], 'figures', '');
end
