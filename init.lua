-- Globals

-- Default config
config = {
    wifi_ssid = 'open',
    wifi_password = '',
    ts_address = '144.212.80.11', -- api.thingspeak.com
    ts_api_key = '',
    loop_time = 30 -- seconds
}
node_name = 'node_' .. node.chipid()

function file_exists(name)
    local res = file.open(name, 'r')
    if (res == true) then
        file.close()
        return true
    end
    return false
end

function start()
    if (file_exists('config.lua')) then
        config = require('config.lua')
        dofile('client.lua')
    else
        dofile('server.lua')
    end
end

print('Starting up...\n')
print('Run "tmr.stop(0)" within 5s to abort startup')

tmr.alarm(0, 5000, 0, start)
