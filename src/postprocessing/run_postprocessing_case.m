function outFile = run_postprocessing_case(caseId, varargin)
%RUN_POSTPROCESSING_CASE  Particle-induced strain field and r*-kymograph of one recording.
%
%   outFile = RUN_POSTPROCESSING_CASE(caseId) performs the post-processing
%   of the original Section 8 for every frame of recording caseId:
%     1) cumulative displacement from incremental DIC (if not stored yet);
%     2) strain by plane fitting (STAQ-DIC ComputeStrainQuadtree);
%     3) refinement of the primary-bubble center/R0 (optimize_bubble_4params)
%        starting from the image-based circle fit (R_data_primary.mat);
%     4) particle-induced strain = DIC strain - primary-bubble strain;
%     5) quadratic fit of strain versus r* around the secondary bubble
%        (fit_rstar_profile);
%   and then builds the smoothed kymograph (build_kymograph).
%
%   Output: <outputRoot>/processed/<id>_postprocessing.mat with variables
%     caseInfo, params, fitResults, primaryFit, kymo, imageNames, dicFile
%   Inputs: images, masks and R_data_*.mat of the data set, and a DIC
%   result (see 'dic').
%
%   Name-value options
%     'dic'          'archive' (default): the DIC result of the paper,
%                    <dataRoot>/<resultDir>/before_sec8.mat
%                    'rerun': your own DIC result from run_dic_case,
%                    <outputRoot>/dic/<id>_dic_results.mat
%     'dicFile'      any other DIC result file (overrides 'dic')
%     'params'       parameter struct (default: default_params())
%     'outputDir'    default: <outputRoot>/processed
%     'frames'       image indices to analyse (default: 2:N, all frames)
%     'saveFigures'  write von Mises maps as 300-dpi JPG (default: false),
%                    to <outputRoot>/figures/vonmises_maps/<id>/
%     'figureFrames' frames for which maps are written (default: 2:5:N)
%     'verbose'      print per-frame progress (default: true)

ip = inputParser;
addRequired(ip, 'caseId');
addParameter(ip, 'dic', 'archive', @(x) any(strcmp(x, {'archive', 'rerun'})));
addParameter(ip, 'dicFile', '', @(x) ischar(x) || isstring(x));
addParameter(ip, 'params', default_params(), @isstruct);
addParameter(ip, 'outputDir', '', @(x) ischar(x) || isstring(x));
addParameter(ip, 'frames', [], @isnumeric);
addParameter(ip, 'saveFigures', false, @islogical);
addParameter(ip, 'figureFrames', [], @isnumeric);
addParameter(ip, 'verbose', true, @islogical);
parse(ip, caseId, varargin{:});
opt = ip.Results;
params = opt.params;

caseInfo = get_case(caseId);
paths = resolve_data_paths();
files = case_files(caseInfo, paths);
resultFolder = fullfile(paths.dataRoot, caseInfo.resultDir);
dicFile = char(opt.dicFile);
if isempty(dicFile)
    if strcmp(opt.dic, 'rerun')
        dicFile = files.rerunDic;
    else
        dicFile = files.archivedDic;
    end
end
outputDir = char(opt.outputDir);
if isempty(outputDir)
    outputDir = fileparts(files.rerunProcessed);
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

% ---------------------------------------------------------------------
% Inputs: DIC results, images, masks, bubble R-t data
% ---------------------------------------------------------------------
if ~isfile(dicFile)
    error('run_postprocessing_case:MissingDicFile', 'DIC result file not found: %s', dicFile);
end
S = load(dicFile, 'DICpara', 'DICmesh', 'ResultDisp', 'ResultFEMeshEachFrame');
DICpara = S.DICpara;
DICmesh = S.DICmesh;
ResultDisp = S.ResultDisp;
ResultFEMeshEachFrame = S.ResultFEMeshEachFrame;

[file_name, Img] = load_case_images(fullfile(paths.dataRoot, caseInfo.imageDir), params.dic);
nImages = numel(Img);
if nImages ~= numel(ResultDisp) + 1
    error('run_postprocessing_case:FrameMismatch', ...
        '%d images but %d DIC increments in %s.', nImages, numel(ResultDisp), dicFile);
end
[~, ImgMask] = load_case_masks(fullfile(paths.dataRoot, caseInfo.maskDir), nImages);
ImgNormalized = funNormalizeImg(Img, DICpara.gridxyROIRange);
clear Img
rt = load_rt_data(resultFolder, nImages);

