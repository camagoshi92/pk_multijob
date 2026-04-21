local Core = exports.vorp_core:GetCore()

-- ============================================================
--  Notifiche
-- ============================================================

RegisterNetEvent("pk_multijob:client:notify", function(title, subtitle, ntype)
    if ntype == "fail" then
        Core.NotifyFail(title, subtitle, 4000)
    elseif ntype == "update" then
        Core.NotifyUpdate(title, subtitle, 4000)
    else
        Core.NotifyTip(title .. " - " .. subtitle, 4000)
    end
end)

-- ============================================================
--  Apertura menu
-- ============================================================

RegisterCommand("pk_myjobs", function()
    CreateThread(openJobMenu)
end, false)

RegisterNetEvent("pk_multijob:client:openMenu", function()
    CreateThread(openJobMenu)
end)

exports("OpenJobMenu", function()
    CreateThread(openJobMenu)
end)

-- ============================================================
--  Al spawn mostra il job attivo
-- ============================================================

AddEventHandler("vorp_core:Client:OnPlayerSpawned", function()
    Core.Callback.TriggerAsync("pk_multijob:getMyJobs", function(data)
        if not data then
            return
        end

        Core.NotifySimpleTop(
            "Lavoro attivo",
            data.active .. " (grade " .. data.grade .. ")",
            5000
        )
    end)
end)
