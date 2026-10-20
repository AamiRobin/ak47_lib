Lib47.DoesExportExist = function(resourceName, exportName)
    if type(resourceName) ~= 'string' or type(exportName) ~= 'string' then
        return false, nil
    end

    local state = GetResourceState(resourceName)
    if state ~= 'started' and state ~= 'starting' then
        return false, nil
    end

    local ok, exportRef = pcall(function()
        return exports[resourceName][exportName]
    end)

    if ok and exportRef ~= nil then
        return true, exportRef
    end

    return false, nil
end

Lib47.SafeExport = function(resourceName, exportName, ...)
    local exists, exportRef = Lib47.DoesExportExist(resourceName, exportName)
    if not exists then
        return false, ('Export "%s" does not exist or resource "%s" is not started'):format(tostring(exportName), tostring(resourceName))
    end

    return pcall(exportRef, exports[resourceName], ...)
end

exports('DoesExportExist', Lib47.DoesExportExist)
exports('SafeExport', Lib47.SafeExport)