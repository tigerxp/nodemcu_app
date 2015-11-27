-- Register module by require name
local moduleName = ...
local M = {}
_G[moduleName] = M


-- String trim left and right
function M.trim(s)
    return (type(s) == 'string') and (s:gsub('^%s*(.-)%s*$', '%1')) or ''
end

function M.round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function M.dump_table(t)
    for k, v in pairs(t) do
        print(k .. ': ' .. v)
    end
end

return M
