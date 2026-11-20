function c = get_case(caseId)
%GET_CASE  Return the case_table() entry for a recording ID.
%
%   c = GET_CASE('181404') or GET_CASE(181404)

if isnumeric(caseId)
    caseId = sprintf('%06d', caseId);
end
if ~(ischar(caseId) || isstring(caseId))
    error('get_case:BadInput', 'caseId must be a six-digit ID, e.g. ''181404''.');
end
caseId = char(caseId);

cases = case_table();
idx = find(strcmp({cases.id}, caseId), 1);
if isempty(idx)
    error('get_case:UnknownCase', ...
        'Unknown case ID "%s". Valid IDs: %s', caseId, strjoin({cases.id}, ', '));
end
c = cases(idx);
end
