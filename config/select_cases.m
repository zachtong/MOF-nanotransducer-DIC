function cases = select_cases(caseIds)
%SELECT_CASES  Subset of case_table by recording ID.
%
%   cases = SELECT_CASES() or SELECT_CASES({}) returns all 14 recordings.
%   cases = SELECT_CASES({'181404', '171925'}) or SELECT_CASES(181404)
%   returns the listed ones, in the order given. Unknown IDs raise an error.

if nargin < 1 || isempty(caseIds)
    cases = case_table();
    return
end
if isnumeric(caseIds)
    caseIds = arrayfun(@(x) sprintf('%06d', x), caseIds, 'UniformOutput', false);
end
caseIds = cellstr(string(caseIds));
cases = repmat(get_case(caseIds{1}), numel(caseIds), 1);
for k = 2:numel(caseIds)
    cases(k) = get_case(caseIds{k});
end
end
