local Core = exports.vorp_core:GetCore()
MenuData = {}

TriggerEvent("tpz_menu_base:getData", function(call)
    MenuData = call
end)

-- ============================================================
--  Apri menu switch job
-- ============================================================

function openJobMenu()
    Core.Callback.TriggerAsync("pk_multijob:getMyJobs", function(data)
        if not data or #data.jobs == 0 then
            Core.NotifyFail("Multi Job", "Nessun lavoro assegnato.", 4000)
            return
        end

        local elements = {}

        for _, job in ipairs(data.jobs) do
            local isActive = job.name == data.active
            table.insert(elements, {
                label = job.label .. (isActive and "  ★" or ""),
                value = job.name,
                desc  = isActive and "Lavoro attualmente attivo" or "Clicca per attivare questo lavoro",
            })
        end

        MenuData.CloseAll()
        MenuData.Open(
            'default',
            GetCurrentResourceName(),
            'pk_multijob_menu',
            {
                title    = 'I Tuoi Lavori',
                subtext  = 'Attivo: ' .. data.active .. '  |  Slot: ' .. #data.jobs .. '/' .. data.maxJobs,
                align    = 'top-left',
                elements = elements,
            },
            -- onSelect
            function(selectData, menu)
                local selectedJob = selectData.current.value

                if selectedJob == data.active then
                    Core.NotifyTip("Questo lavoro è già attivo.", 3000)
                    menu.close()
                    return
                end

                Core.Callback.TriggerAsync("pk_multijob:setActiveJob", function(result)
                    if not result then
                        Core.NotifyFail("Multi Job", "Impossibile cambiare lavoro.", 4000)
                    end
                end, selectedJob)

                menu.close()
            end,
            -- onClose
            function(closeData, menu)
                menu.close()
            end
        )
    end)
end

-- ============================================================
--  Forza chiusura menu se player muore
-- ============================================================

AddEventHandler("tpz_menu_base:onForcedClosed", function()
    MenuData.CloseAll()
end)
