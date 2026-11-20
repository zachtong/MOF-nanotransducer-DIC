function dicFile = run_dic_case(caseId, varargin)
%RUN_DIC_CASE  Incremental STAQ-DIC for one recording (original Sections 1-7).
%
%   dicFile = RUN_DIC_CASE(caseId) runs DIC on the image sequence of the
%   recording caseId (see config/case_table.m) and writes
%   <outputRoot>/dic/<id>_dic_results.mat with the same variables as the
%   original analysis (the archived before_sec8.mat holds the same
%   variables):
%     file_name, DICpara, DICmesh, ResultDisp, ResultDefGrad, ResultFEMesh,
%     ResultFEMeshEachFrame, ALSub1Time, ALSub2Time, ALSolveStep
%   Use it with run_postprocessing_case(caseId, 'dic', 'rerun') and
%   compare_dic_with_archive(caseId).
%
%   Name-value options
%     'params'     parameter struct (default: default_params())
%     'outputDir'  folder for the result file (default: <outputRoot>/dic)
%     'showPlots'  show the per-frame diagnostic figures (default: false)
%
%   The frame loop is the original code (main_ALDIC_Quadtree_inc_Wenliang.m,
%   lines 102-662) with dead commented-out blocks removed; see
%   docs/provenance.md. Interactive image/ROI/parameter input was replaced
%   by config/default_params.m and config/case_table.m.
%
%   STAQ-DIC writes ADMM intermediate files (Subpb1_step*.mat, ...) to the
%   current folder; they are written to <outputDir>/admm_tmp_<id> and
%   removed at the end.

ip = inputParser;
addRequired(ip, 'caseId');
addParameter(ip, 'params', default_params(), @isstruct);
addParameter(ip, 'outputDir', '', @(x) ischar(x) || isstring(x));
addParameter(ip, 'showPlots', false, @islogical);
parse(ip, caseId, varargin{:});
params = ip.Results.params;
showPlots = ip.Results.showPlots;

caseInfo = get_case(caseId);
paths = resolve_data_paths();
files = case_files(caseInfo, paths);
outputDir = char(ip.Results.outputDir);
if isempty(outputDir)
    outputDir = fileparts(files.rerunDic);
end
outputDir = make_absolute(outputDir);  % the current folder changes below
[~, dicName, dicExt] = fileparts(files.rerunDic);
dicFile = fullfile(outputDir, [dicName dicExt]);
if ~isfolder(outputDir)
    mkdir(outputDir);
end

fprintf('=== DIC for case %s (%s, %s) ===\n', caseInfo.id, caseInfo.material, caseInfo.folder);

% ====== Load images, masks and DIC parameters ======
[file_name, Img, DICpara] = load_case_images( ...
    fullfile(paths.dataRoot, caseInfo.imageDir), params.dic);
[~, ImgMask] = load_case_masks(fullfile(paths.dataRoot, caseInfo.maskDir), numel(Img));

% ====== Work folder for ADMM intermediate files; hide library figures ======
workDir = fullfile(outputDir, ['admm_tmp_' caseInfo.id]);
if ~isfolder(workDir)
    mkdir(workDir);
end
previousDir = cd(workDir);
restoreDir = onCleanup(@() cd(previousDir));
if ~showPlots
    % STAQ-DIC functions (IntegerSearch, GenerateQuadtreeMesh) open figures
    % on every frame; keep them invisible unless showPlots is requested.
    previousVisibility = get(groot, 'DefaultFigureVisible');
    set(groot, 'DefaultFigureVisible', 'off');
    restoreVisibility = onCleanup(@() set(groot, 'DefaultFigureVisible', previousVisibility));
end

% ====== Normalize images: fNormalized = (f-f_avg)/(f_std) ======
[ImgNormalized, DICpara.gridxyROIRange] = funNormalizeImg(Img, DICpara.gridxyROIRange);

