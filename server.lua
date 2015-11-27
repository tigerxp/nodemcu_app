-- config = require('config')
require('helpers')

local function http_listener(conn, data)
    local query_data

    conn:on("receive",
        function(cn, req_data)
            query_data = parse_http_req(req_data)
            print(query_data)
            -- print(query_data["METHOD"] .. " " .. " " .. query_data["User-Agent"])
            wifi.sta.getap(1, function(list)
                cn:send("[")
                for bssid, v in pairs(list) do
                    local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
                    cn:send('{"ssid": "' .. ssid .. '", "bssid": "' .. bssid .. '", "rssi": ' .. rssi .. ', "authmode": ' .. authmode .. ', "channel": ' .. channel .. '}' .. (next(list, bssid) ~= nil and ', ' or ''))
                end
                cn:send("]")
                cn:close()
            end)
        end)
end

function wait_for_wifi_conn()
    tmr.alarm(1, 1000, 1, function()
        if wifi.sta.getip() == nil then
            print("Waiting for Wifi connection")
        else
            tmr.stop(1)
            print("ESP8266 mode is: " .. wifi.getmode())
            print("The module MAC address is: " .. wifi.ap.getmac())
            print("Config done, IP is " .. wifi.sta.getip())
        end
    end)
end

print('Here is a server')

---- Configure the ESP as a station (client)
--wifi.setmode(wifi.STATION)
--wifi.sta.config(config.wifi_ssid, config.wifi_password)
--wifi.sta.autoconnect(1)
--
---- Hang out until we get a wifi connection before the httpd server is started.
--wait_for_wifi_conn()
--
---- Create the httpd server
--svr = net.createServer(net.TCP, 30)
--
---- Server listening on port 80, call connect function if a request is received
--svr:listen(80, http_listener)
