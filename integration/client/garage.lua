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

--- Registers a property garage with external garage systems (e.g. qb-garages)
--- @param garageId string|number
--- @param garageCoords vector3|vector4|table
--- @param extraData table|nil
--- @return boolean
Lib47.SetHouseGarage = function(garageId, garageCoords, extraData)
    local script = Lib47.GetGarageScript()
    local idStr = tostring(garageId)

    if script == 'qb-garages' or script == 'qb-garage' or script == 'qbx_garages' then
        if garageCoords and garageCoords.x then
            TriggerEvent('qb-garages:client:addHouseGarage', 'H:' .. idStr, {
                label = 'H:' .. idStr,
                takeVehicle = garageCoords,
                category = (extraData and extraData.category) or 'car',
            })
            Wait(100)
            TriggerEvent('qb-garages:client:setHouseGarage', 'H:' .. idStr, true)
            return true
        end
    end
    return false
end

--- Unregisters a property garage from external systems
--- @param garageId string|number
--- @return boolean
Lib47.RemoveHouseGarage = function(garageId)
    local script = Lib47.GetGarageScript()
    local idStr = tostring(garageId)

    if script == 'qb-garages' or script == 'qb-garage' or script == 'qbx_garages' then
        TriggerEvent('qb-garages:client:setHouseGarage', 'H:' .. idStr, false)
        return true
    end
    return false
end

Lib47.StoreVehicleHousing = function(garageid, vehicle)
    local script = Lib47.GetGarageScript()

    if script == 'ak47_garage' then
        TriggerEvent("ak47_garage:housing:storevehicle", "Housing "..garageid, 'car')
        return true
    elseif script == 'ak47_qb_garage' then
        TriggerEvent("ak47_qb_garage:housing:storevehicle", "Housing "..garageid, 'car')
        return true
    elseif script == 'cd_garage' then
        if exports['cd_garage'] and exports['cd_garage'].StoreVehicle then
            exports['cd_garage']:StoreVehicle()
        else
            TriggerEvent('cd_garage:StoreVehicle_Main', 1, false)
        end
        return true
    elseif script == 'okokGarage' then
        TriggerEvent("okokGarage:StoreVehiclePrivate", tostring(garageid))
        return true
    elseif script == 'jg-advancedgarages' then
        TriggerEvent('jg-advancedgarages:client:store-vehicle', 'housing:'..garageid, "car")
        return true
    elseif script == 'loaf_garage' then
        exports.loaf_garage:StoreVehicle("property", vehicle)
        return true
    elseif script == 'zerio-garage' then
        TriggerServerEvent('ak47_housing:ZerioGarage:StoreVehicle', garageid, "Housing "..garageid)
        return true
    elseif script == 'custom' then
        -- your custom code below
        return false
    end
    return false
end

Lib47.OpenGarageHousing = function(garageid, coords)
    local script = Lib47.GetGarageScript()
    local ped = (cache and cache.ped) or PlayerPedId()
    local playerCoords = coords and vector3(coords.x, coords.y, coords.z) or GetEntityCoords(ped)
    local playerHeading = coords and (coords.w or coords.heading) or GetEntityHeading(ped)

    if script == 'ak47_garage' then
        TriggerEvent("ak47_garage:housing:takevehicle", "Housing "..garageid, 'car')
        return true
    elseif script == 'ak47_qb_garage' then
        TriggerEvent("ak47_qb_garage:housing:takevehicle", "Housing "..garageid, 'car')
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
        TriggerEvent('jg-advancedgarages:client:open-garage', 'housing:'..garageid, "car", vec4(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading))
        return true
    elseif script == 'loaf_garage' then
        exports.loaf_garage:BrowseVehicles("property", vec4(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading))
        return true
    elseif script == 'zerio-garage' then
        TriggerServerEvent('ak47_housing:ZerioGarage:Open', garageid, "Housing "..garageid, vec4(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading))
        return true
    elseif script == 'custom' then
        -- your custom code below
        return false
    end
    return false
end

exports('GetGarageScript', Lib47.GetGarageScript)
exports('IsGarageManagedExternally', Lib47.IsGarageManagedExternally)
exports('SetHouseGarage', Lib47.SetHouseGarage)
exports('RemoveHouseGarage', Lib47.RemoveHouseGarage)
exports('StoreVehicleHousing', Lib47.StoreVehicleHousing)
exports('OpenGarageHousing', Lib47.OpenGarageHousing)