if ~isfield(ResultDisp{1}, 'U_accum')
    ResultDisp = compute_cumulative_displacement(ResultDisp, ResultFEMeshEachFrame);
end

frames = opt.frames;
if isempty(frames)
    frames = 2:nImages;
end
frames = frames(:).';
if any(frames < 2 | frames > nImages | frames ~= round(frames))
    error('run_postprocessing_case:BadFrames', ...
        'frames must be integers in 2..%d (image 1 is the reference).', nImages);
end
figureFrames = opt.figureFrames;
if isempty(figureFrames)
    figureFrames = 2:5:nImages;
end

% ---------------------------------------------------------------------
% Strain settings (previously entered through funParaInput prompts)
% ---------------------------------------------------------------------
DICpara.um2px = params.post.um2px;
DICpara.smoothness = params.post.smoothness;
DICpara.DoYouWantToSmoothOnceMore = double(DICpara.smoothness ~= 0);
DICpara.MethodToComputeStrain = params.post.MethodToComputeStrain;
DICpara.StrainType = params.post.StrainType;
DICpara.Image2PlotResults = params.post.Image2PlotResults;
DICpara.OrigDICImgTransparency = params.post.OrigDICImgTransparency;
DICpara.vonMisesStrainBounds = params.post.vonMisesStrainBounds;
Rad = params.post.strainHalfWindow; %#ok<NASGU> used by ComputeStrainQuadtree

imageHeightPlusOne = size(ImgNormalized{1}, 2) + 1;  % y flip of image coordinates
fitOpts = struct('radiusUpperBound', caseInfo.radiusUpperBound, ...
    'vonMisesStrainBounds', params.post.vonMisesStrainBounds, ...
    'rstarOuterFactor', params.post.rstarOuterFactor);

fitResults = repmat(empty_fit_result(), nImages - 1, 1);
primaryFit = repmat(empty_primary_fit(), nImages - 1, 1);
figureDir = files.vonMisesMaps;
if opt.saveFigures && ~isfolder(figureDir)
    mkdir(figureDir);
end

