function rt = load_rt_data(resultFolder, expectedFrames)
%LOAD_RT_DATA  Primary and secondary bubble radius/center versus frame.
%
%   rt = LOAD_RT_DATA(resultFolder, expectedFrames) reads
%   R_data_primary.mat and R_data_secondary.mat from resultFolder.
%
%   Fields (one row per image; centers are [row, col] = [y, x] in image
%   pixel coordinates, as returned by the circle-fitting tool):
%     primaryR, primaryCenter, secondaryR, secondaryCenter
%
%   Two variable-name conventions exist in the data set (CircleR /
%   CircleCenterSave for the two ZIF-8 10 Mfps recordings, *_primary for
%   the others); both are accepted. The raw (unsmoothed) radius is used.

primaryFile = fullfile(resultFolder, 'R_data_primary.mat');
secondaryFile = fullfile(resultFolder, 'R_data_secondary.mat');
P = load_required(primaryFile);
S = load_required(secondaryFile);

rt.primaryR = pick_field(P, {'CircleR_primary', 'CircleR'}, primaryFile);
rt.primaryCenter = pick_field(P, {'CircleCenterSave_primary', 'CircleCenterSave'}, primaryFile);
rt.secondaryR = pick_field(S, {'CircleR_secondary'}, secondaryFile);
rt.secondaryCenter = pick_field(S, {'CircleCenterSave_secondary'}, secondaryFile);

rt.primaryR = rt.primaryR(:);
rt.secondaryR = rt.secondaryR(:);

if nargin > 1
    lengths = [numel(rt.primaryR), size(rt.primaryCenter, 1), ...
        numel(rt.secondaryR), size(rt.secondaryCenter, 1)];
    if any(lengths < expectedFrames)
        error('load_rt_data:TooShort', ...
            'R-t data in %s cover %s frames, %d needed.', resultFolder, ...
            mat2str(lengths), expectedFrames);
    end
end
end

function S = load_required(file)
if ~isfile(file)
    error('load_rt_data:MissingFile', 'File not found: %s', file);
end
S = load(file);
end

function value = pick_field(S, candidates, file)
for k = 1:numel(candidates)
    if isfield(S, candidates{k})
        value = S.(candidates{k});
        return
    end
end
error('load_rt_data:MissingVariable', 'None of {%s} found in %s', ...
    strjoin(candidates, ', '), file);
end