% ====== Initialize variable storage ======
ResultDisp = cell(length(ImgNormalized) - 1, 1);
ResultDefGrad = cell(length(ImgNormalized) - 1, 1);
ResultFEMeshEachFrame = cell(length(ImgNormalized) - 1, 1);
ResultFEMesh = cell(ceil((length(ImgNormalized) - 1) / DICpara.ImgSeqIncUnit), 1);
% Overwritten inside IntegerSearch (search zone fixed to 120 px there)
DICpara.SizeOfFFTSearchRegion = params.dic.SizeOfFFTSearchRegion;
useGlobalStep = params.dic.useGlobalStep;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Solve each frame of the image sequence (original code below)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ImgSeqNum = 2 : length(ImgNormalized)

    close all;
    DICpara.NewFFTSearch = 1; % Apply the new FFT search since the incremental disp is small between two consecutive frames
    disp(['Current image frame #: ', num2str(ImgSeqNum),'/',num2str(length(ImgNormalized))]); % Report current frame #

    % ====== Compute image gradients ======
    fNormalizedMask = double( ImgMask{ImgSeqNum-1} ) ; % Load the mask file of previous frame
    fNormalized = ImgNormalized{ImgSeqNum-1} .* fNormalizedMask; % Load previous frame
    Df = funImgGradient(fNormalized,fNormalized,fNormalizedMask); % Finite difference to compute image grayscale gradients;

    gNormalizedMask = double(ImgMask{ImgSeqNum}); % Load the mask file of current frame
    gNormalized = ImgNormalized{ ImgSeqNum } .* gNormalizedMask ; % Load current deformed image frame

    DICpara.ImgRefMask = fNormalizedMask;

    if showPlots
        figure,
        subplot(2,2,1); imshow(fNormalized'); title('fNormalized'); colorbar;
        subplot(2,2,2); imshow(gNormalized'); title('gNormalized'); colorbar;
        subplot(2,2,3); imshow(fNormalizedMask'); title('f mask'); colorbar;
        subplot(2,2,4); imshow(gNormalizedMask'); title('g mask'); colorbar;
    end

    %% Section 3: Compute an initial guess of the unknown displacement field
    fprintf('\n'); fprintf('------------ Section 3 Start ------------ \n')
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This section is to find or update an initial guess of the unknown displacements.
    % The key idea is to either to use a new FFT-based cross correlation peak fitting,
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ====== FFT-based cross correlation ======
    DICpara.InitFFTSearchMethod = params.dic.InitFFTSearchMethod;  % 1: whole-field FFT
    [DICpara,x0temp_f,y0temp_f,u_f,v_f,cc] = IntegerSearch(fNormalized,gNormalized,file_name,DICpara);

    % ====== Initial guess on the DIC grid (modified 2025-06-24) ======
    % Points with FFT cross-correlation peak cc < threshold are treated as
    % discontinuous and filled by nearest neighbour; all other points by a
    % thin-plate RBF + regularizeNd fit (replaces the upstream RBF step).
    xnodes = max([1+0.5*DICpara.winsize,DICpara.gridxyROIRange.gridx(1)])  ...
        : DICpara.winstepsize : min([size(fNormalized,1)-0.5*DICpara.winsize-1,DICpara.gridxyROIRange.gridx(2)]);
    ynodes = max([1+0.5*DICpara.winsize,DICpara.gridxyROIRange.gridy(1)])  ...
        : DICpara.winstepsize : min([size(fNormalized,2)-0.5*DICpara.winsize-1,DICpara.gridxyROIRange.gridy(2)]);

    [x0temp,y0temp] = ndgrid(xnodes,ynodes);

    % A point is only valid if BOTH its u and v displacements are valid numbers.
    valid_indices_u = find(~isnan(u_f(:)));
    valid_indices_v = find(~isnan(v_f(:)));
    valid_indices = intersect(valid_indices_u, valid_indices_v);

    % Define the correlation threshold.
    discontinuity_threshold_cc = params.dic.discontinuityCcThreshold; % 0.85 in the analysis

    % This creates a list of local indices relative to the 'valid_indices' vector.
    low_cc_local_indices = find(cc.max(valid_indices) < discontinuity_threshold_cc);

    % Map these local indices back to the original, global indices to get the final list.
    discontinuity_indices = valid_indices(low_cc_local_indices);

    % The smooth indices are all valid points that are not in the discontinuous list.
    smooth_indices = setdiff(valid_indices, discontinuity_indices);

    % This part creates a smooth, continuous field based on high-quality data.
    if ~isempty(smooth_indices)
        % Create the interpolation model using only points from the smooth region.
        op1_smooth = rbfcreate([x0temp_f(smooth_indices), y0temp_f(smooth_indices)]', [u_f(smooth_indices)]', 'RBFFunction', 'thinplate');
        u_smooth = rbfinterp([x0temp(:), y0temp(:)]', op1_smooth);

        op2_smooth = rbfcreate([x0temp_f(smooth_indices), y0temp_f(smooth_indices)]', [v_f(smooth_indices)]', 'RBFFunction', 'thinplate');
        v_smooth = rbfinterp([x0temp(:), y0temp(:)]', op2_smooth);

        % Regularize the smooth field to remove noise.
        u_final = regularizeNd([x0temp(:), y0temp(:)], u_smooth(:), {xnodes', ynodes'}, 1e-3);
        v_final = regularizeNd([x0temp(:), y0temp(:)], v_smooth(:), {xnodes', ynodes'}, 1e-3);
    else
        % The discontinuous region will overwrite parts of this later if it exists.
        u_final = nan(size(x0temp));
        v_final = nan(size(x0temp));
    end

    % This part handles low-correlation points, preserving sharp jumps in displacement.
    if ~isempty(discontinuity_indices)
        % Use knnsearch for a robust nearest-neighbor lookup, avoiding convex hull issues.
        % This is more reliable than scatteredInterpolant for this purpose.
        discontinuous_points_coords = [x0temp_f(discontinuity_indices), y0temp_f(discontinuity_indices)];

        % Process u-displacement
        discontinuous_u_values = u_f(discontinuity_indices);
        nearest_idx_u = knnsearch(discontinuous_points_coords, [x0temp(:), y0temp(:)]);
        u_discontinuous = reshape(discontinuous_u_values(nearest_idx_u), size(x0temp));

        % Process v-displacement
        discontinuous_v_values = v_f(discontinuity_indices);
        nearest_idx_v = knnsearch(discontinuous_points_coords, [x0temp(:), y0temp(:)]);
        v_discontinuous = reshape(discontinuous_v_values(nearest_idx_v), size(x0temp));

        % --- Create a mask to identify where to apply the discontinuous values ---
        % Define the neighborhood size for mapping the discontinuity.
        k_nearest_neighbors = params.dic.discontinuityKnn; % 3 in the analysis

        % For each point in the new grid, find the indices of its k nearest neighbors
        [~, nearest_indices_in_orig_grid] = pdist2([x0temp_f(:), y0temp_f(:)], [x0temp(:), y0temp(:)], 'euclidean', 'Smallest', k_nearest_neighbors);

        % A new grid point is considered part of the discontinuous region if any of its
        % k neighbors were flagged as discontinuous.
        is_neighbor_discontinuous = ismember(nearest_indices_in_orig_grid, discontinuity_indices);
        is_discontinuous_on_new_grid = any(is_neighbor_discontinuous, 1);
        is_discontinuous_on_new_grid = reshape(is_discontinuous_on_new_grid, size(x0temp));

        % --- Overwrite the discontinuous regions in the final field ---
        u_final(is_discontinuous_on_new_grid) = u_discontinuous(is_discontinuous_on_new_grid);
        v_final(is_discontinuous_on_new_grid) = v_discontinuous(is_discontinuous_on_new_grid);
    end

    % Use the combined u_final and v_final for subsequent Init and MeshSetUp steps.
    u = u_final;
    v = v_final;

    % ====== DIC uniform FE-mesh set up ======
    [DICmesh] = MeshSetUp(x0temp,y0temp,DICpara); % clear x0temp y0temp;
    % ====== Initial Value ======
    U0 = Init(u,v,cc.max,DICmesh.x0,DICmesh.y0,0); % [Temp code:] PlotuvInit;

    % ====== Set the initial guess to NaN at masked (hole) nodes ======
    linearIndices1 = sub2ind(size(fNormalizedMask), DICmesh.coordinatesFEM(:,1), DICmesh.coordinatesFEM(:,2));
    MaskOrNot1 = fNormalizedMask(linearIndices1);

    nanIndex = find(MaskOrNot1<1);
    U0(2*nanIndex) = nan;
    U0(2*nanIndex-1) = nan;

    % ====== Deal with incremental mode ======
    fNormalizedNewIndex = ImgSeqNum-mod(ImgSeqNum-2,DICpara.ImgSeqIncUnit)-1;
    if DICpara.ImgSeqIncUnit == 1, fNormalizedNewIndex = fNormalizedNewIndex-1; end
    ResultFEMesh{1+floor(fNormalizedNewIndex/DICpara.ImgSeqIncUnit)} = ... % To save first mesh info
        struct( 'coordinatesFEM',DICmesh.coordinatesFEM,'elementsFEM',DICmesh.elementsFEM, ...
        'winsize',DICpara.winsize,'winstepsize',DICpara.winstepsize,'gridxyROIRange',DICpara.gridxyROIRange );

    % ====== Generate a quadtree mesh considering sample's complex geometry ======
    DICmesh.elementMinSize = DICpara.winsizeMin; % min element size in the refined quadtree mesh

    % Notes:
    % Hanging nodes and sub-elements are placed on the last
    % All the void regions are generating nodes but we can ignore them
    % using maskfile later.
    GenerateQuadtreeMesh; % Generate the quadtree mesh
    if showPlots
        Plotdisp_show(U0,DICmesh.coordinatesFEMWorld,DICmesh.elementsFEM(:,1:4),DICpara,'EdgeColor');
    end

    % ====== Store current mesh ======
    ResultFEMeshEachFrame{ImgSeqNum-1} = struct( 'coordinatesFEM',DICmesh.coordinatesFEM,'elementsFEM',DICmesh.elementsFEM,'markCoordHoleEdge',DICmesh.markCoordHoleEdge );
    fprintf('------------ Section 3 Done ------------ \n \n')

    %% Section 4: ALDIC Subproblem 1 -or- Local ICGN Subset DIC
    fprintf('------------ Section 4 Start ------------ \n')
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This section is to solve the first local step in ALDIC: Subproblem 1
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % ====== ALStep 1 Subproblem1: Local Subset DIC ======
    mu=0; beta=0; tol=1e-2; ALSolveStep=1; ALSub1Time=zeros(6,1); ALSub2Time=zeros(6,1);
    ConvItPerEle=zeros(size(DICmesh.coordinatesFEM,1),6); ALSub1BadPtNum=zeros(6,1);
    disp(['***** Start step',num2str(ALSolveStep),' Subproblem1 *****'])
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ------ Start Local DIC IC-GN iteration ------
    [USubpb1,FSubpb1,HtempPar,ALSub1Timetemp,ConvItPerEletemp,LocalICGNBadPtNumtemp,markCoordHoleStrain] = ...
        LocalICGNQuadtree(U0,DICmesh.coordinatesFEM,Df,fNormalized,gNormalized,DICpara,'GaussNewton',tol);
    ALSub1Time(ALSolveStep) = ALSub1Timetemp; ConvItPerEle(:,ALSolveStep) = ConvItPerEletemp; ALSub1BadPtNum(ALSolveStep) = LocalICGNBadPtNumtemp; toc
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % (Upstream thin-plate interpolation of bad Subproblem-1 points is
    %  disabled in this analysis.)
    coordinatesFEM = DICmesh.coordinatesFEM;
    U = USubpb1; F = FSubpb1;
    USubpb1World = USubpb1; USubpb1World(2:2:end) = -USubpb1(2:2:end); FSubpb1World = FSubpb1;

    if showPlots
        Plotdisp_show(USubpb1World,DICmesh.coordinatesFEMWorld,DICmesh.elementsFEM(:,1:4),DICpara,'EdgeColor');
        Plotstrain_show(FSubpb1World,DICmesh.coordinatesFEMWorld,DICmesh.elementsFEM(:,1:4),DICpara,'EdgeColor');
    end
    save(['Subpb1_step',num2str(ALSolveStep)],'USubpb1','FSubpb1');
    fprintf('------------ Section 4 Done ------------ \n \n')

    if useGlobalStep
        %% Section 5: Subproblem 2 -- solve the global compatible displacement field
        fprintf('------------ Section 5 Start ------------ \n'); tic;
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % This section is to solve the global step in ALDIC Subproblem 2
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % ======= ALStep 1 Subproblem 2: Global constraint =======
        % ------ Smooth displacements for a better F ------
        DICpara.DispFilterSize=0; DICpara.DispFilterStd=0; DICpara.StrainFilterSize=0; DICpara.StrainFilterStd=0; LevelNo=1;
        DICpara.DispSmoothness = 0; DICpara.StrainSmoothness = 0;
        if DICpara.DispSmoothness>1e-6, USubpb1 = funSmoothDispQuadtree(USubpb1,DICmesh,DICpara); end
        if DICpara.StrainSmoothness>1e-6, FSubpb1 = funSmoothStrainQuadtree(FSubpb1,DICmesh,DICpara); end

        % ====== Define penalty parameter ======
        mu = 1e-3; udual = 0*FSubpb1; vdual = 0*USubpb1;
        betaList = [1e-3,1e-2,1e-1]*mean(DICpara.winstepsize).^2.*mu; % Tune beta in the betaList
        Err1 = zeros(length(betaList),1); Err2 = Err1;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp(['***** Start step',num2str(ALSolveStep),' Subproblem2 *****']);
        DICpara.GaussPtOrder = 2; alpha = 0;  % No regularization added
        % ====== Solver using finite element method ======
        if ImgSeqNum == 2
            for tempk = 1:length(betaList)
                beta = betaList(tempk); display(['Try #',num2str(tempk),' beta = ',num2str(beta)]);
                GaussPtOrder=3; alpha=0; [USubpb2] = Subpb2Quadtree(DICmesh,DICpara.GaussPtOrder,beta,mu,USubpb1,FSubpb1,udual,vdual,alpha,mean(DICpara.winstepsize),0);
                [FSubpb2,~,~] = funGlobalNodalStrainQuadtree(DICmesh,USubpb2,DICpara.GaussPtOrder,0);

                Err1(tempk) = norm(USubpb1-USubpb2,2);
                Err2(tempk) = norm(FSubpb1-FSubpb2,2);
            end

            Err1Norm = (Err1-mean(Err1))/std(Err1); % figure, plot(Err1Norm);
            Err2Norm = (Err2-mean(Err2))/std(Err2); % figure, plot(Err2Norm);
            ErrSum = Err1Norm+Err2Norm; % figure, plot(ErrSum); title('Tune the best \beta in the subproblem 2');
            [~,indexOfbeta] = min(ErrSum);

            try % Tune the best beta by a quadratic polynomial 0fitting
                [fitobj] = fit(log10(betaList(indexOfbeta-1:1:indexOfbeta+1))',ErrSum(indexOfbeta-1:1:indexOfbeta+1),'poly2');
                p = coeffvalues(fitobj); beta = 10^(-p(2)/2/p(1));
            catch, beta = betaList(indexOfbeta);
            end
            display(['Best beta = ',num2str(beta)]);
        else
            try beta = DICpara.beta;
            catch, beta = 1e-3*mean(DICpara.winstepsize).^2.*mu;
            end
        end

        % Using the optimal beta to solve the ALDIC Subproblem 2 again
        if abs(beta-betaList(end))>abs(eps)
            [USubpb2] = Subpb2Quadtree(DICmesh,DICpara.GaussPtOrder,beta,mu,USubpb1,FSubpb1,udual,vdual,alpha,mean(DICpara.winstepsize),0);
            [FSubpb2,~,~] = funGlobalNodalStrainQuadtree(DICmesh,USubpb2,DICpara.GaussPtOrder,0);
            ALSub2Time(ALSolveStep) = toc; toc
        end

        % ------- Smooth strain field --------
        if DICpara.DispSmoothness>1e-6, USubpb2 = funSmoothDispQuadtree(USubpb2,DICmesh,DICpara); end
        % ------- Don't smooth strain fields near the boundary --------
        for tempk=0:3, FSubpb2(4*DICmesh.markCoordHoleEdge-tempk) = FSubpb1(4*DICmesh.markCoordHoleEdge-tempk); end
        if DICpara.StrainSmoothness>1e-6, FSubpb2 = funSmoothStrainQuadtree(0.1*FSubpb2+0.9*FSubpb1,DICmesh,DICpara); end
        for tempk=0:1, USubpb2(2*markCoordHoleStrain-tempk) = USubpb1(2*markCoordHoleStrain-tempk); end
        for tempk=0:3, FSubpb2(4*markCoordHoleStrain-tempk) = FSubpb1(4*markCoordHoleStrain-tempk); end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % ------- Save data ------
        save(['Subpb2_step',num2str(ALSolveStep)],'USubpb2','FSubpb2');

        % ======= Update dual variables =======
        udual = FSubpb2 - FSubpb1; vdual = USubpb2 - USubpb1;
        save(['uvdual_step',num2str(ALSolveStep)],'udual','vdual');
        fprintf('------------ Section 5 Done ------------ \n \n')

        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Section 6: ADMM iterations
        fprintf('------------ Section 6 Start ------------ \n')
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % This section is the ADMM iteration, where both Subproblems 1 & 2 are solved iteratively.
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % ==================== ADMM AL Loop ==========================
        ALSolveStep = 1; tol2 = 1e-2; UpdateY = 1e4;
        HPar = cell(21,1); for tempj = 1:21, HPar{tempj} = HtempPar(:,tempj); end

        while (ALSolveStep < 3)
            ALSolveStep = ALSolveStep + 1;  % Update using the last step

            winsize_List = DICpara.winsize*ones(size(DICmesh.coordinatesFEM,1),2);
            DICpara.winsize_List = winsize_List;

            %%%%%%%%%%%%%%%%%%%%%%% Subproblem 1 %%%%%%%%%%%%%%%%%%%%%%%%%
            disp(['***** Start step',num2str(ALSolveStep),' Subproblem1 *****']);
            tic; [USubpb1,~,ALSub1Timetemp,ConvItPerEletemp,LocalICGNBadPtNumtemp] = Subpb1Quadtree(...
                USubpb2,FSubpb2,udual,vdual,DICmesh.coordinatesFEM,...
                Df,fNormalized,gNormalized,mu,beta,HPar,ALSolveStep,DICpara,'GaussNewton',tol);
            FSubpb1 = FSubpb2; toc
            % for tempk=0:1, USubpb1(2*markCoordHoleStrain-tempk) = USubpb2(2*markCoordHoleStrain-tempk); end
            ALSub1Time(ALSolveStep) = ALSub1Timetemp; ConvItPerEle(:,ALSolveStep) = ConvItPerEletemp; ALSub1BadPtNum(ALSolveStep) = LocalICGNBadPtNumtemp;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            save(['Subpb1_step',num2str(ALSolveStep)],'USubpb1','FSubpb1');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ============== Subproblem 2 ==============
            disp(['***** Start step',num2str(ALSolveStep),' Subproblem2 *****'])
            tic; [USubpb2] = Subpb2Quadtree(DICmesh,DICpara.GaussPtOrder,beta,mu,USubpb1,FSubpb1,udual,vdual,alpha,mean(DICpara.winstepsize),0);
            [FSubpb2,~,~] = funGlobalNodalStrainQuadtree(DICmesh,USubpb2,DICpara.GaussPtOrder,0);
            ALSub2Time(ALSolveStep) = toc; toc

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ------- Smooth strain field --------
            if DICpara.DispSmoothness>1e-6, USubpb2 = funSmoothDispQuadtree(USubpb2,DICmesh,DICpara); end
            % ------- Don't change strain fields near the boundary --------
            for tempk=0:3, FSubpb2(4*DICmesh.markCoordHoleEdge-tempk) = FSubpb1(4*DICmesh.markCoordHoleEdge-tempk); end
            if DICpara.StrainSmoothness>1e-6, FSubpb2 = funSmoothStrainQuadtree(0.1*FSubpb2+0.9*FSubpb1,DICmesh,DICpara); end
            for tempk=0:1, USubpb2(2*markCoordHoleStrain-tempk) = USubpb1(2*markCoordHoleStrain-tempk); end
            for tempk=0:3, FSubpb2(4*markCoordHoleStrain-tempk) = FSubpb1(4*markCoordHoleStrain-tempk); end

            save(['Subpb2_step',num2str(ALSolveStep)],'USubpb2','FSubpb2');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Compute norm of UpdateY
            USubpb2_Old = load(['Subpb2_step',num2str(ALSolveStep-1)],'USubpb2');
            USubpb2_New = load(['Subpb2_step',num2str(ALSolveStep)],'USubpb2');
            USubpb1_Old = load(['Subpb1_step',num2str(ALSolveStep-1)],'USubpb1');
            USubpb1_New = load(['Subpb1_step',num2str(ALSolveStep)],'USubpb1');
            if (mod(ImgSeqNum-2,DICpara.ImgSeqIncUnit) ~= 0 && (ImgSeqNum>2)) || (ImgSeqNum < DICpara.ImgSeqIncUnit)
                UpdateY = norm((USubpb2_Old.USubpb2 - USubpb2_New.USubpb2), 2)/sqrt(size(USubpb2_Old.USubpb2,1));
                try
                    UpdateY2 = norm((USubpb1_Old.USubpb1 - USubpb1_New.USubpb1), 2)/sqrt(size(USubpb1_Old.USubpb1,1));
                catch
                end
            end
            try
                disp(['Update local step  = ',num2str(UpdateY2)]);
                disp(['Update global step = ',num2str(UpdateY)]);
            catch
            end
            fprintf('*********************************** \n \n');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Update dual variables------------------------------
            udual = FSubpb2 - FSubpb1; vdual = USubpb2 - USubpb1;

            save(['uvdual_step',num2str(ALSolveStep)],'udual','vdual');
            try
                if UpdateY < tol2 || UpdateY2 < tol2
                    break
                end
            catch
            end

        end
        fprintf('------------ Section 6 Done ------------ \n \n')
    end

    if useGlobalStep
        % Save data
        ResultDisp{ImgSeqNum-1}.U = full(USubpb2);
        ResultDisp{ImgSeqNum-1}.ALSub1BadPtNum = ALSub1BadPtNum;
        ResultDefGrad{ImgSeqNum-1}.F = full(FSubpb2);
    else
        % Save data
        ResultDisp{ImgSeqNum-1}.U = full(USubpb1);
        ResultDisp{ImgSeqNum-1}.ALSub1BadPtNum = ALSub1BadPtNum;
        ResultDefGrad{ImgSeqNum-1}.F = full(FSubpb1);
    end

end

% ====== Save results ======
save(dicFile, 'file_name', 'DICpara', 'DICmesh', 'ResultDisp', 'ResultDefGrad', ...
    'ResultFEMesh', 'ResultFEMeshEachFrame', 'ALSub1Time', 'ALSub2Time', ...
    'ALSolveStep', '-v7.3');
fprintf('Saved DIC results: %s\n', dicFile);

close all
clear restoreDir  % return to the previous folder before cleaning up
rmdir(workDir, 's');
end
