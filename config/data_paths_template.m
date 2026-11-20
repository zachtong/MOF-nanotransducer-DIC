function paths = data_paths_template()
%DATA_PATHS_TEMPLATE  Template for local data locations.
%
%   Copy this file to config/data_paths.m, rename the function to
%   DATA_PATHS, and edit the two folders below. config/data_paths.m is
%   ignored by git so that personal paths never end up in the repository.
%
%   dataRoot   folder that contains the per-material folders of the
%              Zenodo data set, e.g. <dataRoot>/ZIF-8/Jin_18_14_04/
%   outputRoot folder where new results and figures are written

paths.dataRoot = fullfile('path', 'to', 'MOF-nanotransducer-DIC-data');
paths.outputRoot = fullfile('path', 'to', 'MOF-nanotransducer-DIC-output');
end
