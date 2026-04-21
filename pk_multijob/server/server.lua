local Core = exports.vorp_core:GetCore()

-- ============================================================
--  Utility
-- ============================================================

local function getMaxJobsForSource(source)
    local user = Core.getUser(source)
    if not user then return Config.DefaultMaxJobs end
    local group = user.getGroup
    return Config.MaxJobsByGroup[group] or Config.DefaultMaxJobs
end

local function notify(source, title, subtitle, ntype)
    if not Config.Notifications then return end
    TriggerClientEvent("pk_multijob:client:notify", source, title, subtitle, ntype or "tip")
end

-- Legge i multijobs dal DB tramite charIdentifier
local function getMultiJobsFromDB(charIdentifier, cb)
    exports.oxmysql:single(
        "SELECT multijobs FROM characters WHERE charidentifier = ?",
        { charIdentifier },
        function(row)
            if not row then cb({}) return end
            local raw = row.multijobs
            if not raw or raw == "" or raw == "[]" or raw == "{}" then
                cb({})
                return
            end
            local decoded = json.decode(raw)
            cb(decoded or {})
        end
    )
end

-- Salva i multijobs nel DB
local function saveMultiJobsToDB(charIdentifier, multiJobs, cb)
    local encoded = json.encode(multiJobs)
    exports.oxmysql:execute(
        "UPDATE characters SET multijobs = ? WHERE charidentifier = ?",
        { encoded, charIdentifier },
        function(rowsChanged)
            if cb then cb(rowsChanged and rowsChanged > 0) end
        end
    )
end

-- ============================================================
--  Callback: ottieni tutti i job del personaggio
-- ============================================================

Core.Callback.Register("pk_multijob:getMyJobs", function(source, callback)
    local user = Core.getUser(source)
    if not user then callback(nil) return end

    local character = user.getUsedCharacter
    if not character then callback(nil) return end

    local maxJobs = getMaxJobsForSource(source)

    getMultiJobsFromDB(character.charIdentifier, function(multiJobs)
        callback({
            jobs    = multiJobs,
            active  = character.job,
            grade   = character.jobGrade,
            maxJobs = maxJobs,
        })
    end)
end)

-- ============================================================
--  Callback: cambia job attivo
-- ============================================================

Core.Callback.Register("pk_multijob:setActiveJob", function(source, callback, jobName)
    local user = Core.getUser(source)
    if not user then callback(false) return end

    local character = user.getUsedCharacter
    if not character then callback(false) return end

    getMultiJobsFromDB(character.charIdentifier, function(multiJobs)
        local targetJob = nil
        for _, j in ipairs(multiJobs) do
            if j.name == jobName then
                targetJob = j
                break
            end
        end

        if not targetJob then
            notify(source, "Multi Job", "Non hai questo lavoro assegnato.", "fail")
            callback(false)
            return
        end

        TriggerEvent("vorp:setJob", source, targetJob.name, targetJob.grade)
        notify(source, "Multi Job", "Lavoro attivo: " .. targetJob.label, "update")
        callback(true)
    end)
end)

-- ============================================================
--  Callback: aggiungi job
-- ============================================================

Core.Callback.Register("pk_multijob:addJob", function(source, callback, jobName, jobGrade, jobLabel)
    local user = Core.getUser(source)
    if not user then callback(false) return end

    local character = user.getUsedCharacter
    if not character then callback(false) return end

    local maxJobs = getMaxJobsForSource(source)

    getMultiJobsFromDB(character.charIdentifier, function(multiJobs)
        for _, j in ipairs(multiJobs) do
            if j.name == jobName then
                notify(source, "Multi Job", "Hai già questo lavoro.", "fail")
                callback(false)
                return
            end
        end

        if #multiJobs >= maxJobs then
            notify(source, "Multi Job", "Limite massimo raggiunto (" .. maxJobs .. ").", "fail")
            callback(false)
            return
        end

        table.insert(multiJobs, {
            name  = jobName,
            grade = jobGrade or 0,
            label = jobLabel or jobName,
        })

        saveMultiJobsToDB(character.charIdentifier, multiJobs, function(success)
            if success then
                TriggerEvent("vorp:setMultiJob", source, multiJobs)
                notify(source, "Multi Job", "Lavoro aggiunto: " .. (jobLabel or jobName), "update")
                callback(true)
            else
                notify(source, "Multi Job", "Errore nel salvataggio.", "fail")
                callback(false)
            end
        end)
    end)
end)

-- ============================================================
--  Callback: rimuovi job
-- ============================================================

Core.Callback.Register("pk_multijob:removeJob", function(source, callback, jobName)
    local user = Core.getUser(source)
    if not user then callback(false) return end

    local character = user.getUsedCharacter
    if not character then callback(false) return end

    getMultiJobsFromDB(character.charIdentifier, function(multiJobs)
        if #multiJobs <= 1 then
            notify(source, "Multi Job", "Non puoi rimuovere l'unico lavoro.", "fail")
            callback(false)
            return
        end

        local newJobs = {}
        local removed = false

        for _, j in ipairs(multiJobs) do
            if j.name ~= jobName then
                table.insert(newJobs, j)
            else
                removed = true
            end
        end

        if not removed then
            notify(source, "Multi Job", "Lavoro non trovato.", "fail")
            callback(false)
            return
        end

        saveMultiJobsToDB(character.charIdentifier, newJobs, function(success)
            if not success then
                notify(source, "Multi Job", "Errore nel salvataggio.", "fail")
                callback(false)
                return
            end

            TriggerEvent("vorp:setMultiJob", source, newJobs)

            if character.job == jobName then
                local fallback = newJobs[1]
                TriggerEvent("vorp:setJob", source, fallback.name, fallback.grade)
                notify(source, "Multi Job", "Nuovo lavoro attivo: " .. fallback.label, "update")
            end

            notify(source, "Multi Job", "Lavoro rimosso: " .. jobName, "update")
            callback(true)
        end)
    end)
end)

