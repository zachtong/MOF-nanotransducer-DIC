function run_all_dic(caseIds)
%RUN_ALL_DIC  Incremental STAQ-DIC of every recording (several hours per recording).
%
%   RUN_ALL_DIC() runs run_dic_case for all 14 recordings;
%   RUN_ALL_DIC({'181404', '171925'}) for selected ones.
%   Results: <outputRoot>/dic/<id>_dic_results.mat.
%   Needs the MEX files (setup_paths compiles them; "mex -setup C++" once).
%
%   Afterwards: compare_dic_with_archive, then
%   run_all_postprocessing('dic', 'rerun').

if nargin < 1
    caseIds = {};
end
setup_paths();
cases = select_cases(caseIds);
failed = {};
for k = 1:numel(cases)
    try
        run_dic_case(cases(k).id);
    catch err
        failed{end + 1} = cases(k).id; %#ok<AGROW>
        warning('run_all_dic:CaseFailed', 'Case %s failed: %s', cases(k).id, err.message);
    end
end
if isempty(failed)
    fprintf('DIC finished for all %d recordings.\n', numel(cases));
else
    fprintf('%d of %d recordings failed: %s\n', numel(failed), numel(cases), strjoin(failed, ', '));
end
end
