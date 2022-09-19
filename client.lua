
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

globals = {}

TriggerServerEvent("sc-sync:GetGlobals")

callbacks = {}

exports("GetGlobal", function (key, callback)
  local value = globals[key]
  pcall(callback, value)
  if debugging then
    print("GetGlobal(" .. json.encode(key) .. ", callback(" .. json.encode(value) .. "))")
  end
end)

exports("SetGlobal", function (key, value, callback)
  if callbacks[key] == nil then
    callbacks[key] = {}
  end
  table.insert(callbacks[key], callback)
  local index = #callbacks[key]
  TriggerServerEvent("sc-sync:SetGlobal", key, value, index)
  if debugging then
    print("SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ", callbacks[" .. tostring(index) .. "])")
  end
end)

RegisterNetEvent("sc-sync:SetGlobal", function(key, value)
  globals[key] = value
  if debugging then
    print("Server: SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
  end
end)

RegisterNetEvent("sc-sync:SetGlobal:Result", function(key, index, allowed)
  if callbacks[key] ~= nil then
    if callbacks[key][index] ~= nil then
      pcall(callbacks[key][index], allowed)
      callbacks[key][index] = nil
    end
    if #callbacks[key] == 0 then
      callbacks[key] = nil
    end
  end
  if debugging then
    print("Server: SetGlobal.Result(" .. json.encode(key) .. ", " .. json.encode(index) .. ", " .. json.encode(allowed) .. ")")
  end
end)

privates = {}

TriggerServerEvent("sc-sync:InitializePrivate")

exports("GetPrivate", function (key, callback)
  local value = privates[key]
  pcall(callback, value)
  if debugging then
    print("GetPrivate(" .. json.encode(key) .. ", callback(" .. json.encode(value) .. "))")
  end
end)

exports("SetPrivate", function (key, value)
  privates[key] = value
  TriggerServerEvent("sc-sync:SetPrivate", key, value)
  if debugging then
    print("SetPrivate(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
  end
end)

RegisterNetEvent("sc-sync:SetPrivate", function(key, value)
  privates[key] = value
  if debugging then
    print("Server: SetPrivate(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
  end
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