% ---------------------------------------------------------------------
% Frame loop (original Section 8)
% ---------------------------------------------------------------------
for ImgSeqNum = frames
    if opt.verbose
        fprintf('Case %s: frame %d / %d\n', caseInfo.id, ImgSeqNum, nImages);
    end

    % ------ Current frame, reference mask, cumulative displacement ------
    gNormalizedMask = double(ImgMask{ImgSeqNum});
    gNormalized = ImgNormalized{ImgSeqNum} .* gNormalizedMask;
    Dg = funImgGradient(gNormalized, gNormalized, gNormalizedMask); %#ok<NASGU>
    DICpara.ImgRefMask = double(ImgMask{1});

    coordinatesFEM = ResultFEMeshEachFrame{1}.coordinatesFEM;
    elementsFEM = ResultFEMeshEachFrame{1}.elementsFEM;
    DICmesh.coordinatesFEM = coordinatesFEM;
    DICmesh.elementsFEM = elementsFEM;
    coordinatesFEMWorld = DICpara.um2px * [coordinatesFEM(:, 1), ...
        size(ImgNormalized{1}, 2) + 1 - coordinatesFEM(:, 2)];

    ULocal = ResultDisp{ImgSeqNum - 1}.U_accum;
    UWorld = DICpara.um2px * ULocal;
    UWorld(2:2:end) = -UWorld(2:2:end);

    % ------ Displacement smoothing before strain (3 passes when smoothness = 0) ------
    SmoothTimes = 0;
    try
        while DICpara.DoYouWantToSmoothOnceMore == 0 && SmoothTimes < params.post.maxSmoothTimes
            ULocal = funSmoothDispQuadtree(ULocal, DICmesh, DICpara);
            SmoothTimes = SmoothTimes + 1;
        end
    catch smoothErr
        warning('run_postprocessing_case:Smoothing', ...
            'Frame %d: displacement smoothing stopped after %d passes (%s).', ...
            ImgSeqNum, SmoothTimes, smoothErr.message);
    end

    % ------ Strain by plane fitting (STAQ-DIC script, defines FStrainWorld) ------
    FStrainWorld = [];
    ComputeStrainQuadtree;
    if isempty(FStrainWorld)
        error('run_postprocessing_case:Strain', 'Frame %d: ComputeStrainQuadtree returned no strain.', ImgSeqNum);
    end

    % ------ Primary bubble: circle fit -> local model refinement ------
    R0_initial = rt.primaryR(1);
    R = rt.primaryR(ImgSeqNum);
    Xc0_initial = rt.primaryCenter(ImgSeqNum, 2);
    Yc0_initial = imageHeightPlusOne - rt.primaryCenter(ImgSeqNum, 1);
    if params.post.optimizePrimary
        [Xc0, Yc0, R0, R, residual] = optimize_bubble_4params(UWorld, coordinatesFEMWorld, ...
            Xc0_initial, Yc0_initial, R0_initial, R, ...
            'center_search_range', params.post.centerSearchRange, ...
            'center_resolution', params.post.centerResolution, ...
            'radius_search_range', params.post.radiusSearchRange, ...
            'radius_resolution', params.post.radiusResolution, ...
            'max_iterations', params.post.maxIterations, ...
            'local_radius', params.post.localRadiusFactor * R);
    else
        Xc0 = Xc0_initial;
        Yc0 = Yc0_initial;
        R0 = R0_initial;
        residual = NaN;
    end
    primaryFit(ImgSeqNum - 1) = struct('frame', ImgSeqNum, ...
        'Xc0_initial', Xc0_initial, 'Yc0_initial', Yc0_initial, 'R0_initial', R0_initial, ...
        'Xc0', Xc0, 'Yc0', Yc0, 'R0', R0, 'R', R, 'residual', residual);

    % ------ Particle-induced (secondary) strain ------
    strainFields = compute_secondary_strain(FStrainWorld, coordinatesFEMWorld, ...
        Xc0, Yc0, R0, R);

    % ------ r* profile around the secondary bubble ------
    coordsCurrent = coordinatesFEMWorld + DICpara.Image2PlotResults * ...
        [UWorld(1:2:end), UWorld(2:2:end)];
    secCenter = rt.secondaryCenter(ImgSeqNum, :);
    centerXY = [secCenter(2), imageHeightPlusOne - secCenter(1)];
    fitResults(ImgSeqNum - 1) = fit_rstar_profile(coordsCurrent, ...
        strainFields.secondary.vonMises, strainFields.secondary.principalMax, ...
        centerXY, rt.secondaryR(ImgSeqNum), rt.secondaryR(1), ImgSeqNum, fitOpts);

    % ------ Optional full-field figure ------
    if opt.saveFigures && ismember(ImgSeqNum, figureFrames)
        imageFile = fullfile(file_name{2, ImgSeqNum}, file_name{1, ImgSeqNum});
        fig = plot_secondary_vonmises(imageFile, ImgMask{ImgSeqNum}, coordinatesFEMWorld, ...
            UWorld, elementsFEM, real(strainFields.secondary.vonMises), DICpara, ...
            caseInfo.vonMisesClim, 'off');
        [~, imgname] = fileparts(imageFile);
        jpgName = sprintf('%s_WS%d_ST%d_strain_vonMises', imgname, ...
            DICpara.winsize, DICpara.winstepsize);
        print(fig, fullfile(figureDir, jpgName), '-djpeg', '-r300');
        close(fig);
    end
end

% ---------------------------------------------------------------------
% Kymograph and output
% ---------------------------------------------------------------------
kymo = build_kymograph(fitResults, caseInfo.fpsMHz, params.kymo);
imageNames = file_name(1, :);
outFile = fullfile(outputDir, sprintf('%s_postprocessing.mat', caseInfo.id));
save(outFile, 'caseInfo', 'params', 'fitResults', 'primaryFit', 'kymo', 'imageNames', 'dicFile');
fprintf('Saved post-processing results: %s\n', outFile);
end

function f = empty_fit_result()
f = struct('frame', NaN, ...
    'principal_coeff', nan(1, 3), 'principal_range', nan(1, 2), 'principal_residual', [], ...
    'vonmises_coeff', nan(1, 3), 'vonmises_range', nan(1, 2), 'vonmises_residual', []);
end

function p = empty_primary_fit()
p = struct('frame', NaN, 'Xc0_initial', NaN, 'Yc0_initial', NaN, 'R0_initial', NaN, ...
    'Xc0', NaN, 'Yc0', NaN, 'R0', NaN, 'R', NaN, 'residual', NaN);
end
