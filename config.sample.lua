return {
    wifi_ssid = 'open',
    wifi_password = '',
    ts_address = '54.88.155.198', -- api.thingspeak.com
    ts_port = 80,
    ts_url = '/update',
    ts_api_key = 'YOUR_API_KEY',
    ds_pin = 2, -- i/o index, GPIO4
    relay_pin = 0, -- test only, GPIO16 (user led)
    loop_time = 30 -- seconds
}
