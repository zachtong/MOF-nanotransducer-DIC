function p = default_params()
%DEFAULT_PARAMS  Analysis parameters used for all recordings.
%
%   p = DEFAULT_PARAMS() returns a struct with three groups:
%     p.dic   STAQ-DIC settings (previously entered interactively)
%     p.post  strain computation, primary-bubble fit and r* analysis
%     p.kymo  kymograph reconstruction and smoothing
%
%   All values were recovered from the archived workspaces of the analysis
%   behind the published figures (DICpara and workspace variables in
%   <case>_DIC_results/before_sec9.mat). Change them only on purpose.

% ---------------------------------------------------------------------
% DIC (STAQ-DIC, incremental mode, every frame is a new reference)
% ---------------------------------------------------------------------
p.dic.winsize = 20;                 % subset size (px)
p.dic.winstepsize = 8;              % subset step (px)
p.dic.winsizeMin = 2;               % finest quadtree element size (px)
p.dic.useFullImageROI = true;       % ROI = whole image ([1 W] x [1 H])
p.dic.Subpb2FDOrFEM = 1;            % global step: finite element
p.dic.ClusterNo = 1;                % parallel workers (does not change results)
p.dic.NewFFTSearch = 1;             % new FFT search for every frame
p.dic.ImgSeqIncUnit = 1;            % incremental mode, update every frame
p.dic.ImgSeqIncROIUpdateOrNot = 1;
p.dic.LoadImgMethod = 0;            % "image folder" (kept for provenance)
p.dic.InitFFTSearchMethod = 1;      % whole-field FFT initial guess
p.dic.SizeOfFFTSearchRegion = [8, 8]; % overwritten in IntegerSearch (zone fixed to 120 px)
p.dic.discontinuityCcThreshold = 0.85; % initial-guess split, see run_dic_case
p.dic.discontinuityKnn = 3;
p.dic.useGlobalStep = true;         % run ALDIC global step + ADMM

% ---------------------------------------------------------------------
% Strain computation and primary/secondary separation (Section 8)
% ---------------------------------------------------------------------
p.post.um2px = 1;                   % keep pixel units (bubble data are in px)
p.post.smoothness = 0;              % -> displacement smoothing applied 3x
p.post.maxSmoothTimes = 3;
p.post.MethodToComputeStrain = 2;   % plane fitting
p.post.strainHalfWindow = 40;       % plane-fit half window "Rad" (px)
p.post.StrainType = 2;              % Green-Lagrangian
p.post.Image2PlotResults = 1;       % plot on deformed images
p.post.OrigDICImgTransparency = 0.7;

% Primary-bubble parameter refinement (optimize_bubble_4params)
p.post.optimizePrimary = true;
p.post.centerSearchRange = 3;       % px
p.post.centerResolution = 11;
p.post.radiusSearchRange = 3;       % px
p.post.radiusResolution = 21;
p.post.maxIterations = 10;
p.post.localRadiusFactor = 1.2;     % local region = 1.2 x current radius

% r* analysis around the secondary (particle) bubble
p.post.vonMisesStrainBounds = [0, 0.3];
p.post.rstarOuterFactor = 3;        % r < 3 R0_s

% ---------------------------------------------------------------------
% Kymograph (r*, t, von Mises strain)
% ---------------------------------------------------------------------
p.kymo.rStarGrid = 1.01:0.01:3;
p.kymo.frameCut = 4;                % first frames kept unsmoothed
p.kymo.sigmaR = 0.5;                % Gaussian sigma along r*
p.kymo.sigmaT = 2;                  % Gaussian sigma along time
p.kymo.medianWindow = 5;            % temporal median filter length
p.kymo.rLines = [1.5, 2.0, 2.5];    % r* values of the strain-time curves
end
