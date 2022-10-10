# Server Clients Sync
Standalone [FiveM script](https://docs.fivem.net/docs/scripting-manual/introduction/creating-your-first-script/) that synchronize values between the server and the clients.

## How it works
Both the server and the client save the values in a [table](https://www.lua.org/pil/2.5.html).  
Once one of them change the values, it sends an [event](https://docs.fivem.net/docs/scripting-reference/events/) to the other side to update that value.
There are two types of values:
- `Globals`: Synchronized values between the server and all clients.
- `Privates`: Synchronized values between the server and a specific client.  
Not all the clients are allowed to change a global value but all the clients are always allowed to change their private values.  
What decide whether a client is allowed to change a global value or not is a server-side [checker](#Checker) added by the developer.

## Usage
All script's functionality works with [exports](https://docs.fivem.net/docs/scripting-manual/runtimes/lua/#using-exports).

### Server
Before the exports, there are some commands:
- `SCSdebug`: Toggle print debug stuff in the console.
- `SCSglobals`: Print all the global values in the console.
- `SCScheckers`: Print the count of checkers on each global value.
- `SCSprivates`: Print all the private values of a specific client in the console.

#### Server Global
Control the global values from the server.

##### GetGlobal
Get a global value using a key, example:
```lua
local weather = exports["sc-sync"]:GetGlobal("weather")
print("The weather is: " .. weather)
```

##### SetGlobal
Set a global value using a key, example:
```lua
exports["sc-sync"]:SetGlobal("weather", "clear")
```

#### Checker
Control the checkers.

##### AddGlobalChecker
Add a checker on a global value using a key, example:
```lua
exports["sc-sync"]:AddGlobalChecker("weather", function(src, value)
  if GetPlayerName(src) == "Owner" then -- this is just for the example, don't use it :)
    local weather_type = string.upper(value)
    if
      weather_type == "BLIZZARD" or
      weather_type == "CLEAR" or
      weather_type == "CLEARING" or
      weather_type == "CLOUDS" or
      weather_type == "EXTRASUNNY" or
      weather_type == "FOGGY" or
      weather_type == "HALLOWEEN" or
      weather_type == "NEUTRAL" or
      weather_type == "OVERCAST" or
      weather_type == "RAIN" or
      weather_type == "SMOG" or
      weather_type == "SNOW" or
      weather_type == "SNOWLIGHT" or
      weather_type == "THUNDER" or
      weather_type == "XMAS"
    then
      return true
    end
  end
  return false
end)
```

##### RemoveGlobalChecker
Remove a checker from a global value using a key and index, example:
```lua
local checker_index = exports["sc-sync"]:AddGlobalChecker("weather", function(src, value)
  return GetPlayerName(src) == "Owner" -- this is just for the example, don't use it :)
end)

RegisterCommand("free4all", function()
  exports["sc-sync"]:RemoveGlobalChecker("weather", checker_index)
end, true)
```

#### Server Private
Control clients' private values from the server.

##### GetPrivate
Get a private value of a client using a key and source, example:
```lua
local src = 1 -- any source
local in_task = exports["sc-sync"]:GetPrivate(src, "in_task")
if in_task then
  print("player[" .. tostring(src) .. "] is in the task.")
else
  print("player[" .. tostring(src) .. "] isn't in the task.")
end
```

##### SetPrivate
Set a private value of a client using a key and source, example:
```lua
local src = 1 -- any source
exports["sc-sync"]:SetPrivate(src, "in_task", true)
```

### Client
Before the exports, there are some commands:
- `SCSdebug`: Toggle print debug stuff in the console.
- `SCSglobals`: Print all the global values in the console.
- `SCSprivates`: Print all the private values in the console.

#### Client Global
Control global values from the client.

##### GetGlobal
Get a global value using a key, example:
```lua
local weather = exports["sc-sync"]:GetGlobal("weather")
print("The weather is: " .. weather)
```

##### SetGlobal
Set a global value using a key, example:
```lua
exports["sc-sync"]:SetGlobal("weather", "clear", function(set, justification)
  if set then
    print("Changed the weather successfully.")
  else
    print("Changing the weather failed, reason: " .. justification .. ".")
  end
end)
```

#### Client Private
Control private values from the client.

##### GetPrivate
Get a private value using a key, example:
```lua
local in_task = exports["sc-sync"]:GetPrivate("in_task")
if in_task then
  print("In the task.")
else
  print("Not in the task.")
end
```

##### SetPrivate
Set a private value using a key, example:
```lua
exports["sc-sync"]:SetPrivate("in_task", false)
```
