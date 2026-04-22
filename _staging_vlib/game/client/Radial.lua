
local PlayerData = {
    job = nil,
    jobLabel = nil,
    jobGrade = nil,
    group = nil
}

CreateThread(function()
    Wait(1000) 
    if GetResourceState("vorp_core") == "started" then
        local VORPCore = exports.vorp_core:GetCore()
        AddEventHandler("vorp_core:Client:OnPlayerSpawned", function()
            local characterJob = LocalPlayer.state.Character.Job
            local characterGroup = LocalPlayer.state.Character.Group or LocalPlayer.state.Character.group
            if characterJob then
                PlayerData = {
                    job = characterJob,
                    jobLabel = characterJob,
                    jobGrade = 0,
                    group = characterGroup
                }
            end
        end)
        RegisterNetEvent("vorp:playerJobChange")
        AddEventHandler("vorp:playerJobChange", function(source, newjob, oldjob)
            PlayerData.job = newjob
            PlayerData.jobLabel = newjob
        end)
        RegisterNetEvent("vorp:playerJobGradeChange")
        AddEventHandler("vorp:playerJobGradeChange", function(source, newjobgrade, oldjobgrade)
            PlayerData.jobGrade = newjobgrade
        end)
        RegisterNetEvent("vorp:playerGroupChange")
        AddEventHandler("vorp:playerGroupChange", function(source, newgroup, oldgroup)
            PlayerData.group = newgroup
        end)
        CreateThread(function()
            while true do
                Wait(1000) 
                if LocalPlayer.state.Character then
                    local currentJob = LocalPlayer.state.Character.Job
                    if currentJob and currentJob ~= PlayerData.job then
                        PlayerData.job = currentJob
                        PlayerData.jobLabel = currentJob
                    end
                    local currentGroup = LocalPlayer.state.Character.Group or LocalPlayer.state.Character.group
                    if currentGroup and currentGroup ~= PlayerData.group then
                        PlayerData.group = currentGroup
                    end
                end
            end
        end)
    elseif GetResourceState("rsg-core") == "started" then
        local RSGCore = exports['rsg-core']:GetCoreObject()
        
        RegisterNetEvent('RSGCore:Client:OnPlayerLoaded')
        AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
            local Player = RSGCore.Functions.GetPlayerData()
            if Player and Player.job then
                PlayerData = {
                    job = Player.job.name,
                    jobLabel = Player.job.label,
                    jobGrade = Player.job.grade.level
                }
            end
        end)
        
        RegisterNetEvent('RSGCore:Player:SetPlayerData')
        AddEventHandler('RSGCore:Player:SetPlayerData', function(val)
            if val and val.job then
                PlayerData = {
                    job = val.job.name,
                    jobLabel = val.job.label,
                    jobGrade = val.job.grade.level
                }
            end
        end)
        
        CreateThread(function()
            Wait(2000)
            local Player = RSGCore.Functions.GetPlayerData()
            if Player and Player.job then
                PlayerData = {
                    job = Player.job.name,
                    jobLabel = Player.job.label,
                    jobGrade = Player.job.grade.level
                }
            end
        end)
    else
        print("^3[V-Lib] ^7Running in standalone mode - job features are disabled!")
    end
end)

local isRadialOpen = false
local currentMenuItems = {}
local lastKeyPress = 0
local KEY_COOLDOWN = 1250
local menuSelectionCooldown = 2000
local MENU_SELECTION_COOLDOWN = 2500 

local function markMenuSelection()
    menuSelectionCooldown = GetGameTimer()
end

local clothingIcons = {
    Hat          = 'fas fa-hat-cowboy',
    Mask         = 'fas fa-mask',
    EyeWear      = 'fas fa-glasses',
    NeckWear     = 'fas fa-circle',
    NeckTies     = 'fas fa-circle',
    Shirt        = 'fas fa-tshirt',
    Vest         = 'fas fa-vest',
    Coat         = 'fa-solid fa-shirt',
    CoatClosed   = 'fa-solid fa-shirt',
    Poncho       = 'fas fa-user-shield',
    Cloak        = 'fas fa-mask',
    Pant         = 'fas fa-socks',
    Boots        = 'fas fa-shoe-prints',
    Spurs        = 'fas fa-star',
    Glove        = 'fas fa-hand-paper',
    Belt         = 'fas fa-circle-notch',
    Gunbelt      = 'fas fa-gun',
    Holster      = 'fas fa-crosshairs',
    Satchels     = 'fas fa-bag-shopping',
    Accessories  = 'fas fa-gem',
    Suspenders   = 'fas fa-grip-lines-vertical',
    Armor        = 'fas fa-shield-alt',
    Badge        = 'fas fa-certificate',
    Gauntlets    = 'fas fa-mitten',
    Bracelet     = 'fas fa-ring',
    RingLh       = 'fas fa-ring',
    RingRh       = 'fas fa-ring',
}

