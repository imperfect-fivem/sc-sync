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

exports("GetGlobal", function (key)
  local value = globals[key]
  if debugging then
    print("GetGlobal(" .. json.encode(key) .. "): " .. json.encode(value))
  end
  return value
end)

exports("SetGlobal", function (key, value, callback)
  local id = tostring(GetGameTimer())
  local result_handler
  local function handleResult(allowed)
    pcall(callback, allowed)
    if debugging then
      print("Server: SetGlobal.Result[" .. json.encode(id) .. "]: " .. json.encode(allowed))
    end
    RemoveEventHandler(result_handler)
  end
  result_handler = AddEventHandler("sc-sync:SetGlobal:Result:" .. id, handleResult)
  TriggerServerEvent("sc-sync:SetGlobal", key, value, id)
  if debugging then
    print("SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. "): " .. json.encode(id))
  end
  return id
end)

RegisterNetEvent("sc-sync:SetGlobal", function(key, value)
  globals[key] = value
  if debugging then
    print("Server: SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
  end
end)

privates = {}

TriggerServerEvent("sc-sync:InitializePrivate")

exports("GetPrivate", function (key)
  local value = privates[key]
  if debugging then
    print("GetPrivate(" .. json.encode(key) .. "): " .. json.encode(value))
  end
  return value
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
