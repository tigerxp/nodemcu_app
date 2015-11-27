config = require('config')
helpers = require('helpers')
http = require('http_client')

-- settings
WIFI_MAX_RETRY = 100

data = {}
ip_addr = nil
wifi_attempt = 1 -- Counter of trys to connect to wifi
iteration = 0

sensors = {
}

function setup()
--    sensors.ds = require('ds18b20')
--    sensors.ds.setup(config.ds_pin)
end

function loop()
    data['field1'] = node.heap()
    data['field2'] = tmr.time() -- uptime
    data['field3'] = helpers.round(math.random(60*100, 90*100)/100, 2)
    data['field4'] = math.random(0, 1)
    print("Data: ", data['field1'], data['field2'], data['field3'], data['field4'])

    -- At this point, data table should be ready to be sent
    http.get(config.ts_address, config.oprog_port, config.report_url, data, function(status, data, message)
        if (data ~= '') then
            print(iteration, status, message)
            if (type(data) == 'string') then
                print('data size: ', string.len(data))
            else
                print('data: nil')
            end
        else
            print("Empty response!")
        end
    end)
    iteration = iteration+1
end

-- Change the code of this function that it calls your code.
function launch()
    print('Connected to WIFI!')
    print('IP Address: ' .. wifi.sta.getip())
    -- Set globals
    data['node'] = node_name
    data['api_key'] = config.api_key
    -- Call the prog in a loop
    print('Start sending data, interval (s):' .. config.loop_time)
    -- First run
    loop()
    -- Loop run
    tmr.alarm(0, config.loop_time * 1000, 1, loop)
end

function checkWIFI()
    if (wifi_attempt > WIFI_MAX_RETRY) then
        print('Unable to connect after ' .. WIFI_MAX_RETRY .. ' tries.' )
    else
        ip_addr = wifi.sta.getip()
        if ((ip_addr ~= nil) and (ip_addr ~= '0.0.0.0')) then
            -- lauch()        -- Cannot call directly the function from the timer... NodeMcu crashes...
            tmr.alarm(1, 500, 0, launch)
        else
            -- Reset alarm again
            tmr.alarm(0, 3000, 0, checkWIFI)
            print('Checking Wifi, attempt ' .. wifi_attempt .. '...')
            wifi_attempt = wifi_attempt + 1
        end
    end
end

print('Here is a client!')

-- Lets see if we are already connected by getting the IP
--ipAddr = wifi.sta.getip()
--if ((ipAddr == nil) or (ipAddr == '0.0.0.0')) then
--    -- We aren't connected, so let's connect
--    wifi.setmode(wifi.STATION)
--    wifi.sta.config(config.wifi_ssid, config.wifi_password)
--    print('Waiting for WiFi connection...')
--    tmr.alarm(0, 2500, 0, checkWIFI) -- Call checkWIFI 2.5S in the future.
--else
--    -- We are connected, so just run the launch code.
--    launch()
--end