local clothingLabels = {
    Hat          = 'Cappello',
    Mask         = 'Maschera',
    EyeWear      = 'Occhiali',
    NeckWear     = 'Collare',
    NeckTies     = 'Cravatta',
    Shirt        = 'Camicia',
    Vest         = 'Gilet',
    Coat         = 'Giacca',
    CoatClosed   = 'Giacca Chiusa',
    Poncho       = 'Poncho',
    Cloak        = 'Mantello',
    Pant         = 'Pantaloni',
    Boots        = 'Stivali',
    Spurs        = 'Speroni',
    Glove        = 'Guanti',
    Belt         = 'Cintura',
    Gunbelt      = 'Cinturone',
    Holster      = 'Fondina',
    Satchels     = 'Borsa',
    Accessories  = 'Accessori',
    Suspenders   = 'Bretelle',
    Armor        = 'Armatura',
    Badge        = 'Distintivo',
    Gauntlets    = 'Guanti Armati',
    Bracelet     = 'Braccialetto',
    RingLh       = 'Anello Sx',
    RingRh       = 'Anello Dx',
}

local function BuildDynamicClothesItems()
    if GetResourceState('v-appearance') ~= 'started' then return nil end
    local equipped = exports['v-appearance']:GetEquippedCategories()
    if not equipped or #equipped == 0 then return nil end
    local items = {}
    for _, cat in ipairs(equipped) do
        table.insert(items, {
            title = clothingLabels[cat] or cat,
            icon  = clothingIcons[cat] or 'fas fa-tshirt',
            type  = 'command',
            command = string.lower(cat),
        })
    end
    return items
end

local function OpenRadialMenu()
    if isRadialOpen then return end

    local currentTime = GetGameTimer()
    if currentTime - lastKeyPress < KEY_COOLDOWN or currentTime - menuSelectionCooldown < MENU_SELECTION_COOLDOWN then
        return
    end
    lastKeyPress = currentTime

    isRadialOpen = true
    local menuItems = {}

    for _, item in pairs(Config.MenuItems) do
        if type(_) == "number" then
            if item.job and item.job ~= PlayerData.job then
                goto continue
            end
            if item.title == 'Clothes' and item.items then
                local dynamicItems = BuildDynamicClothesItems()
                if dynamicItems then
                    item = {
                        title = item.title,
                        icon  = item.icon,
                        items = dynamicItems,
                    }
                end
            end
            table.insert(menuItems, item)
            ::continue::
        end
    end

    if PlayerData.job and Config.MenuItems[PlayerData.job] then
        for _, item in pairs(Config.MenuItems[PlayerData.job]) do
            table.insert(menuItems, item)
        end
    end

    if PlayerData.group and Config.MenuItems[PlayerData.group] then
        for _, item in pairs(Config.MenuItems[PlayerData.group]) do
            table.insert(menuItems, item)
        end
    elseif not FrameworkLoaded and next(Config.MenuItems) ~= nil then
        for jobName, _ in pairs(Config.MenuItems) do
            if type(jobName) == "string" and jobName ~= "number" then
                print("^3[V-Lib] ^7Warning: Job-specific menu for '" .. jobName .. "' is defined but no framework is loaded!")
            end
        end
    end
    
    currentMenuItems = menuItems
    SendNUIMessage({
        action = "RADIAL",
        items = menuItems
    })
    
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SetCursorLocation(0.5, 0.5)
end

local function CloseRadialMenu()
    if not isRadialOpen then return end
    
    local currentTime = GetGameTimer()
    if currentTime - lastKeyPress < KEY_COOLDOWN then
        return
    end
    lastKeyPress = currentTime

    SendNUIMessage({
        action = "CLOSE_RADIAL"
    })
    
    isRadialOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

