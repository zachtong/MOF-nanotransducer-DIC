function paths = resolve_data_paths()
%RESOLVE_DATA_PATHS  Read local data locations from config/data_paths.m.
%
%   paths = RESOLVE_DATA_PATHS() returns struct with fields dataRoot and
%   outputRoot, both as absolute paths (relative entries are resolved
%   against the current folder). Create config/data_paths.m from
%   config/data_paths_template.m first.

if exist('data_paths', 'file') ~= 2
    error('resolve_data_paths:MissingConfig', ['config/data_paths.m not found. ', ...
        'Copy config/data_paths_template.m to config/data_paths.m, rename the ', ...
        'function to data_paths and set dataRoot / outputRoot.']);
end
paths = data_paths();
if ~isfield(paths, 'dataRoot') || ~isfolder(paths.dataRoot)
    error('resolve_data_paths:BadDataRoot', ...
        'paths.dataRoot does not exist: %s', string(paths.dataRoot));
end
if ~isfield(paths, 'outputRoot') || isempty(paths.outputRoot)
    error('resolve_data_paths:BadOutputRoot', 'paths.outputRoot must be set.');
end
paths.dataRoot = make_absolute(paths.dataRoot);
paths.outputRoot = make_absolute(paths.outputRoot);
end
