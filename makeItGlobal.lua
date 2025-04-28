local addonName, addon = ...
_G[addonName] = addon

-- /dump TransmogMailer
-- /dump TransmogMailerSV
-- /run TransmogMailer.DumpSV()

function addon.DumpSV()
    DevTools_Dump(addon.sv)
end