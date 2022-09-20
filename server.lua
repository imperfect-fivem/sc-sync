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

globals = {}

RegisterNetEvent("sc-sync:GetGlobals", function()
  local client = source
  TriggerClientEvent("sc-sync:GetGlobals", client, globals)
  if debugging then
    print("Client[" .. json.encode(client) .. "]: GetGlobals")
  end
end)

checkers = {}

exports("GetGlobal", function (key)
  local value = globals[key]
  if debugging then
    print("GetGlobal(" .. json.encode(key) .. "): " .. json.encode(value))
  end
  return value
end)

exports("SetGlobal", function (key, value)
  globals[key] = value
  TriggerClientEvent("sc-sync:SetGlobal", -1, key, value)
  if debugging then
    print("SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
  end
end)

exports("AddGlobalChecker", function(key, checker)
  if checkers[key] == nil then
    checkers[key] = {}
  end
  table.insert(checkers[key], checker)
  local index = #checkers[key]
  if debugging then
    print("AddGlobalChecker(" .. json.encode(key) .. "): index[" .. tostring(index) .. "]")
  end
  return index
end)

exports("RemoveGlobalChecker", function (key, index)
  if checkers[key] ~= nil then
    checkers[key][index] = nil
    if #checkers[key] == 0 then
      checkers[key] = nil
    end
  end
  if debugging then
    print("RemoveGlobalChecker(" .. json.encode(key) .. ", " .. tostring(index) .. ")")
  end
end)

RegisterNetEvent("sc-sync:SetGlobal", function(key, value, id)
  local client = source
  local allowed = true
  local reason
  if checkers[key] ~= nil then
    for _, checker in pairs(checkers[key]) do
      local executed, allow, justification = pcall(checker, client, value)
      if executed and not allow then
        allowed = false
        reason = justification
        break
      end
    end
  end
  if allowed then
    globals[key] = value
    TriggerClientEvent("sc-sync:SetGlobal", -1, key, value)
  end
  TriggerClientEvent("sc-sync:SetGlobal:Result:" .. tostring(id), client, allowed, reason)
  if debugging then
    print("Client[" .. json.encode(client) .. "]: SetGlobal(" .. json.encode(key) .. ", " .. json.encode(value) .. ", " .. json.encode(id) .. "): " .. tostring(allowed) .. ", " .. json.encode(reason))
  end
end)

privates = {}

RegisterNetEvent("sc-sync:InitializePrivate", function()
  local client = source
  privates[client] = {}
  if debugging then
    print("Client[" .. json.encode(client) .. "]: InitializePrivate()")
  end
end)

exports("GetPrivate", function (client, key)
  local value
  if privates[client] ~= nil then
    value = privates[client][key]
  end
  if debugging then
    print("GetPrivate(" .. json.encode(client) .. ", " .. json.encode(key) .. "): " .. json.encode(value))
  end
  return value
end)

exports("SetPrivate", function (client, key, value)
  if privates[client] ~= nil then
    privates[client][key] = value
    TriggerClientEvent("sc-sync:SetPrivate", client, key, value)
  end
  if debugging then
    print("SetPrivate(" .. json.encode(client) .. ", " .. json.encode(key) .. ", " .. json.encode(value) .. ")")
  end
end)

RegisterNetEvent("sc-sync:SetPrivate", function(key, value)
  local client = source
  privates[client][key] = value
  if debugging then
    print("Client[" .. json.encode(client) .. "]: SetPrivate(" .. json.encode(key) .. ", " .. json.encode(value) .. ")")
  end
end)

AddEventHandler("playerDropped", function()
  local client = source
  privates[client] = nil
  if debugging then
    print("Client[" .. json.encode(client) .. "]: Left")
  end
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
