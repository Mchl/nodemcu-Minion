-- file : application.lua
local module = {}  
m = nil
id = node.chipid()

red = 0
green = 0
blue = 0

--gpio.mode(1,gpio.OUTPUT)
--gpio.mode(2,gpio.OUTPUT)
--gpio.mode(3,gpio.OUTPUT)

pwm.setup(1,1000,1023);
pwm.setup(2,1000,1023);
pwm.setup(3,1000,1023);

pwm.setduty(1,red)
pwm.setduty(2,green)
pwm.setduty(3,blue)

-- Sends a simple ping to the broker
local function send_ping()  
    m:publish("iot/heartbeat",cjson.encode({
        id=id,
        config=config,
        state={
            red=red,
            green=green,
            blue=blue
        }
    }),0,0)
end

-- Sends my id to the broker for registration
local function register_myself()  
    m:subscribe( "iot/things/" .. id,0,function(conn)
        print("Successfully subscribed to data endpoint")
    end)
end

local function mqtt_start()  
    m = mqtt.Client(id, 120)
    -- register message callback beforehand
    m:on("message", function(conn, topic, data) 
      if data ~= nil then
        -- do something, we have received a message
        ok, payload = pcall(cjson.decode,data)
        if ok and payload.action == "set" and payload.state ~= nil and payload.state.green ~= nil then
            green = payload.state.green
            pwm.setduty(2,green);
        end

        if ok and payload.action == "set" and payload.state ~= nil and payload.state.red ~= nil then
            red = payload.state.red
            pwm.setduty(1,red);
        end

        if ok and payload.action == "set" and payload.state ~= nil and payload.state.blue ~= nil then
            blue = payload.state.blue
            pwm.setduty(3,blue);
        end
   
      end
    end)
    -- Connect to broker
    m:connect("192.168.0.17", "1883", 0, 1, function(con) 
        register_myself()
        -- And then pings each 1000 milliseconds
        tmr.stop(6)
        tmr.alarm(6, 1000, 1, send_ping)
    end) 

end

function module.start()  
    mqtt_start()
end

return module
