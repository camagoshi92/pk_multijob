local Core = exports.vorp_core:GetCore()

local function notify(text, ntype, title)
    exports["v-lib"]:ShowNotification(text, ntype, 4000, title)
end

-- ============================================================
--  Dispatcher: v-lib registra le callback NUI una sola volta,
--  quindi usiamo variabili mutabili che aggiorniamo ad ogni apertura.
-- ============================================================

local activeSubmit = nil
local activeCancel = nil

local function openVlibMenu(menuData, submitFn, cancelFn)
    activeSubmit = submitFn
    activeCancel = cancelFn

    local menu = exports["v-lib"]:Menu()
    menu.Open(
        "default",
        GetCurrentResourceName(),
        "pk_multijob_menu",
        menuData,
        function(data, m)
            if activeSubmit then activeSubmit(data, m) end
        end,
        function(data, m)
            if activeCancel then activeCancel(data, m) end
        end
    )
end

-- ============================================================
--  Sottomenu singolo job
-- ============================================================

local function openJobDetail(job, data)
    local isActive = job.name == data.active
    local elements = {}

    if not isActive then
        table.insert(elements, {
            label       = "Attiva lavoro",
            name        = "activate",
            description = "Imposta '" .. job.label .. "' come lavoro attivo",
        })
    end

    table.insert(elements, {
        label       = "Rimuovi lavoro",
        name        = "remove",
        description = "Rimuovi '" .. job.label .. "' dalla tua lista",
    })

    table.insert(elements, {
        label       = "Indietro",
        name        = "back",
        description = "Torna alla lista dei lavori",
    })

    openVlibMenu(
        {
            title    = job.label .. (isActive and " *" or ""),
            align    = "top-left",
            elements = elements,
        },
        function(selectData, m)
            local action = selectData.name

            if action == "activate" then
                Core.Callback.TriggerAsync("pk_multijob:setActiveJob", function(result)
                    if not result then
                        notify("Impossibile attivare il lavoro.", "error", "Multi Job")
                    end
                end, job.name)
                m.close()

            elseif action == "remove" then
                Core.Callback.TriggerAsync("pk_multijob:removeJob", function(result)
                    if not result then
                        notify("Impossibile rimuovere il lavoro.", "error", "Multi Job")
                    end
                end, job.name)
                m.close()

            elseif action == "back" then
                m.close()
                CreateThread(openJobMenu)
            end
        end,
        function(_, m)
            m.close()
            CreateThread(openJobMenu)
        end
    )
end

-- ============================================================
--  Menu principale: lista job
-- ============================================================

function openJobMenu()
    Core.Callback.TriggerAsync("pk_multijob:getMyJobs", function(data)
        if not data or type(data.jobs) ~= "table" or #data.jobs == 0 then
            notify("Nessun lavoro assegnato.", "error", "Multi Job")
            return
        end

        local elements = {}
        for _, job in ipairs(data.jobs) do
            local isActive = job.name == data.active
            table.insert(elements, {
                label       = job.label .. (isActive and "  *" or ""),
                name        = job.name,
                description = isActive and "Lavoro attualmente attivo" or "Clicca per gestire questo lavoro",
            })
        end

        openVlibMenu(
            {
                title    = "I Tuoi Lavori",
                align    = "top-left",
                elements = elements,
            },
            function(selectData, m)
                local selectedJob = nil
                for _, job in ipairs(data.jobs) do
                    if job.name == selectData.name then
                        selectedJob = job
                        break
                    end
                end

                m.close()
                if selectedJob then
                    CreateThread(function()
                        openJobDetail(selectedJob, data)
                    end)
                end
            end,
            function(_, m)
                m.close()
            end
        )
    end)
end
