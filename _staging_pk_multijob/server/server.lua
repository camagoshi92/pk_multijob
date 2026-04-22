local Core = exports.vorp_core:GetCore()

-- ============================================================
--  Utility
-- ============================================================

local function getUserGroup(user)
    if not user then return nil end

    local group = user.getGroup
    if type(group) == "function" then
        local ok, value = pcall(group, user)
        if ok then group = value else group = nil end
    end

    if group == nil or group == "" then
        group = user.group or user.Group
    end

    if group == nil or group == "" then return nil end
    return tostring(group)
end

local function getMaxJobsForSource(source)
    local user = Core.getUser(source)
    if not user then return Config.DefaultMaxJobs end
    local group = getUserGroup(user)
    return Config.MaxJobsByGroup[group] or Config.DefaultMaxJobs
end

local function notify(source, title, subtitle, ntype)
    if not Config.Notifications then return end
    TriggerClientEvent("pk_multijob:client:notify", source, title, subtitle, ntype or "tip")
end

local function normalizeJobEntry(entry, fallbackName)
    if type(entry) == "string" and entry ~= "" then
        return {
            name = entry,
            grade = 0,
            label = entry,
        }
    end

    if type(entry) ~= "table" then
        if fallbackName and fallbackName ~= "" then
            return {
                name = tostring(fallbackName),
                grade = 0,
                label = tostring(fallbackName),
            }
        end
        return nil
    end

    local name = entry.name or entry.job or entry.jobName or fallbackName
    if not name or name == "" then return nil end

    local grade = tonumber(entry.grade or entry.jobGrade or entry.rank or 0) or 0
    local label = entry.label or entry.jobLabel or entry.title or name

    return {
        name = tostring(name),
        grade = grade,
        label = tostring(label),
    }
end

local function normalizeMultiJobs(raw)
    if type(raw) ~= "table" then return {} end

    if raw.name or raw.job or raw.jobName then
        local single = normalizeJobEntry(raw)
        return single and { single } or {}
    end

    local jobs = {}
    local seen = {}
    local indexed = {}
    local mapped = {}

    local function push(entry, fallbackName)
        local job = normalizeJobEntry(entry, fallbackName)
        if not job or seen[job.name] then return end
        seen[job.name] = true
        jobs[#jobs + 1] = job
    end

    for key, value in pairs(raw) do
        local numericKey = tonumber(key)
        if numericKey then
            indexed[#indexed + 1] = { key = numericKey, value = value }
        else
            mapped[#mapped + 1] = { key = tostring(key), value = value }
        end
    end

    table.sort(indexed, function(a, b)
        return a.key < b.key
    end)

    table.sort(mapped, function(a, b)
        return a.key < b.key
    end)

    for _, item in ipairs(indexed) do
        push(item.value)
    end

    for _, item in ipairs(mapped) do
        push(item.value, item.key)
    end

    return jobs
end

-- Legge i multijobs dal DB tramite charIdentifier
local function getMultiJobsFromDB(charIdentifier, cb)
    exports.oxmysql:single(
        "SELECT multijobs FROM characters WHERE charidentifier = ?",
        { charIdentifier },
        function(row)
            if not row then cb({}) return end
            local raw = row.multijobs
            -- oxmysql può restituire JSON già decodificato come tabella Lua
            if type(raw) == "table" then
                cb(normalizeMultiJobs(raw))
                return
            end
            if not raw or raw == "" or raw == "[]" or raw == "{}" then
                cb({})
                return
            end
            local ok, decoded = pcall(json.decode, raw)
            if not ok then
                cb({})
                return
            end
            cb(normalizeMultiJobs(decoded))
        end
    )
end

-- Salva i multijobs nel DB
local function saveMultiJobsToDB(charIdentifier, multiJobs, cb)
    local encoded = json.encode(normalizeMultiJobs(multiJobs))
    exports.oxmysql:execute(
        "UPDATE characters SET multijobs = ? WHERE charidentifier = ?",
        { encoded, charIdentifier },
        function()
            if cb then cb(true) end
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
        local shouldSave = false
        local activeJob = normalizeJobEntry({
            name = character.job,
            grade = character.jobGrade,
            label = character.jobLabel or character.job,
        })

        if #multiJobs == 0 then
            multiJobs = activeJob and { activeJob } or {}
            shouldSave = true
        elseif activeJob then
            local foundActive = false

            for _, job in ipairs(multiJobs) do
                if job.name == activeJob.name then
                    foundActive = true

                    if (tonumber(job.grade or 0) or 0) ~= activeJob.grade then
                        job.grade = activeJob.grade
                        shouldSave = true
                    end

                    if not job.label or job.label == "" then
                        job.label = activeJob.label
                        shouldSave = true
                    end

                    break
                end
            end

            if not foundActive then
                multiJobs[#multiJobs + 1] = activeJob
                shouldSave = true
            end
        end

        if shouldSave then
            saveMultiJobsToDB(character.charIdentifier, multiJobs, nil)
        end

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

        character.setJob(targetJob.name)
        character.setJobGrade(targetJob.grade)
        character.setJobLabel(targetJob.label)
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

            if character.job == jobName then
                local fallback = newJobs[1]
                character.setJob(fallback.name)
                character.setJobGrade(fallback.grade)
                character.setJobLabel(fallback.label)
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
        if getUserGroup(user) ~= "admin" then
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
        if getUserGroup(user) ~= "admin" then
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
                if targetChar.job == jobName then
                    local fallback = newJobs[1]
                    targetChar.setJob(fallback.name)
                    targetChar.setJobGrade(fallback.grade)
                    targetChar.setJobLabel(fallback.label)
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
