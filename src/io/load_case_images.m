function [file_name, Img, DICpara] = load_case_images(imageFolder, dicParams)
%LOAD_CASE_IMAGES  Non-interactive replacement of STAQ-DIC ReadImageQuadtree.
%
%   [file_name, Img, DICpara] = LOAD_CASE_IMAGES(imageFolder, dicParams)
%
%   Reads every image of imageFolder (sorted by name), converts it to a
%   grayscale double array and transposes it to the STAQ-DIC convention
%   (first index = x). DICpara is filled with the values that were entered
%   interactively in the original analysis (config/default_params.m, .dic).

file_name = list_image_files(imageFolder);
numImages = size(file_name, 2);

Img = cell(1, numImages);
for i = 1:numImages
    img = imread(fullfile(file_name{2, i}, file_name{1, i}));
    if size(img, 3) == 3
        img = rgb2gray(img);
    elseif size(img, 3) == 4
        img = rgb2gray(img(:, :, 1:3));
    end
    Img{i} = double(img)';
end

imgInfo = imfinfo(fullfile(file_name{2, 1}, file_name{1, 1}));
DICpara.imgBitDepth = imgInfo(1).BitDepth;

if dicParams.useFullImageROI
    DICpara.gridxyROIRange.gridx = [1, size(Img{1}, 1)];
    DICpara.gridxyROIRange.gridy = [1, size(Img{1}, 2)];
else
    error('load_case_images:ROI', 'Only the full-image ROI used in the analysis is supported.');
end

DICpara.winsize = dicParams.winsize;
DICpara.winstepsize = dicParams.winstepsize;
DICpara.LoadImgMethod = dicParams.LoadImgMethod;
DICpara.ImgSeqIncUnit = dicParams.ImgSeqIncUnit;
DICpara.ImgSeqIncROIUpdateOrNot = dicParams.ImgSeqIncROIUpdateOrNot;
DICpara.Subpb2FDOrFEM = dicParams.Subpb2FDOrFEM;
DICpara.NewFFTSearch = dicParams.NewFFTSearch;
DICpara.ClusterNo = dicParams.ClusterNo;
DICpara.ImgSize = size(Img{1});
DICpara.winsizeMin = dicParams.winsizeMin;
end
