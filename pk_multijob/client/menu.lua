local Core = exports.vorp_core:GetCore()
local MenuData = {}

local function isMenuDataReady()
    return MenuData
        and type(MenuData.Open) == "function"
        and type(MenuData.CloseAll) == "function"
end

local function fetchMenuData()
    if isMenuDataReady() then
        return true
    end

    if GetResourceState("tpz_menu_base") ~= "started" then
        return false
    end

    local ok, exportedMenuData = pcall(function()
        return exports.tpz_menu_base:GetMenuData()
    end)

    if ok and exportedMenuData then
        MenuData = exportedMenuData
    end

    if isMenuDataReady() then
        return true
    end

    TriggerEvent("tpz_menu_base:getData", function(call)
        if call then
            MenuData = call
        end
    end)

    return isMenuDataReady()
end

local function ensureMenuData(timeoutMs)
    local timeoutAt = GetGameTimer() + (timeoutMs or 2000)

    repeat
        if fetchMenuData() then
            return true
        end

        Wait(100)
    until GetGameTimer() >= timeoutAt

    return isMenuDataReady()
end

CreateThread(function()
    ensureMenuData(5000)
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= "tpz_menu_base" and resourceName ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        Wait(250)
        ensureMenuData(5000)
    end)
end)

-- ============================================================
--  Apri menu switch job
-- ============================================================

function openJobMenu()
    if not ensureMenuData(1500) then
        Core.NotifyFail("Multi Job", "tpz_menu_base non pronto.", 4000)
        return
    end

    Core.Callback.TriggerAsync("pk_multijob:getMyJobs", function(data)
        if not data or type(data.jobs) ~= "table" or #data.jobs == 0 then
            Core.NotifyFail("Multi Job", "Nessun lavoro assegnato.", 4000)
            return
        end

        local elements = {}

        for _, job in ipairs(data.jobs) do
            local isActive = job.name == data.active
            table.insert(elements, {
                label = job.label .. (isActive and "  *" or ""),
                value = job.name,
                desc = isActive and "Lavoro attualmente attivo" or "Clicca per attivare questo lavoro",
            })
        end

        MenuData.CloseAll()
        MenuData.Open(
            "default",
            GetCurrentResourceName(),
            "pk_multijob_menu",
            {
                title = "I Tuoi Lavori",
                subtext = "Attivo: " .. data.active .. "  |  Slot: " .. #data.jobs .. "/" .. data.maxJobs,
                align = "top-left",
                elements = elements,
            },
            function(selectData, menu)
                local selectedJob = selectData.current.value

                if selectedJob == data.active then
                    Core.NotifyTip("Questo lavoro e gia attivo.", 3000)
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
            function(_, menu)
                menu.close()
            end
        )
    end)
end

-- ============================================================
--  Forza chiusura menu se player muore
-- ============================================================

AddEventHandler("tpz_menu_base:onForcedClosed", function()
    if isMenuDataReady() then
        MenuData.CloseAll()
    end
end)
