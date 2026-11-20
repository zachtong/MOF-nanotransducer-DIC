function setup_paths(compileMex)
%SETUP_PATHS  Add the repository to the MATLAB path and build the MEX files.
%
%   SETUP_PATHS() adds config/, src/ and the vendored STAQ-DIC library to
%   the path and compiles ba_interp2.cpp / ba_interp2_spline.cpp when no
%   MEX binary exists for this platform. A C++ compiler must be configured
%   once with "mex -setup C++".
%
%   SETUP_PATHS(false) skips MEX compilation (enough for the figure
%   scripts and the unit tests).

if nargin < 1
    compileMex = true;
end

root = fileparts(mfilename('fullpath'));
staq = fullfile(root, 'third_party', 'STAQ-DIC');

addpath(root);   % keeps setup_paths / run_tests callable from any folder
addpath(fullfile(root, 'config'));
addpath(genpath(fullfile(root, 'src')));
addpath(fullfile(root, 'scripts'));
% Only the folders that the original analysis put on the path (in
% particular func/rbfinterp, not a second copy elsewhere).
addpath(staq, fullfile(staq, 'func'), fullfile(staq, 'func', 'rbfinterp'), ...
    fullfile(staq, 'func_quadtree'), fullfile(staq, 'func_quadtree', 'refinement'), ...
    fullfile(staq, 'plotFiles'));

if compileMex
    build_mex(staq, 'ba_interp2');
    build_mex(staq, 'ba_interp2_spline');
end
end

function build_mex(folder, name)
if isfile(fullfile(folder, [name '.' mexext]))
    return
end
fprintf('Compiling %s.cpp ...\n', name);
try
    mex('-O', fullfile(folder, [name '.cpp']), '-outdir', folder);
catch err
    error('setup_paths:Mex', ['Could not compile %s.cpp (%s). Configure a C++ ', ...
        'compiler with "mex -setup C++" and run setup_paths again.'], name, err.message);
end
end