RegisterNUICallback('radial:selectItem', function(data, cb)
    markMenuSelection()
    CloseRadialMenu()
    local itemId = tonumber(data.itemId)
    local isSubMenu = data.isSubMenu
    local parentItemIndex = data.parentItemIndex and tonumber(data.parentItemIndex) or nil

    print(string.format("^3[V-Lib Radial] itemId=%s isSubMenu=%s parentItemIndex=%s", tostring(itemId), tostring(isSubMenu), tostring(parentItemIndex)))

    local selectedItem = nil

    if isSubMenu and parentItemIndex then
        local parentItem = currentMenuItems[parentItemIndex + 1]
        if parentItem and parentItem.items and parentItem.items[itemId + 1] then
            selectedItem = parentItem.items[itemId + 1]
        end
    else
        if currentMenuItems[itemId + 1] then
            selectedItem = currentMenuItems[itemId + 1]
        end
    end

    if selectedItem then
        print(string.format("^2[V-Lib Radial] Selezionato: title=%s type=%s command=%s event=%s", tostring(selectedItem.title), tostring(selectedItem.type), tostring(selectedItem.command), tostring(selectedItem.event)))
    else
        print("^1[V-Lib Radial] Nessun item trovato!")
    end

    Wait(800)
    if selectedItem then
        if selectedItem.type == 'client' and selectedItem.event then
            TriggerEvent(selectedItem.event, selectedItem)
        elseif selectedItem.type == 'server' and selectedItem.event then
            TriggerServerEvent(selectedItem.event, selectedItem)
        elseif selectedItem.type == 'command' and selectedItem.command then
            ExecuteCommand(selectedItem.command)
        end
    end
    cb('ok')
end)

RegisterNUICallback('radial:close', function(data, cb)
    isRadialOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    cb('ok')
end)

RegisterNUICallback('executeFavorite', function(data, cb)
    local item = data.item
    local eventType = data.type
    markMenuSelection()
    CloseRadialMenu()
    Wait(800)
    if eventType == 'client' and item.event then
        TriggerEvent(item.event, item)
    elseif eventType == 'server' and item.event then
        TriggerServerEvent(item.event, item)
    elseif item.type == 'command' and item.command then
        ExecuteCommand(item.command)
    end
    
    cb('ok')
end)

RegisterNUICallback('executeCommand', function(data, cb)
    local command = data.command
    
    if command then
        markMenuSelection()
        CloseRadialMenu()
        Wait(1600)
        ExecuteCommand(command)
    end
    cb('ok')
end)


RegisterNUICallback('radial:animationComplete', function(data, cb)
    isRadialOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(0)
          
        if IsControlPressed(0, Config.RadialKey) or IsDisabledControlPressed(0, Config.RadialKey) then
            if not isRadialOpen then
                OpenRadialMenu()
            end
        else
            if isRadialOpen then
                CloseRadialMenu()
                EnableAllControlsAction()
            end
        end
        
        if isRadialOpen then
            DisableControlAction(0, 0x8FFC75D6, true) -- Aim
            DisableControlAction(0, 0xAC4BD4F1, true) -- Attack
            DisableControlAction(0, 0x07CE1E61, true) -- Attack 2
            DisableControlAction(0, 0xA987235F, true) -- Look left/right (mouse)
            DisableControlAction(0, 0xD2047988, true) -- Look up/down (mouse)
            DisableControlAction(0, 0xF84FA74F, true) -- Look Behind
            DisableControlAction(0, 0xDB096B85, true) -- Cover
            DisableControlAction(0, 0xC1989F95, true) -- Select Weapon
            DisableControlAction(0, 0x27568539, true) -- Next Weapon
            DisableControlAction(0, 0xD0842EDF, true) -- Previous Weapon
            DisableControlAction(0, Config.RadialKey, true) -- F4
        end
    end
end)




Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) 
        if LocalPlayer.state.Character then
            local currentJob = LocalPlayer.state.Character.Job
            if currentJob and currentJob ~= PlayerData.job then
                PlayerData.job = currentJob
                PlayerData.jobLabel = currentJob
            end
        end
    end
end)


