function p = make_absolute(p)
%MAKE_ABSOLUTE  Resolve a relative path against the current folder.
%
%   p = MAKE_ABSOLUTE(p) returns p unchanged if it is already absolute
%   (Unix "/...", Windows "C:\..." or UNC "\\server\..."), otherwise
%   fullfile(pwd, p). Needed because some steps change the current folder.

p = char(p);
isAbsolute = startsWith(p, '/') || startsWith(p, '\\') || ...
    ~isempty(regexp(p, '^[A-Za-z]:[\\/]', 'once'));
if ~isAbsolute
    p = fullfile(pwd, p);
end
end
