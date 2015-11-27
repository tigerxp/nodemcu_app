-- Globals
config = {}
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
        config = require('config')
        dofile('client.lua')
    else
        dofile('server.lua')
    end
end

print('Starting up...\n')
print('Run "tmr.stop(0)" within 10s to abort startup')

tmr.alarm(0, 10000, 0, start)
