function d = max_abs_diff(a, b)
%MAX_ABS_DIFF  Largest absolute difference of two arrays, NaN-aware.
%
%   d = MAX_ABS_DIFF(a, b) returns max(|a - b|) over all elements.
%   Positions where both are NaN count as equal. A NaN on one side only,
%   or a size mismatch, gives Inf. Two empty arrays give 0.

if ~isequal(size(a), size(b))
    d = Inf;
    return
end
nanA = isnan(a);
nanB = isnan(b);
if any(xor(nanA(:), nanB(:)))
    d = Inf;
    return
end
both = ~(nanA | nanB);
diffs = abs(a(both) - b(both));
if isempty(diffs)
    d = 0;
else
    d = max(diffs(:));
end
end
