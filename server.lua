
debugging = false
debuggers = {
  ["license:xxx000"] = true,
  ["steam:000000"] = true
}

RegisterCommand("SCSdebug", function(src)
  if src ~= 0 then
    local is_debugger = false
    for _,identifier in pairs(GetPlayerIdentifiers(src)) do
      if debuggers[identifier] then
        is_debugger = true
        break
      end
    end
    TriggerClientEvent("sc-sync:SetDebugStatus", src, is_debugger)
  else
    -- console execution
    debugging = not debugging
    if debugging then
      print("Debug enabled")
    else
      print("Debug disabled")
    end
  end
end)

function debug(...)
  if debugging then
    print(table.unpack({...}))
  end
end

globals = {}

RegisterNetEvent("sc-sync:GetGlobals", function()
  local client = source
  TriggerClientEvent("sc-sync:GetGlobals", client, globals)
  debug("Client[" .. json.encode(client) .. "]: GetGlobals")
end)

checkers = {}

exports("GetGlobal", function (key, callback)
  local value = globals[key]
  pcall(callback, value)
  debug("GetGlobal(" .. json.encode(key) .. ", callback(" .. json.encode(value) .. "))")
end)

exports("SetGlobal", function (key, value)
  globals[key] = value
  TriggerClientEvent("sc-sync:SetGlobal", -1, key, value)
  debug("SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
end)

exports("AddGlobalChecker", function(key, checker, callback)
  if checkers[key] == nil then
    checkers[key] = {}
  end
  table.insert(checkers[key], checker)
  local index = #checkers[key]
  debug("AddGlobalChecker(" .. json.encode(key) .. "): index[" .. tostring(index) .. "]")
  pcall(callback, index)
end)

exports("RemoveGlobalChecker", function (key, index)
  if checkers[key] ~= nil then
    checkers[key][index] = nil
    if #checkers[key] == 0 then
      checkers[key] = nil
    end
  end
  debug("RemoveGlobalChecker(" .. json.encode(key) .. ", " .. tostring(index) .. ")")
end)

RegisterNetEvent("sc-sync:SetGlobal", function(key, value, index)
  local client = source
  local allowed = true
  if checkers[key] ~= nil then
    for _, checker in pairs(checkers[key]) do
      local executed, allow = pcall(checker, client, value)
      if executed and not allow then
        allowed = false
        break
      end
    end
  end
  if allowed then
    globals[key] = value
    TriggerClientEvent("sc-sync:SetGlobal", -1, key, value)
  end
  if type(index) == "number" then
    TriggerClientEvent("sc-sync:SetGlobal:Result", client, key, index, allowed)
  end
  debug("Client[" .. json.encode(client) .. "]: SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ", " .. json.encode(index) .. "): " .. tostring(allowed))
end)

privates = {}

RegisterNetEvent("sc-sync:InitializePrivate", function()
  local client = source
  privates[client] = {}
  debug("Client[" .. json.encode(client) .. "]: InitializePrivate()")
end)

exports("GetPrivate", function (client, key, callback)
  local value
  if privates[client] ~= nil then
    value = privates[client][key]
  end
  pcall(callback, value)
  debug("GetPrivate(" .. json.encode(client) .. ", " .. json.encode(key) .. ", callback(" .. json.encode(value) .. "))")
end)

exports("SetPrivate", function (client, key, value)
  if privates[client] ~= nil then
    privates[client][key] = value
    TriggerClientEvent("sc-sync:SetPrivate", client, key, value)
  end
  debug("SetPrivate(" .. json.encode(client) .. ", " .. json.encode(key) .. ", " .. json.encode(value) .. ")")
end)

RegisterNetEvent("sc-sync:SetPrivate", function(key, value)
  local client = source
  privates[client][key] = value
  debug("Client[" .. json.encode(client) .. "]: SetPrivate(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
end)

AddEventHandler("playerDropped", function()
  local client = source
  privates[client] = nil
  debug("Client[" .. json.encode(client) .. "]: Left")
end)

RegisterCommand("SCSglobals", function(executer)
  if executer == 0 then -- console
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

RegisterCommand("SCScheckers", function(executer)
  if executer == 0 then -- console
    local exist = false
    for key in pairs(checkers) do
      print(json.encode(key) .. " => checkers: " .. tostring(#checkers[key]))
      exist = true
    end
    if not exist then
      print("Empty \"checkers\"")
    end
  end
end)

RegisterCommand("SCSprivates", function(executer, args)
  if executer == 0 then -- console
    if #args == 1 then
      local client = tonumber(args[1])
      if type(client) == "number" then
        if privates[client] ~= nil then
          local exist = false
          for key,value in pairs(privates[client]) do
            print(json.encode(key) .. " => " .. json.encode(value))
            exist = true
          end
          if not exist then
            print("Empty \"privates[" .. tostring(client) .. "]\"")
          end
        else
          print("Target is not listed")
        end
      else
        print("Bad argument #1 (number expected)")
      end
    else
      print("Argument count mismatch (passed " .. tostring(#args) .. ", wanted 1)")
    end
  end
end)
