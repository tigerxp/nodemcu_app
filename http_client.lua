local moduleName = ...
local M = {}
_G[moduleName] = M

function M.get(host, port, url, data, callback)
    local conn = net.createConnection(net.TCP, false)
    local headers
    local buffer = ''
    local query = M.urlencode_table(data)
    if (query ~= '') then
        query = (url:find('?') == nil and '?' or '&') .. query
    end

    conn:on('receive', function(conn, payload)
        buffer = buffer .. payload
    end)

    conn:on('disconnection', function(c)
        c:close()
        conn = nil
        -- cut the headers
        local headers_end = string.find(buffer, "\r\n\r\n")
        local status, message
        if (headers_end) then
            headers = string.sub(buffer, 0, headers_end)
            status, message = string.match(headers, 'Status: (%d+)%s+([^\n\r]*)')
            buffer = string.sub(buffer, headers_end + 4)
            callback(status, buffer, message, headers)
        else
            callback(nil, nil, nil, nil)
        end
    end)

    conn:on('connection', function(c)
        local req = 'GET ' .. url .. query .. ' HTTP/1.1\r\n' ..
                'Host: ' .. host .. "\r\n" ..
                'Connection: close\r\n' ..
                'Accept: */*\r\n\r\n'
        c:send(req)
    end)

    conn:connect(port, host)
end

function M.urlencode_str(str)
    if (str) then
        str = string.gsub(str, '\n', '\r\n')
        str = string.gsub(str, '([^%w %-%_%.%~])',
            function(c)
                return string.format('%%%02X', string.byte(c))
            end)
        str = string.gsub(str, ' ', '+')
    end
    return str
end

function M.urlencode_table(t)
    local res = ''
    for k, v in pairs(t) do
        res = res .. M.urlencode_str(k) .. '=' .. M.urlencode_str(v) .. (next(t, k) ~= nil and '&' or '')
    end
    return res
end

return M
