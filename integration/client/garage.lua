local garageScripts = {
    'ak47_garage',
    'ak47_qb_garage',
    'cd_garage',
    'okokGarage',
    'jg-advancedgarages',
    'loaf_garage',
    'zerio-garage',
    'qb-garages',
    'qb-garage',
    'qbx_garages',
}

--- Resolves and caches the active garage script
--- @return string
Lib47.GetGarageScript = function()
    if Config.Garage and Config.Garage ~= 'auto' then
        return Config.Garage
    end

    for _, script in ipairs(garageScripts) do
        local state = GetResourceState(script)
        if state == 'started' or state == 'starting' then
            Config.Garage = script
            print(string.format("^2['GARAGE']: %s^0", Config.Garage))
            return Config.Garage
        end
    end

    return 'standalone'
end

CreateThread(function()
    Lib47.GetGarageScript()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if Config.Garage == 'auto' or Config.Garage == 'standalone' then
        for _, script in ipairs(garageScripts) do
            if script == resourceName then
                Config.Garage = script
                print(string.format("^2['GARAGE']: %s^0", Config.Garage))
                return
            end
        end
    end
end)

--- Checks whether the active garage system handles its own markers / radial prompts
--- @return boolean
Lib47.IsGarageManagedExternally = function()
    local script = Lib47.GetGarageScript()
    return script == 'qb-garages' or script == 'qb-garage' or script == 'qbx_garages' or script == 'jg-advancedgarages'
end

--- Registers a garage with external garage systems (e.g. qb-garages)
--- @param garageId string|number
--- @param garageCoords vector3|vector4|table
--- @param extraData table|nil Optional { label = string, category = string, prefix = string, id = string }
--- @return boolean
Lib47.SetGarage = function(garageId, garageCoords, extraData)
    local script = Lib47.GetGarageScript()
    local idStr = tostring(garageId)
    local prefix = (extraData and extraData.prefix) or ''
    local formattedId = (extraData and extraData.id) or (prefix ~= '' and (prefix .. idStr)) or idStr
    local label = (extraData and extraData.label) or formattedId
    local category = (extraData and extraData.category) or 'car'

    if script == 'qb-garages' or script == 'qb-garage' or script == 'qbx_garages' then
        if garageCoords and garageCoords.x then
            TriggerEvent('qb-garages:client:addHouseGarage', formattedId, {
                label = label,
                takeVehicle = garageCoords,
                category = category,
            })
            Wait(100)
            TriggerEvent('qb-garages:client:setHouseGarage', formattedId, true)
            return true
        end
    end
    return false
end

--- Unregisters a garage from external systems
--- @param garageId string|number
--- @param extraData table|nil Optional { prefix = string, id = string }
--- @return boolean
Lib47.RemoveGarage = function(garageId, extraData)
    local script = Lib47.GetGarageScript()
    local idStr = tostring(garageId)
    local prefix = (extraData and extraData.prefix) or ''
    local formattedId = (extraData and extraData.id) or (prefix ~= '' and (prefix .. idStr)) or idStr

    if script == 'qb-garages' or script == 'qb-garage' or script == 'qbx_garages' then
        TriggerEvent('qb-garages:client:setHouseGarage', formattedId, false)
        return true
    end
    return false
end

