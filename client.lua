helpers = require('helpers')
http = require('http_client')

-- settings
WIFI_MAX_RETRY = 100
LOOP_TIMER = 2
WIFI_TIMER = 0

data = {}
ip_addr = nil
wifi_attempt = 1 -- Counter of trys to connect to wifi
wifi_connected = false
iteration = 0

sensors = {
    temp = 0,
    pressure = 0
}

function setup()
    bmp085.init(config.sda_pin, config.scl_pin)
end

function loop()
    data['field3'] = node.heap()
    data['field4'] = tmr.time() -- uptime
    -- Read BMP180
    sensors.temp = bmp085.temperature() / 10
    sensors.pressure = helpers.round(bmp085.pressure() * 0.00750061683, 2)

    data['field1'] = sensors.temp
    data['field2'] = sensors.pressure
    print("Data: ", data['field1'], data['field2'], data['field3'], data['field4'])

    -- At this point, data table should be ready to be sent
    if (wifi_connected) then
        http.get(config.ts_address, config.ts_port, config.ts_url, data, function(status, data, message)
            if (data ~= '') then
                print(iteration, status, message)
            else
                print("Empty response!")
            end
        end)
    end
    iteration = iteration+1
--    collectgarbage("collect")
end

-- Change the code of this function that it calls your code.
function wifiConnected()
    print('WiFi connected.')
    print('IP Address: ' .. wifi.sta.getip())
    wifi_connected = true
    -- Re-arm WiFi check
    wifi_attempt = 1 -- reset counter
    tmr.alarm(WIFI_TIMER, 60000, 0, checkWIFI) -- Call checkWIFI in 1min
end

function checkWIFI()
    if (wifi_attempt > WIFI_MAX_RETRY) then
        print('Unable to connect after ' .. WIFI_MAX_RETRY .. ' tries. Reboot.' )
        node.restart()
    else
        ip_addr = wifi.sta.getip()
        if ((ip_addr ~= nil) and (ip_addr ~= '0.0.0.0')) then
            -- Cannot call directly the function from the timer... NodeMcu crashes...
            tmr.alarm(1, 500, 0, wifiConnected)
        else
            wifi_connected = false
            -- Reset alarm again
            tmr.alarm(WIFI_TIMER, 3000, 0, checkWIFI) -- check every 3s
            print('Checking Wifi, attempt ' .. wifi_attempt .. '...')
            wifi_attempt = wifi_attempt + 1
        end
    end
end

print('Starting as a cient')

-- Check if are already connected by getting the IP
ip_addr = wifi.sta.getip()
if ((ip_addr == nil) or (ip_addr == '0.0.0.0')) then
    -- Connect
    wifi.setmode(wifi.STATION)
    wifi.sta.config(config.wifi_ssid, config.wifi_password)
    print('Waiting for WiFi connection...')
    tmr.alarm(WIFI_TIMER, 2500, 0, checkWIFI) -- Call checkWIFI 2.5S in the future.
else
    -- Already connected
    wifiConnected()
end

-- Set globals
data['api_key'] = config.ts_api_key
setup()
-- Call the prog in a loop
print('Start processing sensors, interval (s):' .. config.loop_time)
loop() -- First run
-- Loop run
tmr.alarm(LOOP_TIMER, config.loop_time * 1000, 1, loop)
