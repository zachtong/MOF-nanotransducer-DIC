function run_all_postprocessing(varargin)
%RUN_ALL_POSTPROCESSING  Post-processing of every recording (~1 h per recording).
%
%   RUN_ALL_POSTPROCESSING() runs run_postprocessing_case for all 14
%   recordings on the archived DIC results of the paper (before_sec8.mat)
%   and writes <outputRoot>/processed/<id>_postprocessing.mat.
%
%   Name-value options are passed on to run_postprocessing_case, e.g.
%     RUN_ALL_POSTPROCESSING('dic', 'rerun')        use your own DIC results
%     RUN_ALL_POSTPROCESSING('saveFigures', true)   also write the von Mises
%         maps (every 5th frame, 300-dpi JPG; Fig. 2C, Fig. S9, Movie S2)
%   and one more option
%     'cases'   cell array of recording IDs (default: all)
%
%   Afterwards: compare_rerun_with_archive, make_kymograph_figures('rerun').

ip = inputParser;
ip.KeepUnmatched = true;
addParameter(ip, 'cases', {}, @(x) iscell(x) || ischar(x) || isstring(x) || isnumeric(x));
parse(ip, varargin{:});
passOn = namevalue_to_cell(ip.Unmatched);

setup_paths(false);   % post-processing needs no MEX
cases = select_cases(ip.Results.cases);
failed = {};
for k = 1:numel(cases)
    try
        run_postprocessing_case(cases(k).id, passOn{:});
    catch err
        failed{end + 1} = cases(k).id; %#ok<AGROW>
        warning('run_all_postprocessing:CaseFailed', 'Case %s failed: %s', ...
            cases(k).id, err.message);
    end
end
report_failures(failed, numel(cases));
end

function c = namevalue_to_cell(s)
names = fieldnames(s);
c = cell(1, 2 * numel(names));
for i = 1:numel(names)
    c{2 * i - 1} = names{i};
    c{2 * i} = s.(names{i});
end
end

function report_failures(failed, nCases)
if isempty(failed)
    fprintf('All %d recordings processed.\n', nCases);
else
    fprintf('%d of %d recordings failed: %s\n', numel(failed), nCases, strjoin(failed, ', '));
end
end
