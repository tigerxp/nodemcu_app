helpers = require('helpers')
http = require('http_client')

-- settings
WIFI_MAX_RETRY = 100
TEMP_DISABLE = 55
TEMP_ENABLE = 60
LOOP_TIMER = 2
WIFI_TIMER = 0

PUMP_ON = gpio.LOW
PUMP_OFF = gpio.HIGH

data = {}
ip_addr = nil
wifi_attempt = 1 -- Counter of trys to connect to wifi
wifi_connected = false
iteration = 0

sensors = {
    temp = 0,
    pump = PUMP_ON
}

function setup()
    sensors.ds = require('ds18b20')
    sensors.ds.setup(config.ds_pin)
    sensors.ds_addrs = sensors.ds.addrs()
    gpio.mode(config.relay_pin, gpio.OUTPUT)
end

function loop()
    -- Read DS1820
    if (sensors.ds_addrs[1] ~= nil) then
        sensors.temp1 = sensors.ds.read(sensors.ds_addrs[1]);
    else
        sensors.temp1 = 0
    end
    if (sensors.ds_addrs[2] ~= nil) then
        sensors.temp2 = sensors.ds.read(sensors.ds_addrs[2]);
    else
        sensors.temp2 = 0
    end

    -- Read DHT
    local status, temp, humi, temp_dec, humi_dec = dht.read(config.dht_pin)
    sensors.dht_temp = 0
    sensors.dht_humi = 0
    if status == dht.OK then
        print("DHT Temperature:"..temp..";".."Humidity:"..humi)
        sensors.dht_temp = temp
        sensors.dht_humi = humi
    elseif status == dht.ERROR_CHECKSUM then
        print( "DHT Checksum error." )
    elseif status == dht.ERROR_TIMEOUT then
        print( "DHT timed out." )
    end

    -- Update relay
    if (sensors.temp2 < TEMP_DISABLE) then
        sensors.pump = PUMP_OFF
    end
    if (sensors.temp2 >= TEMP_ENABLE) then
        sensors.pump = PUMP_ON
    end
    gpio.write(config.relay_pin, sensors.pump)

    data['field1'] = sensors.temp1
    data['field2'] = sensors.temp2
    data['field3'] = sensors.pump == PUMP_ON and 1 or 0
    data['field4'] = sensors.dht_temp
    data['field5'] = sensors.dht_humi
    data['field6'] = node.heap()
    data['field7'] = tmr.time() -- uptime

    print("Data: ", data['field1'], data['field2'], data['field3'], data['field4'], data['field5'], data['field6'], data['field7'])

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
