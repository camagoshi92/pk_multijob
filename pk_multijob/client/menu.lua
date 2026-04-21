local Core = exports.vorp_core:GetCore()

-- ============================================================
--  Apri menu switch job
-- ============================================================

function openJobMenu()
    Core.Callback.TriggerAsync("pk_multijob:getMyJobs", function(data)
        if not data or type(data.jobs) ~= "table" or #data.jobs == 0 then
            Core.NotifyFail("Multi Job", "Nessun lavoro assegnato.", 4000)
            return
        end

        local elements = {}
        for _, job in ipairs(data.jobs) do
            local isActive = job.name == data.active
            table.insert(elements, {
                label       = job.label .. (isActive and "  *" or ""),
                name        = job.name,
                description = isActive and "Lavoro attualmente attivo" or "Clicca per attivare questo lavoro",
            })
        end

        local menu = exports["v-lib"]:Menu()
        menu.Open(
            "default",
            GetCurrentResourceName(),
            "pk_multijob_menu",
            {
                title    = "I Tuoi Lavori",
                align    = "top-left",
                elements = elements,
            },
            function(selectData, m)
                local selectedJob = selectData.name

                if selectedJob == data.active then
                    Core.NotifyTip("Questo lavoro e gia attivo.", 3000)
                    m.close()
                    return
                end

                Core.Callback.TriggerAsync("pk_multijob:setActiveJob", function(result)
                    if not result then
                        Core.NotifyFail("Multi Job", "Impossibile cambiare lavoro.", 4000)
                    end
                end, selectedJob)

                m.close()
            end,
            function(_, m)
                m.close()
            end
        )
    end)
end
