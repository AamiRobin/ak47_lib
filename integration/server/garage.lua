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

--- Resolves active garage script on server
--- @return string
Lib47.GetGarageScript = function()
    if Config.Garage and Config.Garage ~= 'auto' then
        return Config.Garage
    end

    for _, script in ipairs(garageScripts) do
        local state = GetResourceState(script)
        if state == 'started' or state == 'starting' then
            Config.Garage = script
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
                return
            end
        end
    end
end)

--- Updates vehicle stored state and garage name in framework database
--- @param plate string
--- @param stored boolean
--- @param garage string|nil
Lib47.SetVehicleStored = function(plate, stored, garage)
    if not plate then return end
    local schema = Lib47.GetVehicleSchema and Lib47.GetVehicleSchema()
    if not schema then return end

    if stored then
        MySQL.Async.execute(string.format('UPDATE `%s` SET `%s` = 1, `%s` = ? WHERE `plate` = ?', schema.name, schema.stored, schema.garage), {
            garage or 'Garage',
            plate
        })
    else
        MySQL.Async.execute(string.format('UPDATE `%s` SET `%s` = 0 WHERE `plate` = ?', schema.name, schema.stored), {
            plate
        })
    end
end

--- Sync newly created or moved garage to external garage database (e.g. jg-advancedgarages)
--- @param garageId string|number
--- @param garageCoords vector3|vector4|table
--- @param extraData table|nil Optional { name = string, label = string, type = string, category = string }
--- @return boolean
Lib47.SyncExternalGarageCreated = function(garageId, garageCoords, extraData)
    if not garageId or not garageCoords or not garageCoords.x then return false end
    local script = Lib47.GetGarageScript()

    if script == 'jg-advancedgarages' or (script == 'auto' and GetResourceState('jg-advancedgarages') == 'started') then
        local idStr = tostring(garageId)
        local heading = garageCoords.w or garageCoords.h or garageCoords.heading or 0.0
        local name = (extraData and (extraData.name or extraData.label)) or ('Garage: ' .. idStr)
        local gType = (extraData and (extraData.type or extraData.category)) or 'car'

        MySQL.Async.execute("REPLACE INTO `player_priv_garages` (id, name, `type`, `x`, `y`, `z`, `h`) VALUES (?, ?, ?, ?, ?, ?, ?)", {
            idStr, name, gType, garageCoords.x, garageCoords.y, garageCoords.z, heading
        })
        return true
    end
    return false
end
Lib47.CreateGarage = Lib47.SyncExternalGarageCreated

--- Remove garage from external garage database
--- @param garageId string|number
--- @return boolean
Lib47.SyncExternalGarageDeleted = function(garageId)
    if not garageId then return false end
    local script = Lib47.GetGarageScript()

    if script == 'jg-advancedgarages' or (script == 'auto' and GetResourceState('jg-advancedgarages') == 'started') then
        local idStr = tostring(garageId)
        MySQL.Async.execute("DELETE FROM `player_priv_garages` WHERE id = ?", {idStr})
        return true
    end
    return false
end
Lib47.DeleteGarage = Lib47.SyncExternalGarageDeleted

--- Stores a vehicle via server-side garage script (e.g. zerio-garage)
--- @param source number
--- @param garageId string|number
--- @param label string|nil
--- @param extraData table|nil
--- @return boolean
Lib47.StoreVehicleToGarage = function(source, garageId, label, extraData)
    local script = Lib47.GetGarageScript()
    local idStr = tostring(garageId)
    local garageLabel = label or (extraData and extraData.label) or ('Garage: ' .. idStr)

    if script == 'zerio-garage' or GetResourceState('zerio-garage') == 'started' then
        if exports['zerio-garage'] and exports['zerio-garage'].StoreHousingVehicle then
            exports['zerio-garage']:StoreHousingVehicle(source, idStr, garageLabel)
            return true
        end
    end
    return false
end

--- Opens a garage via server-side garage script (e.g. zerio-garage)
--- @param source number
--- @param garageId string|number
--- @param label string|nil
--- @param spawnCoords vector4|table
--- @param extraData table|nil
--- @return boolean
Lib47.OpenVehicleGarage = function(source, garageId, label, spawnCoords, extraData)
    local script = Lib47.GetGarageScript()
    local idStr = tostring(garageId)
    local garageLabel = label or (extraData and extraData.label) or ('Garage: ' .. idStr)

    if script == 'zerio-garage' or GetResourceState('zerio-garage') == 'started' then
        if exports['zerio-garage'] and exports['zerio-garage'].OpenHousingGarage then
            exports['zerio-garage']:OpenHousingGarage(source, idStr, garageLabel, spawnCoords)
            return true
        end
    end
    return false
end

--====================================================================================
-- Server Network Events (Unified & Legacy compatibility)
--====================================================================================

RegisterNetEvent('ak47_lib:garage:server:StoreVehicle', function(garageId, label, extraData)
    local _source = source
    Lib47.StoreVehicleToGarage(_source, garageId, label, extraData)
end)

RegisterNetEvent('ak47_lib:garage:server:OpenGarage', function(garageId, label, spawnCoords, extraData)
    local _source = source
    Lib47.OpenVehicleGarage(_source, garageId, label, spawnCoords, extraData)
end)

-- Legacy Zerio Garage compatibility
RegisterNetEvent('ak47_housing:ZerioGarage:StoreVehicle', function(hid, label)
    local _source = source
    Lib47.StoreVehicleToGarage(_source, hid, label or ('Housing: ' .. tostring(hid)))
end)

RegisterNetEvent('ak47_housing:ZerioGarage:Open', function(hid, label, spawn)
    local _source = source
    Lib47.OpenVehicleGarage(_source, hid, label or ('Housing: ' .. tostring(hid)), spawn)
end)

RegisterNetEvent('ak47_qb_housing:ZerioGarage:StoreVehicle', function(hid, label)
    local _source = source
    Lib47.StoreVehicleToGarage(_source, hid, label or ('Housing: ' .. tostring(hid)))
end)

RegisterNetEvent('ak47_qb_housing:ZerioGarage:Open', function(hid, label, spawn)
    local _source = source
    Lib47.OpenVehicleGarage(_source, hid, label or ('Housing: ' .. tostring(hid)), spawn)
end)

exports('GetGarageScript', Lib47.GetGarageScript)
exports('SetVehicleStored', Lib47.SetVehicleStored)
exports('CreateGarage', Lib47.CreateGarage)
exports('DeleteGarage', Lib47.DeleteGarage)
exports('SyncExternalGarageCreated', Lib47.SyncExternalGarageCreated)
exports('SyncExternalGarageDeleted', Lib47.SyncExternalGarageDeleted)
exports('StoreVehicleToGarage', Lib47.StoreVehicleToGarage)
exports('OpenVehicleGarage', Lib47.OpenVehicleGarage)
