local Core = exports.vorp_core:GetCore()

local uiOpen = false
local uiMode = nil
local currentDepartment = nil
local requestId = 0
local pending = {}

local function notify(text)
    if not text or text == "" then return end
    if Core and Core.NotifyRightTip then
        Core.NotifyRightTip(text, 3500)
    else
        print(('[pk_medicarch] %s'):format(text))
    end
end

local function drawText3D(coords, text, scale)
    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z + 1.0)
    if not onScreen then return end
    local str = CreateVarString(10, 'LITERAL_STRING', text)
    SetTextScale(scale, scale)
    SetTextColor(245, 235, 215, 230)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    DisplayText(str, x, y)
end

RegisterNetEvent('pk_medicarch:client:response', function(id, ok, data, err)
    local p = pending[id]
    if not p then return end
    pending[id] = nil
    p:resolve({ ok = ok, data = data, error = err })
end)

RegisterNetEvent('pk_medicarch:client:notify', function(message)
    notify(message)
end)

local function requestServer(action, payload)
    requestId = requestId + 1
    local id = requestId
    local p = promise.new()
    pending[id] = p

    TriggerServerEvent('pk_medicarch:server:request', id, action, payload or {})

    SetTimeout(12000, function()
        if pending[id] then
            pending[id] = nil
            p:resolve({ ok = false, error = 'Request timeout' })
        end
    end)

    local result = Citizen.Await(p)
    return result.ok, result.data, result.error
end

local function closeUi()
    uiOpen = false
    uiMode = nil
    SetNuiFocus(false, false)
    ClearPedTasks(PlayerPedId())
    SendNUIMessage({ action = 'close' })
end

local function playOpenBookAnimation()
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_WRITE_NOTEBOOK'), -1)
    Wait(500)
end

local function openArchive(preferredDepartment)
    local ok, data, err = requestServer('bootstrap', { departmentId = preferredDepartment })
    if not ok then
        notify(err)
        return
    end

    playOpenBookAnimation()

    currentDepartment = data.department and data.department.id or preferredDepartment
    uiOpen = true
    uiMode = 'archive'

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openArchive',
        payload = data,
        locale = (Config.Locale[Config.Language] or Config.Locale.it).ui
    })
end

local function openDocuments()
    local ok, data, err = requestServer('shared_docs', { page = 1 })
    if not ok then
        notify(err)
        return
    end

    uiOpen = true
    uiMode = 'docs'

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openDocs',
        payload = data,
        locale = (Config.Locale[Config.Language] or Config.Locale.it).ui
    })
end

local function openCaseTranscript(payload)
    playOpenBookAnimation()

    uiOpen = true
    uiMode = 'transcript'

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openCaseTranscript',
        payload = payload or {},
        locale = (Config.Locale[Config.Language] or Config.Locale.it).ui
    })
end

RegisterNetEvent('pk_medicarch:client:openDepartment', function(departmentId)
    openArchive(departmentId)
end)

RegisterNetEvent('pk_medicarch:client:openCaseTranscript', function(payload)
    openCaseTranscript(payload)
end)

RegisterCommand(Config.Commands.archive, function()
    openArchive(currentDepartment)
end, false)

if type(RegisterKeyMapping) == 'function' then
    RegisterKeyMapping(Config.Commands.archive, 'Open Medical Archive', 'keyboard', Config.Commands.archiveKey)
else
    print('[pk_medicarch] RegisterKeyMapping non disponibile: usa il comando /' .. Config.Commands.archive)
end

CreateThread(function()
    while true do
        Wait(0)

        if uiOpen then
            Wait(250)
        elseif Config.Text3D.enabled then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearestDepartment = nil
            local nearestDist = 9999.0

            for depId, dep in pairs(Config.Departments) do
                for _, location in ipairs(dep.locations or {}) do
                    local distance = #(coords - location.coords)

                    if distance < Config.DrawDistance then
                        drawText3D(location.coords, Config.Text3D.text, Config.Text3D.scale)
                    end

                    if distance < nearestDist then
                        nearestDist = distance
                        nearestDepartment = depId
                    end
                end
            end

            if nearestDepartment and nearestDist <= Config.OpenDistance and IsControlJustPressed(0, Config.OpenControl) then
                openArchive(nearestDepartment)
                Wait(350)
            end
        else
            Wait(400)
        end
    end
end)

local function nuiForward(action, data, cb)
    if currentDepartment and action ~= 'shared_docs' and action ~= 'shared_doc_detail' then
        data = data or {}
        if not data.departmentId then
            data.departmentId = currentDepartment
        end
    end

    local ok, response, err = requestServer(action, data)
    if ok and response and response.message then
        notify(response.message)
    elseif (not ok) and err then
        notify(err)
    end

    cb({ ok = ok, data = response, error = err })
end

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb({ ok = true })
end)

RegisterNUICallback('patients', function(data, cb)
    nuiForward('patients', data, cb)
end)

RegisterNUICallback('history', function(data, cb)
    nuiForward('history', data, cb)
end)

RegisterNUICallback('forms', function(data, cb)
    nuiForward('forms', data, cb)
end)

RegisterNUICallback('cases', function(data, cb)
    nuiForward('cases', data, cb)
end)

RegisterNUICallback('create_patient', function(data, cb)
    nuiForward('create_patient', data, cb)
end)

RegisterNUICallback('delete_patient', function(data, cb)
    nuiForward('delete_patient', data, cb)
end)

RegisterNUICallback('create_form', function(data, cb)
    nuiForward('create_form', data, cb)
end)

RegisterNUICallback('update_form', function(data, cb)
    nuiForward('update_form', data, cb)
end)

RegisterNUICallback('create_case', function(data, cb)
    nuiForward('create_case', data, cb)
end)

RegisterNUICallback('update_case', function(data, cb)
    nuiForward('update_case', data, cb)
end)

RegisterNUICallback('delete_case', function(data, cb)
    nuiForward('delete_case', data, cb)
end)

RegisterNUICallback('transcribe_case', function(data, cb)
    nuiForward('transcribe_case', data, cb)
end)

RegisterNUICallback('transcribe_form', function(data, cb)
    nuiForward('transcribe_form', data, cb)
end)

RegisterNUICallback('sign_form', function(data, cb)
    nuiForward('sign_form', data, cb)
end)

RegisterNUICallback('delete_form', function(data, cb)
    nuiForward('delete_form', data, cb)
end)

RegisterNUICallback('share_form', function(data, cb)
    nuiForward('share_form', data, cb)
end)

RegisterNUICallback('shared_docs', function(data, cb)
    nuiForward('shared_docs', data, cb)
end)

RegisterNUICallback('shared_doc_detail', function(data, cb)
    nuiForward('shared_doc_detail', data, cb)
end)