--- Stores a vehicle into the active garage script
--- @param garageId string|number
--- @param vehicle number
--- @param extraData table|nil Optional { label = string, category = string, prefix = string, garageType = string, jgId = string }
--- @return boolean
Lib47.StoreVehicleToGarage = function(garageId, vehicle, extraData)
    local script = Lib47.GetGarageScript()
    local idStr = tostring(garageId)
    local label = (extraData and extraData.label) or ('Garage ' .. idStr)
    local category = (extraData and extraData.category) or 'car'
    local garageType = (extraData and extraData.garageType) or 'property'
    local prefix = (extraData and extraData.prefix) or ''

    if script == 'ak47_garage' then
        TriggerEvent("ak47_garage:housing:storevehicle", label, category)
        return true
    elseif script == 'ak47_qb_garage' then
        TriggerEvent("ak47_qb_garage:housing:storevehicle", label, category)
        return true
    elseif script == 'cd_garage' then
        if exports['cd_garage'] and exports['cd_garage'].StoreVehicle then
            exports['cd_garage']:StoreVehicle()
        else
            TriggerEvent('cd_garage:StoreVehicle_Main', 1, false)
        end
        return true
    elseif script == 'okokGarage' then
        TriggerEvent("okokGarage:StoreVehiclePrivate", idStr)
        return true
    elseif script == 'jg-advancedgarages' then
        local jgId = (extraData and extraData.jgId) or (prefix ~= '' and (prefix .. idStr)) or ('housing:' .. idStr)
        TriggerEvent('jg-advancedgarages:client:store-vehicle', jgId, category)
        return true
    elseif script == 'loaf_garage' then
        exports.loaf_garage:StoreVehicle(garageType, vehicle)
        return true
    elseif script == 'zerio-garage' then
        TriggerServerEvent('ak47_lib:garage:server:StoreVehicle', idStr, label, extraData)
        return true
    elseif script == 'custom' then
        -- your custom code below
        return false
    end
    return false
end

--- Opens the garage menu to retrieve a vehicle from the active garage script
--- @param garageId string|number
--- @param coords vector3|vector4|table|nil
--- @param extraData table|nil Optional { label = string, category = string, prefix = string, garageType = string, jgId = string }
--- @return boolean
Lib47.OpenVehicleGarage = function(garageId, coords, extraData)
    local script = Lib47.GetGarageScript()
    local idStr = tostring(garageId)
    local ped = (cache and cache.ped) or PlayerPedId()
    local playerCoords = coords and vector3(coords.x, coords.y, coords.z) or GetEntityCoords(ped)
    local playerHeading = coords and (coords.w or coords.heading or coords.h) or GetEntityHeading(ped)
    local spawnCoords = vec4(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading)
    local label = (extraData and extraData.label) or ('Garage ' .. idStr)
    local category = (extraData and extraData.category) or 'car'
    local garageType = (extraData and extraData.garageType) or 'property'
    local prefix = (extraData and extraData.prefix) or ''

    if script == 'ak47_garage' then
        TriggerEvent("ak47_garage:housing:takevehicle", label, category)
        return true
    elseif script == 'ak47_qb_garage' then
        TriggerEvent("ak47_qb_garage:housing:takevehicle", label, category)
        return true
    elseif script == 'cd_garage' then
        if exports['cd_garage'] and exports['cd_garage'].OpenGarage then
            exports['cd_garage']:OpenGarage()
        else
            TriggerEvent('cd_garage:PropertyGarage', 'quick', nil)
        end
        return true
    elseif script == 'okokGarage' then
        TriggerEvent("okokGarage:OpenPrivateGarageMenu", playerCoords, playerHeading)
        return true
    elseif script == 'jg-advancedgarages' then
        local jgId = (extraData and extraData.jgId) or (prefix ~= '' and (prefix .. idStr)) or ('housing:' .. idStr)
        TriggerEvent('jg-advancedgarages:client:open-garage', jgId, category, spawnCoords)
        return true
    elseif script == 'loaf_garage' then
        exports.loaf_garage:BrowseVehicles(garageType, spawnCoords)
        return true
    elseif script == 'zerio-garage' then
        TriggerServerEvent('ak47_lib:garage:server:OpenGarage', idStr, label, spawnCoords, extraData)
        return true
    elseif script == 'custom' then
        -- your custom code below
        return false
    end
    return false
end

exports('GetGarageScript', Lib47.GetGarageScript)
exports('IsGarageManagedExternally', Lib47.IsGarageManagedExternally)
exports('SetGarage', Lib47.SetGarage)
exports('RemoveGarage', Lib47.RemoveGarage)
exports('StoreVehicleToGarage', Lib47.StoreVehicleToGarage)
exports('OpenVehicleGarage', Lib47.OpenVehicleGarage)
