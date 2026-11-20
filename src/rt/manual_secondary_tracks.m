function track = manual_secondary_tracks(caseId)
%MANUAL_SECONDARY_TRACKS  Manually defined secondary-bubble tracks.
%
%   track = MANUAL_SECONDARY_TRACKS(caseId) returns struct with fields
%     center  N x 2 [row, col] image coordinates per frame
%     R       N x 1 radius (px)
%
%   In four solvent-filled (no gas) recordings no secondary bubble is
%   visible, so the circle fit cannot track the particle cluster. Its
%   position was defined by hand (piecewise-linear in time) and its radius
%   fixed.
%

switch char(caseId)
    case '162005'  % NU-1003, no gas, 10 Mfps
        track = linear_track([174, 325], [183, 335], 233, 234, 8);
    case '163902'  % ZIF-67, no gas, 10 Mfps
        track = linear_track([171, 350], [179, 360], 233, 234, 8);
    case '162445'  % NU-1003, no gas, 1 Mfps
        controlPoints = [156 348; 161 358; 155 347; 156 350; 154 347; 156 347];
        breakFrames = [1, 28, 65, 92, 112, 253];
        track = piecewise_track(controlPoints, breakFrames, 9);
    case '164311'  % ZIF-67, no gas, 1 Mfps
        controlPoints = [222 233; 232 238; 234 222; 226 236; 223 234; 223 232];
        breakFrames = [1, 30, 60, 90, 114, 252];
        track = piecewise_track(controlPoints, breakFrames, 12);
    otherwise
        error('manual_secondary_tracks:NotManual', ...
            'Case %s uses the detected secondary-bubble track.', char(caseId));
end
end

function track = linear_track(firstPoint, lastPoint, nSteps, nFrames, radius)
% Uniform motion from firstPoint; the step is (lastPoint - firstPoint) / nSteps.
step = (lastPoint - firstPoint) / nSteps;
k = (0:nFrames - 1)';
track.center = firstPoint + k * step;
track.R = radius * ones(nFrames, 1);
end

function track = piecewise_track(controlPoints, breakFrames, radius)
% Linear interpolation between control points placed at breakFrames.
nFrames = breakFrames(end);
center = zeros(nFrames, 2);
for s = 1:numel(breakFrames) - 1
    f0 = breakFrames(s);
    f1 = breakFrames(s + 1);
    t = linspace(0, 1, f1 - f0 + 1)';
    center(f0:f1, :) = controlPoints(s, :) + t .* (controlPoints(s + 1, :) - controlPoints(s, :));
end
track.center = center;
track.R = radius * ones(nFrames, 1);
end
