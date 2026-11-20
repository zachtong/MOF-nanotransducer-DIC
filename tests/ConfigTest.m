classdef ConfigTest < matlab.unittest.TestCase
    %CONFIGTEST  Case table, parameters and manual secondary tracks.

    methods (Test)
        function caseTableHasFourteenUniqueCases(tc)
            cases = case_table();
            tc.verifyNumElements(cases, 14);
            tc.verifyNumElements(unique({cases.id}), 14);
            tc.verifyTrue(all(ismember([cases.fpsMHz], [1, 10])));
        end

        function getCaseAcceptsNumericAndText(tc)
            tc.verifyEqual(get_case(181404).folder, 'Jin_18_14_04');
            tc.verifyEqual(get_case('171925').material, 'ZIF-8');
            tc.verifyError(@() get_case('000000'), 'get_case:UnknownCase');
        end

        function defaultsMatchArchivedAnalysis(tc)
            p = default_params();
            tc.verifyEqual([p.dic.winsize, p.dic.winstepsize, p.dic.winsizeMin], [20, 8, 2]);
            tc.verifyEqual(p.post.strainHalfWindow, 40);
            tc.verifyEqual(p.kymo.frameCut, 4);
        end

        function selectCasesKeepsOrderAndDefaultsToAll(tc)
            tc.verifyNumElements(select_cases(), 14);
            tc.verifyNumElements(select_cases({}), 14);
            picked = select_cases({'181404', '171925'});
            tc.verifyEqual({picked.id}, {'181404', '171925'});
            tc.verifyEqual(select_cases(181404).id, '181404');
            tc.verifyEqual(select_cases('172655').id, '172655');
            tc.verifyError(@() select_cases({'000000'}), 'get_case:UnknownCase');
        end

        function caseFilesFollowDocumentedLayout(tc)
            paths = struct('dataRoot', fullfile('D', 'data'), 'outputRoot', fullfile('D', 'out'));
            f = case_files(get_case('181404'), paths);
            resultDir = fullfile('D', 'data', 'ZIF-8', 'Jin_18_14_04_DIC_results');
            tc.verifyEqual(f.archivedDic, fullfile(resultDir, 'before_sec8.mat'));
            tc.verifyEqual(f.archivedWorkspace, fullfile(resultDir, 'before_sec9.mat'));
            tc.verifyEqual(f.datasetProcessed, ...
                fullfile('D', 'data', 'processed', '181404_postprocessing.mat'));
            tc.verifyEqual(f.rerunDic, fullfile('D', 'out', 'dic', '181404_dic_results.mat'));
            tc.verifyEqual(f.rerunProcessed, ...
                fullfile('D', 'out', 'processed', '181404_postprocessing.mat'));
            tc.verifyEqual(f.vonMisesMaps, fullfile('D', 'out', 'figures', 'vonmises_maps', '181404'));
        end

        function dataPathsDefaultAndOverride(tc)
            % Clear the session setting (e.g. from main.m) and restore it afterwards.
            previous = set_data_paths();
            tc.addTeardown(@() set_data_paths(previous));
            p = resolve_data_paths();
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            tc.verifyEqual(p.dataRoot, fullfile(repoRoot, 'data'));
            tc.verifyEqual(p.outputRoot, fullfile(repoRoot, 'output'));
            other = tempname;
            mkdir(other);
            tc.addTeardown(@() rmdir(other, 's'));
            set_data_paths(other, fullfile(other, 'out'));
            p = resolve_data_paths();
            tc.verifyEqual(p.dataRoot, other);
            tc.verifyEqual(p.outputRoot, fullfile(other, 'out'));
            set_data_paths(fullfile(other, 'missing'));
            tc.verifyError(@() resolve_data_paths(), 'resolve_data_paths:MissingData');
        end

        function maxAbsDiffTreatsNaNExplicitly(tc)
            tc.verifyEqual(max_abs_diff([1 NaN 3], [1.5 NaN 3]), 0.5);
            tc.verifyEqual(max_abs_diff([1 NaN], [1 2]), Inf);
            tc.verifyEqual(max_abs_diff([1 2], [1 2 3]), Inf);
            tc.verifyEqual(max_abs_diff([], []), 0);
            tc.verifyEqual(max_abs_diff([NaN NaN], [NaN NaN]), 0);
        end

        function manualTracksHaveExpectedLength(tc)
            ids = {'162005', '163902', '162445', '164311'};
            lens = [234, 234, 253, 252];
            for k = 1:numel(ids)
                t = manual_secondary_tracks(ids{k});
                tc.verifySize(t.center, [lens(k), 2]);
                tc.verifySize(t.R, [lens(k), 1]);
            end
            tc.verifyError(@() manual_secondary_tracks('181404'), ...
                'manual_secondary_tracks:NotManual');
        end

        function manualTrackHitsControlPoints(tc)
            t = manual_secondary_tracks('162445');
            tc.verifyEqual(t.center([1, 28, 65, 92, 112, 253], :), ...
                [156 348; 161 358; 155 347; 156 350; 154 347; 156 347], 'AbsTol', 1e-12);
        end
    end
end
