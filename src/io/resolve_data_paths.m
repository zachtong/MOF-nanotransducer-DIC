function paths = resolve_data_paths()
%RESOLVE_DATA_PATHS  Data and output folders of the analysis.
%
%   paths = RESOLVE_DATA_PATHS() returns a struct with absolute paths
%     dataRoot    the unzipped data set (default: <repository>/data)
%     outputRoot  new results and figures (default: <repository>/output)
%   Other folders can be set with set_data_paths (main.m does this).

APPDATA_KEY = 'MOFNanotransducerDIC_paths';   % same key as in set_data_paths
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
paths = struct('dataRoot', fullfile(repoRoot, 'data'), ...
    'outputRoot', fullfile(repoRoot, 'output'));

custom = getappdata(groot, APPDATA_KEY);
if isstruct(custom)
    if ~isempty(custom.dataRoot)
        paths.dataRoot = custom.dataRoot;
    end
    if ~isempty(custom.outputRoot)
        paths.outputRoot = custom.outputRoot;
    end
end
paths.dataRoot = make_absolute(paths.dataRoot);
paths.outputRoot = make_absolute(paths.outputRoot);

if ~isfolder(paths.dataRoot)
    error('resolve_data_paths:MissingData', ['Data folder not found: %s\n', ...
        'Unzip the data set into this folder (see docs/reproduce.md) or set ', ...
        'dataRoot in main.m.'], paths.dataRoot);
end
end
