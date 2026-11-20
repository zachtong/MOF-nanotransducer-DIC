function f = case_files(caseInfo, paths)
%CASE_FILES  Input and output file locations of one recording.
%
%   f = CASE_FILES(caseInfo, paths) returns, for a case from case_table
%   and the paths from resolve_data_paths, a struct with
%
%   Inputs (data set, below paths.dataRoot)
%     archivedDic        <resultDir>/before_sec8.mat  DIC result of the paper
%     archivedWorkspace  <resultDir>/before_sec9.mat  workspace after post-processing
%   Outputs (below paths.outputRoot)
%     rerunDic           dic/<id>_dic_results.mat              run_dic_case
%     rerunProcessed     processed/<id>_postprocessing.mat     run_postprocessing_case
%     vonMisesMaps       figures/vonmises_maps/<id>/           full-field maps (JPG)

resultFolder = fullfile(paths.dataRoot, caseInfo.resultDir);
f.archivedDic = fullfile(resultFolder, 'before_sec8.mat');
f.archivedWorkspace = fullfile(resultFolder, 'before_sec9.mat');

f.rerunDic = fullfile(paths.outputRoot, 'dic', [caseInfo.id '_dic_results.mat']);
f.rerunProcessed = fullfile(paths.outputRoot, 'processed', [caseInfo.id '_postprocessing.mat']);
f.vonMisesMaps = fullfile(paths.outputRoot, 'figures', 'vonmises_maps', caseInfo.id);
end
