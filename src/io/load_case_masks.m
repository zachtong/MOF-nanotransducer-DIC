function [mask_file_name, ImgMask] = load_case_masks(maskFolder, expectedCount)
%LOAD_CASE_MASKS  Non-interactive replacement of STAQ-DIC ReadImageMasks.
%
%   [mask_file_name, ImgMask] = LOAD_CASE_MASKS(maskFolder, expectedCount)
%
%   Reads every mask image of maskFolder (sorted by name) as a logical
%   array transposed to the STAQ-DIC convention. The number of masks must
%   equal the number of DIC images (expectedCount).

mask_file_name = list_image_files(maskFolder);
numMasks = size(mask_file_name, 2);
if nargin > 1 && numMasks ~= expectedCount
    error('load_case_masks:CountMismatch', ...
        '%d masks in %s but %d images.', numMasks, maskFolder, expectedCount);
end

ImgMask = cell(1, numMasks);
for i = 1:numMasks
    mask = imread(fullfile(mask_file_name{2, i}, mask_file_name{1, i}));
    if size(mask, 3) == 3
        mask = rgb2gray(mask);
    end
    ImgMask{i} = logical(mask)';
end
end
