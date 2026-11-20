function file_name = list_image_files(folder)
%LIST_IMAGE_FILES  Image files of a folder in STAQ-DIC "file_name" layout.
%
%   file_name = LIST_IMAGE_FILES(folder) returns the 6 x N cell array
%   struct2cell(dir(...)) used by STAQ-DIC (row 1: name, row 2: folder,
%   ...). Extensions and their order follow ReadImageQuadtree (option 0,
%   "select images folder"); names are sorted within each extension
%   (zero-padded frame numbers, so this is the frame order). Hidden files
%   such as macOS "._*" resource forks are ignored.

if ~isfolder(folder)
    error('list_image_files:MissingFolder', 'Image folder not found: %s', folder);
end
extensions = {'*.jpg', '*.jpeg', '*.tif', '*.tiff', '*.bmp', '*.png', '*.jp2'};
listing = [];
for k = 1:numel(extensions)
    found = dir(fullfile(folder, extensions{k}));
    found = found(~startsWith({found.name}, '.'));
    [~, order] = sort({found.name});
    listing = [listing; found(order)]; %#ok<AGROW>
end
if isempty(listing)
    error('list_image_files:NoImages', 'No image files found in %s', folder);
end
% On some Windows volumes '*.tif' also matches '*.tiff' (8.3 short names);
% keep the first occurrence of each file.
[~, firstIdx] = unique({listing.name}, 'stable');
listing = listing(sort(firstIdx));
file_name = struct2cell(listing);
end
