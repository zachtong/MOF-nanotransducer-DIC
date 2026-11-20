function previous = set_data_paths(dataRoot, outputRoot)
%SET_DATA_PATHS  Use other data / output folders for this MATLAB session.
%
%   SET_DATA_PATHS(dataRoot, outputRoot) makes resolve_data_paths return
%   these folders instead of the defaults <repository>/data and
%   <repository>/output. An empty argument keeps that default.
%   SET_DATA_PATHS() restores both defaults. main.m calls this function
%   with the folders set at its top.
%
%   previous = SET_DATA_PATHS(...) also returns the setting before the
%   call ([] if none); SET_DATA_PATHS(previous) restores it.

APPDATA_KEY = 'MOFNanotransducerDIC_paths';   % same key as in resolve_data_paths
previous = [];
if isappdata(groot, APPDATA_KEY)
    previous = getappdata(groot, APPDATA_KEY);
    rmappdata(groot, APPDATA_KEY);
end
if nargin == 0
    return
end
if nargin == 1 && (isstruct(dataRoot) || (isnumeric(dataRoot) && isempty(dataRoot)))
    if isstruct(dataRoot)     % restore a setting returned earlier
        setappdata(groot, APPDATA_KEY, dataRoot);
    end
    return
end
if nargin < 2
    outputRoot = '';
end
setappdata(groot, APPDATA_KEY, struct('dataRoot', char(dataRoot), ...
    'outputRoot', char(outputRoot)));
end
