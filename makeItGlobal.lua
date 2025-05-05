local addonName, addon = ...
_G[addonName] = addon

-- /dump TransmogMailer
-- /dump TransmogMailerSV
-- /run TransmogMailer.DumpSV()
-- /run TransmogMailer.DumpMailingList()

function addon.DumpSV()
    DevTools_Dump(addon.db)
end

function addon.DumpMailingList()
    addon.frame:BuildMailingList()
    DevTools_Dump(addon.frame.mailingList)
end