-- ============================================================
--  Comando: /addJob [id] [jobName] [grade] [label]
-- ============================================================

RegisterCommand("addJob", function(source, args)
    local user = Core.getUser(source)
    if source ~= 0 then
        if not user then return end
        if user.getGroup ~= "admin" then
            notify(source, "Multi Job", "Permessi insufficienti.", "fail")
            return
        end
    end

    local targetId = tonumber(args[1])
    local jobName  = args[2]
    local grade    = tonumber(args[3]) or 0
    local label    = args[4] or jobName

    if not targetId or not jobName then
        print("[pk_multijob] Uso: /addJob [id] [jobName] [grade] [label]")
        return
    end

    local targetUser = Core.getUser(targetId)
    if not targetUser then
        print("[pk_multijob] Player " .. targetId .. " non trovato.")
        return
    end

    local targetChar = targetUser.getUsedCharacter
    if not targetChar then
        print("[pk_multijob] Personaggio del player " .. targetId .. " non trovato.")
        return
    end

    local maxJobs = getMaxJobsForSource(targetId)

    getMultiJobsFromDB(targetChar.charIdentifier, function(multiJobs)
        for _, j in ipairs(multiJobs) do
            if j.name == jobName then
                print("[pk_multijob] Il player " .. targetId .. " ha già il job '" .. jobName .. "'.")
                if source ~= 0 then
                    notify(source, "Multi Job", "Il player ha già questo lavoro.", "fail")
                end
                return
            end
        end

        if #multiJobs >= maxJobs then
            print("[pk_multijob] Il player " .. targetId .. " ha raggiunto il limite job.")
            if source ~= 0 then
                notify(source, "Multi Job", "Limite massimo raggiunto per questo player.", "fail")
            end
            return
        end

        table.insert(multiJobs, {
            name  = jobName,
            grade = grade,
            label = label,
        })

        saveMultiJobsToDB(targetChar.charIdentifier, multiJobs, function(success)
            if success then
                TriggerEvent("vorp:setMultiJob", targetId, multiJobs)
                notify(targetId, "Multi Job", "Ti è stato assegnato il lavoro: " .. label, "update")
                if source ~= 0 then
                    notify(source, "Multi Job", "Job assegnato con successo.", "update")
                end
                print(("[pk_multijob] Job '%s' assegnato al player %s (char: %s)"):format(jobName, targetId, targetChar.charIdentifier))
            else
                print("[pk_multijob] Errore nel salvataggio DB.")
            end
        end)
    end)
end, false)

-- ============================================================
--  Comando: /removeJob [id] [jobName]
-- ============================================================

RegisterCommand("removeJob", function(source, args)
    local user = Core.getUser(source)
    if source ~= 0 then
        if not user then return end
        if user.getGroup ~= "admin" then
            notify(source, "Multi Job", "Permessi insufficienti.", "fail")
            return
        end
    end

    local targetId = tonumber(args[1])
    local jobName  = args[2]

    if not targetId or not jobName then
        print("[pk_multijob] Uso: /removeJob [id] [jobName]")
        return
    end

    local targetUser = Core.getUser(targetId)
    if not targetUser then
        print("[pk_multijob] Player " .. targetId .. " non trovato.")
        return
    end

    local targetChar = targetUser.getUsedCharacter
    if not targetChar then return end

    getMultiJobsFromDB(targetChar.charIdentifier, function(multiJobs)
        if #multiJobs <= 1 then
            print("[pk_multijob] Impossibile rimuovere l'unico job.")
            return
        end

        local newJobs = {}
        local removed = false
        for _, j in ipairs(multiJobs) do
            if j.name ~= jobName then
                table.insert(newJobs, j)
            else
                removed = true
            end
        end

        if not removed then
            print("[pk_multijob] Job '" .. jobName .. "' non trovato per il player " .. targetId)
            return
        end

        saveMultiJobsToDB(targetChar.charIdentifier, newJobs, function(success)
            if success then
                TriggerEvent("vorp:setMultiJob", targetId, newJobs)

                if targetChar.job == jobName then
                    local fallback = newJobs[1]
                    TriggerEvent("vorp:setJob", targetId, fallback.name, fallback.grade)
                    notify(targetId, "Multi Job", "Nuovo lavoro attivo: " .. fallback.label, "update")
                end

                notify(targetId, "Multi Job", "Lavoro rimosso: " .. jobName, "update")
                if source ~= 0 then
                    notify(source, "Multi Job", "Job rimosso con successo.", "update")
                end
                print(("[pk_multijob] Job '%s' rimosso dal player %s"):format(jobName, targetId))
            end
        end)
    end)
end, false)

-- ============================================================
--  Log cambio job
-- ============================================================

AddEventHandler("vorp:playerJobChange", function(source, job, grade)
    print(("[pk_multijob] Player %s -> job: %s grade: %s"):format(source, job, grade))
end)
