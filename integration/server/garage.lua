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
            garage or 'Housing',
            plate
        })
    else
        MySQL.Async.execute(string.format('UPDATE `%s` SET `%s` = 0 WHERE `plate` = ?', schema.name, schema.stored), {
            plate
        })
    end
end

exports('GetGarageScript', Lib47.GetGarageScript)
exports('SetVehicleStored', Lib47.SetVehicleStored)
