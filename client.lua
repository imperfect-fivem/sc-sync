
debugging = false

RegisterNetEvent("sc-sync:SetDebugStatus", function(allowed)
  if allowed then
    debugging = not debugging
    if debugging then
      print("Debug enabled")
    else
      print("Debug disabled")
    end
  else
    debugging = false
    print("Debug permissions refused")
  end
end)

function debug(...)
  if debugging then
    print(table.unpack({...}))
  end
end

globals = {}

TriggerServerEvent("sc-sync:GetGlobals")

callbacks = {}

exports("GetGlobal", function (key, callback)
  local value = globals[key]
  pcall(callback, value)
  debug("GetGlobal(" .. json.encode(key) .. ", callback(" .. json.encode(value) .. "))")
end)

exports("SetGlobal", function (key, value, callback)
  if callbacks[key] == nil then
    callbacks[key] = {}
  end
  table.insert(callbacks[key], callback)
  local index = #callbacks[key]
  TriggerServerEvent("sc-sync:SetGlobal", key, value, index)
  debug("SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ", callbacks[" .. tostring(index) .. "])")
end)

RegisterNetEvent("sc-sync:SetGlobal")
AddEventHandler("sc-sync:SetGlobal", function(key, value)
  globals[key] = value
  debug("Server: SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
end)

RegisterNetEvent("sc-sync:SetGlobal:Result")
AddEventHandler("sc-sync:SetGlobal:Result", function(key, index, allowed)
  if callbacks[key] ~= nil then
    if callbacks[key][index] ~= nil then
      pcall(callbacks[key][index], allowed)
      callbacks[key][index] = nil
    end
    if #callbacks[key] == 0 then
      callbacks[key] = nil
    end
  end
  debug("Server: SetGlobal.Result(" .. json.encode(key) .. ", " .. json.encode(index) .. ", " .. json.encode(allowed) .. ")")
end)

privates = {}

TriggerServerEvent("sc-sync:InitializePrivate")

exports("GetPrivate", function (key, callback)
  local value = privates[key]
  pcall(callback, value)
  debug("GetPrivate(" .. json.encode(key) .. ", callback(" .. json.encode(value) .. "))")
end)

exports("SetPrivate", function (key, value)
  privates[key] = value
  TriggerServerEvent("sc-sync:SetPrivate", key, value)
  debug("SetPrivate(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
end)

RegisterNetEvent("sc-sync:SetPrivate")
AddEventHandler("sc-sync:SetPrivate", function(key, value)
  privates[key] = value
  debug("Server: SetPrivate(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
end)

RegisterCommand("SCSglobals", function()
  if debugging then
    local exist = false
    for key,value in pairs(globals) do
      print(json.encode(key) .. " => " .. json.encode(value))
      exist = true
    end
    if not exist then
      print("Empty \"globals\"")
    end
  end
end)

RegisterCommand("SCSprivates", function()
  if debugging then
    local exist = false
    for key,value in pairs(privates) do
      print(json.encode(key) .. " => " .. json.encode(value))
      exist = true
    end
    if not exist then
      print("Empty \"privates\"")
    end
  end
end)
