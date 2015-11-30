helpers = require('helpers')
http = require('http_client')

-- settings
WIFI_MAX_RETRY = 100
TEMP_DISABLE = 55
TEMP_ENABLE = 60

PUMP_ON = gpio.LOW
PUMP_OFF = gpio.HIGH

data = {}
ip_addr = nil
wifi_attempt = 1 -- Counter of trys to connect to wifi
iteration = 0

sensors = {
    temp = 0,
    pump = PUMP_ON
}

function setup()
    sensors.ds = require('ds18b20')
    sensors.ds.setup(config.ds_pin)
    gpio.mode(config.pump_pin, gpio.OUTPUT)
end

function loop()
    data['field1'] = node.heap()
    data['field2'] = tmr.time() -- uptime
    -- TODO: replace with real reading
    -- sensors.temp = helpers.round(math.random(40*100, 70*100)/100, 2)
    sensors.temp = sensors.ds.read();
    print('DS temperature: ', sensors.temp)
    if (sensors.temp < TEMP_DISABLE) then
        sensors.pump = PUMP_OFF
    end
    if (sensors.temp >= TEMP_ENABLE) then
        sensors.pump = PUMP_ON
    end
    gpio.write(config.pump_pin, sensors.pump)
    data['field3'] = sensors.temp
    data['field4'] = sensors.pump == PUMP_ON and 1 or 0
    print("Data: ", data['field1'], data['field2'], data['field3'], data['field4'])

    -- At this point, data table should be ready to be sent
    http.get(config.ts_address, config.ts_port, config.ts_url, data, function(status, data, message)
        if (data ~= '') then
            print(iteration, status, message)
        else
            print("Empty response!")
        end
    end)
    iteration = iteration+1
--    collectgarbage("collect")
end

-- Change the code of this function that it calls your code.
function launch()
    print('Connected to WIFI!')
    print('IP Address: ' .. wifi.sta.getip())
    -- Call setup
    setup()
    -- Set globals
    data['api_key'] = config.ts_api_key
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

print('Starting as a cient')

-- Check if are already connected by getting the IP
ip_addr = wifi.sta.getip()
if ((ip_addr == nil) or (ip_addr == '0.0.0.0')) then
    -- Connect
    wifi.setmode(wifi.STATION)
    wifi.sta.config(config.wifi_ssid, config.wifi_password)
    print('Waiting for WiFi connection...')
    tmr.alarm(0, 2500, 0, checkWIFI) -- Call checkWIFI 2.5S in the future.
else
    -- Connected, launch the code
    launch()
end
