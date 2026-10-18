if Config.TimeScript == 'auto' then
    local scripts = {
        'ak47_timesync',
        'qb-weathersync',
        'cd_easytime',
        'vSync',
        'av_weather',
    }
    CreateThread(function()
        for _, script in pairs(scripts) do
            if GetResourceState(script) == 'started' then
                Config.TimeScript = script
                print(string.format("^2['TIME & WEATHER']: %s^0", Config.TimeScript))
                return
            end
        end
    end)

    AddEventHandler('onResourceStart', function(resourceName)
        for _, script in pairs(scripts) do
            if script == resourceName then
                Config.TimeScript = script
                print(string.format("^2['TIME & WEATHER']: %s^0", Config.TimeScript))
                return
            end
        end
    end)
end

local WeatherTypes = {
    [GetHashKey('BLIZZARD')] = 'BLIZZARD',
    [GetHashKey('CLEAR')] = 'CLEAR',
    [GetHashKey('CLEARING')] = 'CLEARING',
    [GetHashKey('CLOUDS')] = 'CLOUDS',
    [GetHashKey('EXTRASUNNY')] = 'EXTRASUNNY',
    [GetHashKey('FOGGY')] = 'FOGGY',
    [GetHashKey('HALLOWEEN')] = 'HALLOWEEN',
    [GetHashKey('NEUTRAL')] = 'NEUTRAL',
    [GetHashKey('OVERCAST')] = 'OVERCAST',
    [GetHashKey('RAIN')] = 'RAIN',
    [GetHashKey('SMOG')] = 'SMOG',
    [GetHashKey('SNOW')] = 'SNOW',
    [GetHashKey('SNOWLIGHT')] = 'SNOWLIGHT',
    [GetHashKey('THUNDER')] = 'THUNDER',
    [GetHashKey('XMAS')] = 'XMAS',
}

local PauseSyncState = false
local LastHour, LastMinute = 0, 0
local LastWeather = 'EXTRASUNNY'

local function GetCurrentWeatherString()
    local prevHash, nextHash, interp = GetWeatherTypeTransition()
    local currentHash = (interp > 0.5 and nextHash ~= 0) and nextHash or prevHash
    return WeatherTypes[currentHash] or 'EXTRASUNNY'
end

Lib47.PauseTimeSync = function(pause, overrideHour, overrideWeather)
    overrideHour = overrideHour or 21
    overrideWeather = overrideWeather or 'EXTRASUNNY'

    if Config.TimeScript == 'ak47_timesync' then
        exports['ak47_timesync']:SetPauseSync(pause, overrideHour)
    elseif Config.TimeScript == 'cd_easytime' then
        TriggerEvent('cd_easytime:PauseSync', pause, overrideHour)
    elseif Config.TimeScript == 'av_weather' then
        TriggerEvent('av_weather:freeze', pause, overrideHour, 0, overrideWeather)
    elseif Config.TimeScript == 'qb-weathersync' then
        if pause then
            TriggerEvent('qb-weathersync:client:DisableSync')
            SetWeatherTypeOverTime(overrideWeather, 1.0)
            SetOverrideWeather(overrideWeather)
            SetWeatherTypePersist(overrideWeather)
            SetWeatherTypeNowPersist(overrideWeather)
            SetWeatherTypeNow(overrideWeather)
            NetworkOverrideClockTime(overrideHour, 0, 0)
        else
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            TriggerEvent('qb-weathersync:client:EnableSync')
        end
    elseif Config.TimeScript == 'vSync' then
        TriggerEvent('vSync:toggle', not pause)
        if pause then
            SetOverrideWeather(overrideWeather)
            SetWeatherTypeNowPersist(overrideWeather)
            NetworkOverrideClockTime(overrideHour, 0, 0)
        else
            ClearOverrideWeather()
            ClearWeatherTypePersist()
        end
    else
        if pause then
            if not PauseSyncState then
                PauseSyncState = true

                LastHour = GetClockHours()
                LastMinute = GetClockMinutes()
                LastWeather = GetCurrentWeatherString()

                CreateThread(function()
                    while PauseSyncState do
                        SetRainLevel(0.0)
                        SetWeatherTypePersist(overrideWeather)
                        SetWeatherTypeNow(overrideWeather)
                        SetWeatherTypeNowPersist(overrideWeather)
                        SetOverrideWeather(overrideWeather)
                        NetworkOverrideClockTime(overrideHour, 0, 0)
                        Wait(100)
                    end
                end)
            else
                SetWeatherTypePersist(overrideWeather)
                SetWeatherTypeNow(overrideWeather)
                SetWeatherTypeNowPersist(overrideWeather)
                SetOverrideWeather(overrideWeather)
                NetworkOverrideClockTime(overrideHour, 0, 0)
            end
        else
            if PauseSyncState then
                PauseSyncState = false
                Wait(150)

                ClearOverrideWeather()
                ClearWeatherTypePersist()
                SetWeatherTypePersist(LastWeather)
                SetWeatherTypeNow(LastWeather)
                SetWeatherTypeNowPersist(LastWeather)
                NetworkClearClockTimeOverride()
                NetworkOverrideClockTime(LastHour, LastMinute, 0)
            end
        end
    end
end

exports('PauseTimeSync', Lib47.PauseTimeSync)
