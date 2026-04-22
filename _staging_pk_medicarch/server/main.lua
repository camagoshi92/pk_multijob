
local Core = exports.vorp_core:GetCore()
local PER_PAGE = tonumber(Config.PaginationSize) or 10
local RES = GetCurrentResourceName()
local INVENTORY_RES = "vorp_inventory"
local registeredUsableItems = {}

local function L(path, ...)
    local node = Config.Locale[Config.Language] or Config.Locale.it or {}
    for k in string.gmatch(path, "[^%.]+") do node = node and node[k] end
    if type(node) ~= "string" then return path end
    if select("#", ...) > 0 then
        local ok, out = pcall(string.format, node, ...)
        if ok then return out end
    end
    return node
end

local function sanitize(v, max)
    local t = tostring(v or ""):gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if max and #t > max then t = t:sub(1, max) end
    return t
end

local function isTruthyFlag(value)
    if value == true then return true end
    if value == false or value == nil then return false end
    local numeric = tonumber(value)
    if numeric ~= nil then return numeric == 1 end
    local text = string.lower(tostring(value or ""))
    return text == "true" or text == "yes" or text == "on"
end

local function copyTable(value)
    local out = {}
    if type(value) ~= "table" then return out end
    for k, v in pairs(value) do out[k] = v end
    return out
end

local function decodeMetadata(value)
    if type(value) == "table" then return value end
    if type(value) == "string" and value ~= "" then
        local ok, decoded = pcall(json.decode, value)
        if ok and type(decoded) == "table" then return decoded end
    end
    return {}
end

local function lower(v) return string.lower(tostring(v or "")) end
local function reply(src, id, ok, data, err) TriggerClientEvent("pk_medicarch:client:response", src, id, ok, data, err) end

local function getIdentity(src)
    local user = Core.getUser(src)
    if not user then return nil end
    local c = user.getUsedCharacter
    if type(c) == "function" then c = c() end
    if type(c) ~= "table" then return nil end
    local identifier = c.identifier
    if (not identifier or identifier == "") and user and type(user.getIdentifier) == "function" then identifier = user.getIdentifier() end
    return {
        identifier = tostring(identifier or ""),
        charId = tonumber(c.charIdentifier or c.charidentifier),
        firstname = sanitize(c.firstname or c.FirstName or "", 64),
        lastname = sanitize(c.lastname or c.LastName or "", 64),
        job = tostring(c.job or c.Job or ""),
        grade = tonumber(c.jobgrade or c.jobGrade or c.Grade or 0) or 0,
        multiJobs = c.multiJobs or c.multijobs
    }
end

local function getSourceByCharId(charId)
    local targetCharId = tonumber(charId)
    if not targetCharId then return nil, nil end

    for _, playerSrc in ipairs(GetPlayers()) do
        local src = tonumber(playerSrc)
        if src then
            local identity = getIdentity(src)
            if identity and tonumber(identity.charId) == targetCharId then
                return src, identity
            end
        end
    end

    return nil, nil
end

local function decodeMulti(m)
    if type(m) == "table" then return m end
    if type(m) == "string" and m ~= "" then
        local ok, d = pcall(json.decode, m)
        if ok and type(d) == "table" then return d end
    end
    return {}
end

local function hasDepartmentAccess(identity, departmentId)
    local dep = Config.Departments[departmentId]
    if not dep then return false, nil end
    local function check(job, grade)
        for _, r in ipairs(dep.jobs or {}) do
            if lower(r.name) == lower(job) then return tonumber(grade or 0) >= tonumber(r.minGrade or 0) end
        end
        return false
    end
    if check(identity.job, identity.grade) then return true, dep end
    for j, d in pairs(decodeMulti(identity.multiJobs)) do
        if check(j, d and d.grade or 0) then return true, dep end
    end
    return false, dep
end

local function getDepartment(identity, preferred)
    if preferred and preferred ~= "" then
        local ok, dep = hasDepartmentAccess(identity, preferred)
        if ok then return preferred, dep end
        if dep then return nil, nil, L("notify.no_access") end
        return nil, nil, L("notify.no_department")
    end
    for id, dep in pairs(Config.Departments) do
        local ok = hasDepartmentAccess(identity, id)
        if ok then return id, dep end
    end
    return nil, nil, L("notify.no_access")
end

local function paginate(total, page)
    local p = math.max(1, tonumber(page or 1) or 1)
    local tp = math.max(1, math.ceil((tonumber(total) or 0) / PER_PAGE))
    if p > tp then p = tp end
    return { page = p, totalPages = tp, perPage = PER_PAGE, total = tonumber(total) or 0, offset = (p - 1) * PER_PAGE }
end

local function parseDisplayDate(value)
    if value == nil or value == "" then return nil end

    local raw = tostring(value)
    local numeric = tonumber(raw)
    if numeric then
        if numeric > 99999999999 then numeric = math.floor(numeric / 1000) end
        local dt = os.date("*t", numeric)
        if dt then
            return {
                year = tonumber(dt.year) or 0,
                month = tonumber(dt.month) or 1,
                day = tonumber(dt.day) or 1,
                hour = tonumber(dt.hour) or 0,
                min = tonumber(dt.min) or 0,
                sec = tonumber(dt.sec) or 0
            }
        end
    end

    local y, m, d, hh, mm, ss = raw:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)[ T](%d%d):(%d%d):(%d%d)$")
    if y then
        return {
            year = tonumber(y) or 0,
            month = tonumber(m) or 1,
            day = tonumber(d) or 1,
            hour = tonumber(hh) or 0,
            min = tonumber(mm) or 0,
            sec = tonumber(ss) or 0
        }
    end

    y, m, d = raw:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if y then
        return {
            year = tonumber(y) or 0,
            month = tonumber(m) or 1,
            day = tonumber(d) or 1,
            hour = 0,
            min = 0,
            sec = 0
        }
    end

    return nil
end

local function formatDisplayDate(value)
    if value == nil or value == "" then return "" end

    local cfg = Config.DateDisplay or {}
    local parts = parseDisplayDate(value)
    if not parts then return tostring(value) end

    local year = tonumber(cfg.serverYear) or tonumber(parts.year) or 0

    local tokens = {
        ["%d"] = ("%02d"):format(tonumber(parts.day) or 0),
        ["%m"] = ("%02d"):format(tonumber(parts.month) or 0),
        ["%Y"] = tostring(year),
        ["%y"] = ("%02d"):format(math.abs(year) % 100),
        ["%H"] = ("%02d"):format(tonumber(parts.hour) or 0),
        ["%M"] = ("%02d"):format(tonumber(parts.min) or 0),
        ["%S"] = ("%02d"):format(tonumber(parts.sec) or 0)
    }

    local fmt = tostring(cfg.format or "%d/%m/%Y %H:%M")
    return (fmt:gsub("(%%[dmyYHMS])", tokens))
end

local function formatDateFields(entry, fields)
    if type(entry) ~= "table" then return entry end
    for _, key in ipairs(fields or {}) do
        if entry[key] ~= nil and entry[key] ~= "" then
            entry[key] = formatDisplayDate(entry[key])
        end
    end
    return entry
end

local function formatDateFieldsInRows(rows, fields)
    for _, row in ipairs(rows or {}) do
        formatDateFields(row, fields)
    end
    return rows
end

local function webhook(depId, key, title, fields)
    local dep = Config.Departments[depId]
    local url = dep and dep.webhooks and dep.webhooks[key]
    if not url or url == "" then return end
    local f = {}
    for _, it in ipairs(fields or {}) do f[#f + 1] = { name = tostring(it.name), value = tostring(it.value), inline = it.inline == true } end
    local payload = { username = "pk_medicarch", embeds = { { title = title, color = 15158332, fields = f, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") } } }
    PerformHttpRequest(url, function() end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

local function createTables()
    MySQL.query.await("CREATE TABLE IF NOT EXISTS `pk_medicarch_sequences` (`department_id` VARCHAR(64) NOT NULL, `last_number` INT NOT NULL DEFAULT 0, PRIMARY KEY (`department_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")
    MySQL.query.await("CREATE TABLE IF NOT EXISTS `pk_medicarch_patients` (`id` INT NOT NULL AUTO_INCREMENT,`department_id` VARCHAR(64) NOT NULL,`patient_code` VARCHAR(64) NOT NULL,`identifier` VARCHAR(80) DEFAULT NULL,`charidentifier` INT DEFAULT NULL,`firstname` VARCHAR(80) NOT NULL,`lastname` VARCHAR(80) NOT NULL,`dob` VARCHAR(30) DEFAULT NULL,`notes` TEXT DEFAULT NULL,`created_by_charidentifier` INT DEFAULT NULL,`created_by_name` VARCHAR(120) DEFAULT NULL,`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`deleted_at` TIMESTAMP NULL DEFAULT NULL,PRIMARY KEY (`id`),UNIQUE KEY `uk_department_patient_code` (`department_id`,`patient_code`),KEY `idx_department_deleted` (`department_id`,`deleted_at`),KEY `idx_char_department` (`charidentifier`,`department_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")
    MySQL.query.await("CREATE TABLE IF NOT EXISTS `pk_medicarch_records` (`id` INT NOT NULL AUTO_INCREMENT,`department_id` VARCHAR(64) NOT NULL,`patient_id` INT NOT NULL,`record_type` VARCHAR(64) NOT NULL DEFAULT 'treatment',`reason` VARCHAR(255) NOT NULL,`details` TEXT DEFAULT NULL,`provider_charidentifier` INT DEFAULT NULL,`provider_name` VARCHAR(120) DEFAULT NULL,`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`deleted_at` TIMESTAMP NULL DEFAULT NULL,PRIMARY KEY (`id`),KEY `idx_department_patient` (`department_id`,`patient_id`),KEY `idx_created_at` (`created_at`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")
    MySQL.query.await("CREATE TABLE IF NOT EXISTS `pk_medicarch_forms` (`id` INT NOT NULL AUTO_INCREMENT,`department_id` VARCHAR(64) NOT NULL,`template_key` VARCHAR(80) NOT NULL,`title` VARCHAR(150) NOT NULL,`patient_id` INT NOT NULL,`patient_code` VARCHAR(64) NOT NULL,`patient_name` VARCHAR(160) NOT NULL,`description` TEXT DEFAULT NULL,`shareable` TINYINT(1) NOT NULL DEFAULT 0,`created_by_charidentifier` INT DEFAULT NULL,`created_by_name` VARCHAR(120) DEFAULT NULL,`signed` TINYINT(1) NOT NULL DEFAULT 0,`signed_by_charidentifier` INT DEFAULT NULL,`signed_by_name` VARCHAR(120) DEFAULT NULL,`signed_at` TIMESTAMP NULL DEFAULT NULL,`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`deleted_at` TIMESTAMP NULL DEFAULT NULL,PRIMARY KEY (`id`),KEY `idx_department_patient` (`department_id`,`patient_id`),KEY `idx_signed` (`signed`,`deleted_at`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")
    MySQL.query.await("CREATE TABLE IF NOT EXISTS `pk_medicarch_shared_forms` (`id` INT NOT NULL AUTO_INCREMENT,`form_id` INT NOT NULL,`owner_charidentifier` INT NOT NULL,`shared_by_charidentifier` INT DEFAULT NULL,`shared_by_name` VARCHAR(120) DEFAULT NULL,`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`viewed_at` TIMESTAMP NULL DEFAULT NULL,`deleted_at` TIMESTAMP NULL DEFAULT NULL,PRIMARY KEY (`id`),UNIQUE KEY `uk_form_owner` (`form_id`,`owner_charidentifier`),KEY `idx_owner_deleted` (`owner_charidentifier`,`deleted_at`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")
    MySQL.query.await("CREATE TABLE IF NOT EXISTS `pk_medicarch_cases` (`id` INT NOT NULL AUTO_INCREMENT,`department_id` VARCHAR(64) NOT NULL,`title` VARCHAR(150) NOT NULL,`description` TEXT DEFAULT NULL,`created_by_charidentifier` INT DEFAULT NULL,`created_by_name` VARCHAR(120) DEFAULT NULL,`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,`deleted_at` TIMESTAMP NULL DEFAULT NULL,PRIMARY KEY (`id`),KEY `idx_department_deleted` (`department_id`,`deleted_at`),KEY `idx_department_updated` (`department_id`,`updated_at`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")
end

local function inventoryReady()
    return GetResourceState(INVENTORY_RES) == "started"
end

local function registerUsableInventoryItem(itemName, handler)
    local item = sanitize(itemName, 128)
    if item == "" or registeredUsableItems[item] then return true end
    local ok, err = pcall(function()
        exports.vorp_inventory:registerUsableItem(item, handler, RES)
    end)
    if not ok then
        print(("[%s] failed to register usable item %s: %s"):format(RES, item, tostring(err)))
        return false
    end
    registeredUsableItems[item] = true
    return true
end

local function inventoryAwait(invoke, fallback)
    local p = promise.new()
    local settled = false
    local function resolve(value)
        if settled then return end
        settled = true
        p:resolve(value)
    end
    SetTimeout(2000, function() resolve(fallback) end)
    local ok = pcall(invoke, resolve)
    if not ok then return fallback end
    return Citizen.Await(p)
end

local function inventoryGetUserItems(src)
    if not inventoryReady() then return {} end
    local items = inventoryAwait(function(resolve)
        local result = exports.vorp_inventory:getUserInventoryItems(src, function(result)
            resolve(result)
        end)
        if type(result) == "table" then resolve(result) end
    end, {})
    return type(items) == "table" and items or {}
end

local function inventoryGetItemById(src, itemId)
    if not inventoryReady() or not itemId then return nil end
    local item = inventoryAwait(function(resolve)
        local result = exports.vorp_inventory:getItemById(src, itemId, function(result)
            resolve(result)
        end)
        if type(result) == "table" then resolve(result) end
    end, nil)
    return type(item) == "table" and item or nil
end

local function inventorySetItemMetadata(src, itemId, metadata, amount)
    if not inventoryReady() or not itemId then return false end
    local result = inventoryAwait(function(resolve)
        local direct = exports.vorp_inventory:setItemMetadata(src, itemId, metadata, amount or 1, function(success)
            resolve(success)
        end)
        if direct ~= nil then resolve(direct) end
    end, false)
    return result ~= false
end

local function normalizeUsableData(callbackData, callbackUseData)
    if type(callbackData) == "table" then
        local callbackSource = tonumber(callbackData.source or callbackData.player or callbackData._source)
        return callbackSource, callbackData
    end

    local callbackSource = tonumber(callbackData)
    if not callbackSource then
        return nil, nil
    end

    if type(callbackUseData) == "table" then
        callbackUseData.source = callbackUseData.source or callbackSource
        return callbackSource, callbackUseData
    end

    return callbackSource, { source = callbackSource }
end

local function usableItemId(useData)
    if type(useData) ~= "table" then return nil end
    local item = useData.item
    if type(item) == "table" then
        return tonumber(item.id or item.itemId)
    end
    return tonumber(useData.id or useData.itemId)
end

local function usableItemMetadata(useData)
    if type(useData) ~= "table" then return {} end
    if type(useData.item) == "table" then
        local metadata = decodeMetadata(useData.item.metadata or useData.item.meta or useData.item.itemMetadata)
        if next(metadata) then return metadata end
    end
    return decodeMetadata(useData.metadata or useData.meta or useData.itemMetadata)
end

local function isCaseTranscriptMetadata(metadata)
    local md = decodeMetadata(metadata)
    local kind = lower(md.pk_medicarch_type or md.pk_type or "")
    return kind == "case_transcript" or md.pk_case_transcript == true or tonumber(md.pk_case_transcript or 0) == 1
end

local function isFormTranscriptMetadata(metadata)
    local md = decodeMetadata(metadata)
    local kind = lower(md.pk_medicarch_type or md.pk_type or "")
    return kind == "form_transcript" or md.pk_form_transcript == true or tonumber(md.pk_form_transcript or 0) == 1
end

local function isTranscriptMetadata(metadata)
    return isCaseTranscriptMetadata(metadata) or isFormTranscriptMetadata(metadata)
end

local function buildCaseTranscriptPayload(metadata)
    local md = decodeMetadata(metadata)
    return {
        kind = "case",
        sheetTitle = L("ui.case_transcript"),
        caseId = tonumber(md.pk_case_id),
        departmentId = tostring(md.pk_case_department or ""),
        departmentLabel = tostring(md.pk_case_department_label or ""),
        title = tostring(md.pk_case_title or ""),
        body = tostring(md.pk_case_body or ""),
        createdBy = tostring(md.pk_case_created_by or ""),
        createdAt = formatDisplayDate(md.pk_case_created_at or ""),
        updatedAt = formatDisplayDate(md.pk_case_updated_at or ""),
        transcribedBy = tostring(md.pk_case_transcribed_by or ""),
        transcribedAt = formatDisplayDate(md.pk_case_transcribed_at or "")
    }
end

local function buildFormTranscriptPayload(metadata)
    local md = decodeMetadata(metadata)
    local signed = isTruthyFlag(md.pk_form_signed)
    return {
        kind = "form",
        sheetTitle = L("ui.form_transcript"),
        formId = tonumber(md.pk_form_id),
        departmentId = tostring(md.pk_form_department or ""),
        departmentLabel = tostring(md.pk_form_department_label or ""),
        title = tostring(md.pk_form_title or ""),
        body = tostring(md.pk_form_body or ""),
        templateKey = tostring(md.pk_form_template or ""),
        patientCode = tostring(md.pk_form_patient_code or ""),
        patientName = tostring(md.pk_form_patient_name or ""),
        createdBy = tostring(md.pk_form_created_by or ""),
        createdAt = formatDisplayDate(md.pk_form_created_at or ""),
        signed = signed,
        signedBy = tostring(md.pk_form_signed_by or ""),
        signedAt = formatDisplayDate(md.pk_form_signed_at or ""),
        transcribedBy = tostring(md.pk_form_transcribed_by or ""),
        transcribedAt = formatDisplayDate(md.pk_form_transcribed_at or "")
    }
end

local function buildCaseTranscriptMetadata(baseMetadata, depId, depLabel, caseRow, transcribedBy, transcribedAt)
    local metadata = copyTable(decodeMetadata(baseMetadata))
    metadata.label = sanitize(caseRow.title or L("ui.case_transcript"), 150)
    metadata.description = sanitize(("%s | %s"):format(depLabel or depId or "", transcribedBy or ""), 255)
    metadata.pk_medicarch_type = "case_transcript"
    metadata.pk_case_transcript = true
    metadata.pk_case_id = tonumber(caseRow.id)
    metadata.pk_case_department = tostring(depId or "")
    metadata.pk_case_department_label = tostring(depLabel or depId or "")
    metadata.pk_case_title = sanitize(caseRow.title or "", 150)
    metadata.pk_case_body = tostring(caseRow.description or "")
    metadata.pk_case_created_by = sanitize(caseRow.created_by_name or "", 120)
    metadata.pk_case_created_at = formatDisplayDate(caseRow.created_at or "")
    metadata.pk_case_updated_at = formatDisplayDate(caseRow.updated_at or "")
    metadata.pk_case_transcribed_by = sanitize(transcribedBy or "", 120)
    metadata.pk_case_transcribed_at = formatDisplayDate(transcribedAt or "")
    return metadata
end

local function buildFormTranscriptMetadata(baseMetadata, depId, depLabel, formRow, transcribedBy, transcribedAt)
    local metadata = copyTable(decodeMetadata(baseMetadata))
    metadata.label = sanitize(formRow.title or L("ui.form_transcript"), 150)
    metadata.description = sanitize(("%s | %s"):format(formRow.patient_code or depLabel or depId or "", transcribedBy or ""), 255)
    metadata.pk_medicarch_type = "form_transcript"
    metadata.pk_form_transcript = true
    metadata.pk_form_id = tonumber(formRow.id)
    metadata.pk_form_department = tostring(depId or "")
    metadata.pk_form_department_label = tostring(depLabel or depId or "")
    metadata.pk_form_title = sanitize(formRow.title or "", 150)
    metadata.pk_form_body = tostring(formRow.description or "")
    metadata.pk_form_template = sanitize(formRow.template_key or "", 80)
    metadata.pk_form_patient_code = sanitize(formRow.patient_code or "", 64)
    metadata.pk_form_patient_name = sanitize(formRow.patient_name or "", 160)
    metadata.pk_form_created_by = sanitize(formRow.created_by_name or "", 120)
    metadata.pk_form_created_at = formatDisplayDate(formRow.created_at or "")
    metadata.pk_form_signed = isTruthyFlag(formRow.signed) and 1 or 0
    metadata.pk_form_signed_by = sanitize(formRow.signed_by_name or "", 120)
    metadata.pk_form_signed_at = formatDisplayDate(formRow.signed_at or "")
    metadata.pk_form_transcribed_by = sanitize(transcribedBy or "", 120)
    metadata.pk_form_transcribed_at = formatDisplayDate(transcribedAt or "")
    return metadata
end

local function findBlankTranscriptSheet(src, itemName)
    local wanted = lower(itemName)
    for _, item in pairs(inventoryGetUserItems(src) or {}) do
        local currentName = lower(item and (item.name or item.item or item.itemName) or "")
        local currentId = tonumber(item and (item.id or item.itemId))
        if currentName == wanted and currentId then
            local metadata = decodeMetadata(item.metadata or item.meta or item.itemMetadata)
            if not isTranscriptMetadata(metadata) then
                return { id = currentId, metadata = metadata }
            end
        end
    end
    return nil
end

local function registerTranscriptItems()
    if not inventoryReady() then
        print(("[%s] vorp_inventory not started."):format(RES))
        return
    end
    local items = {}
    if Config.CaseTranscriptions and Config.CaseTranscriptions.enabled then
        local caseItem = sanitize(Config.CaseTranscriptions.item, 128)
        if caseItem ~= "" then items[caseItem] = true end
    end
    if Config.FormTranscriptions and Config.FormTranscriptions.enabled then
        local formItem = sanitize(Config.FormTranscriptions.item or (Config.CaseTranscriptions and Config.CaseTranscriptions.item) or "", 128)
        if formItem ~= "" then items[formItem] = true end
    end

    for itemName in pairs(items) do
        registerUsableInventoryItem(itemName, function(data, callbackUseData)
            local src, useData = normalizeUsableData(data, callbackUseData)
            if not src or src <= 0 then return end

            local metadata = usableItemMetadata(useData)
            if not next(metadata) then
                local itemId = usableItemId(useData)
                local itemData = inventoryGetItemById(src, itemId)
                metadata = itemData and decodeMetadata(itemData.metadata or itemData.meta or itemData.itemMetadata) or {}
            end

            if not isTranscriptMetadata(metadata) then
                TriggerClientEvent("pk_medicarch:client:notify", src, L("notify.case_sheet_blank"), "error")
                return
            end

            pcall(function()
                exports.vorp_inventory:closeInventory(src)
            end)

            if isFormTranscriptMetadata(metadata) then
                TriggerClientEvent("pk_medicarch:client:openCaseTranscript", src, buildFormTranscriptPayload(metadata))
                return
            end

            TriggerClientEvent("pk_medicarch:client:openCaseTranscript", src, buildCaseTranscriptPayload(metadata))
        end)
    end
end

local function regItems()
    if not inventoryReady() then print(("[%s] vorp_inventory not started."):format(RES)); return end
    if Config.ItemRegistration.enabled then
        for _, it in ipairs(Config.ItemRegistration.items or {}) do
            if it.item and it.department then
                registerUsableInventoryItem(it.item, function(data, callbackUseData)
                    local src = select(1, normalizeUsableData(data, callbackUseData))
                    if src and src > 0 then TriggerClientEvent("pk_medicarch:client:openDepartment", src, it.department) end
                end)
            end
        end
    end
    registerTranscriptItems()
end

local function nextPatientCode(depId, prefix)
    MySQL.insert.await("INSERT INTO `pk_medicarch_sequences` (`department_id`,`last_number`) VALUES (?,1) ON DUPLICATE KEY UPDATE `last_number`=LAST_INSERT_ID(`last_number`+1)", { depId })
    local r = MySQL.query.await("SELECT LAST_INSERT_ID() AS seq")
    local n = r and r[1] and tonumber(r[1].seq) or 1
    local p = tostring(prefix or "MED"):upper():gsub("[^A-Z0-9]", "")
    if p == "" then p = "MED" end
    return ("%s-%05d"):format(p, n)
end

local function logHistory(depId, patientId, typ, reason, details, identity)
    MySQL.insert.await("INSERT INTO pk_medicarch_records (department_id,patient_id,record_type,reason,details,provider_charidentifier,provider_name) VALUES (?,?,?,?,?,?,?)", {
        depId, tonumber(patientId), sanitize(typ, 64), sanitize(reason, 255), sanitize(details, 4000), identity.charId, (identity.firstname .. " " .. identity.lastname):sub(1, 120)
    })
end

local function fetchPatients(depId, page, search)
    local s = sanitize(search or "", 64)
    local total, rows
    if s ~= "" then
        local p = "%" .. s .. "%"
        total = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM pk_medicarch_patients WHERE department_id=? AND deleted_at IS NULL AND (patient_code LIKE ? OR firstname LIKE ? OR lastname LIKE ? OR CONCAT(firstname,' ',lastname) LIKE ?)", { depId, p, p, p, p }) or 0)
        local pg = paginate(total, page)
        rows = MySQL.query.await("SELECT id,patient_code,firstname,lastname,dob,notes,charidentifier,created_at FROM pk_medicarch_patients WHERE department_id=? AND deleted_at IS NULL AND (patient_code LIKE ? OR firstname LIKE ? OR lastname LIKE ? OR CONCAT(firstname,' ',lastname) LIKE ?) ORDER BY created_at DESC LIMIT ? OFFSET ?", { depId, p, p, p, p, pg.perPage, pg.offset }) or {}
        formatDateFieldsInRows(rows, { "created_at" })
        return { items = rows, page = pg.page, perPage = pg.perPage, total = pg.total, totalPages = pg.totalPages }
    end
    total = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM pk_medicarch_patients WHERE department_id=? AND deleted_at IS NULL", { depId }) or 0)
    local pg = paginate(total, page)
    rows = MySQL.query.await("SELECT id,patient_code,firstname,lastname,dob,notes,charidentifier,created_at FROM pk_medicarch_patients WHERE department_id=? AND deleted_at IS NULL ORDER BY created_at DESC LIMIT ? OFFSET ?", { depId, pg.perPage, pg.offset }) or {}
    formatDateFieldsInRows(rows, { "created_at" })
    return { items = rows, page = pg.page, perPage = pg.perPage, total = pg.total, totalPages = pg.totalPages }
end
local function fetchHistory(depId, page, patientId)
    local pid = tonumber(patientId)
    local total
    if pid then
        total = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM pk_medicarch_records WHERE department_id=? AND patient_id=? AND deleted_at IS NULL", { depId, pid }) or 0)
    else
        total = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM pk_medicarch_records WHERE department_id=? AND deleted_at IS NULL", { depId }) or 0)
    end
    local pg = paginate(total, page)
    local rows
    if pid then
        rows = MySQL.query.await("SELECT r.id,r.patient_id,r.record_type,r.reason,r.details,r.provider_name,r.created_at,p.patient_code,p.firstname,p.lastname FROM pk_medicarch_records r LEFT JOIN pk_medicarch_patients p ON p.id=r.patient_id WHERE r.department_id=? AND r.patient_id=? AND r.deleted_at IS NULL ORDER BY r.created_at DESC LIMIT ? OFFSET ?", { depId, pid, pg.perPage, pg.offset }) or {}
    else
        rows = MySQL.query.await("SELECT r.id,r.patient_id,r.record_type,r.reason,r.details,r.provider_name,r.created_at,p.patient_code,p.firstname,p.lastname FROM pk_medicarch_records r LEFT JOIN pk_medicarch_patients p ON p.id=r.patient_id WHERE r.department_id=? AND r.deleted_at IS NULL ORDER BY r.created_at DESC LIMIT ? OFFSET ?", { depId, pg.perPage, pg.offset }) or {}
    end
    formatDateFieldsInRows(rows, { "created_at" })
    return { items = rows, page = pg.page, perPage = pg.perPage, total = pg.total, totalPages = pg.totalPages }
end

local function fetchForms(depId, page, patientId)
    local pid = tonumber(patientId)
    local total
    if pid then
        total = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM pk_medicarch_forms WHERE department_id=? AND patient_id=? AND deleted_at IS NULL", { depId, pid }) or 0)
    else
        total = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM pk_medicarch_forms WHERE department_id=? AND deleted_at IS NULL", { depId }) or 0)
    end
    local pg = paginate(total, page)
    local rows
    if pid then
        rows = MySQL.query.await("SELECT id,template_key,title,patient_id,patient_code,patient_name,description,shareable,created_by_name,signed,signed_by_name,signed_at,created_at FROM pk_medicarch_forms WHERE department_id=? AND patient_id=? AND deleted_at IS NULL ORDER BY created_at DESC LIMIT ? OFFSET ?", { depId, pid, pg.perPage, pg.offset }) or {}
    else
        rows = MySQL.query.await("SELECT id,template_key,title,patient_id,patient_code,patient_name,description,shareable,created_by_name,signed,signed_by_name,signed_at,created_at FROM pk_medicarch_forms WHERE department_id=? AND deleted_at IS NULL ORDER BY created_at DESC LIMIT ? OFFSET ?", { depId, pg.perPage, pg.offset }) or {}
    end
    formatDateFieldsInRows(rows, { "created_at", "signed_at" })
    return { items = rows, page = pg.page, perPage = pg.perPage, total = pg.total, totalPages = pg.totalPages }
end

local function fetchShared(identity, page)
    local total = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM pk_medicarch_shared_forms sf INNER JOIN pk_medicarch_forms f ON f.id=sf.form_id WHERE sf.owner_charidentifier=? AND sf.deleted_at IS NULL AND f.deleted_at IS NULL AND f.signed=1", { identity.charId }) or 0)
    local pg = paginate(total, page)
    local rows = MySQL.query.await("SELECT sf.id AS doc_id,sf.form_id,sf.created_at AS shared_at,sf.viewed_at,sf.shared_by_name,f.department_id,f.title,f.patient_code,f.patient_name,f.created_by_name,f.signed_by_name,f.signed_at,f.description FROM pk_medicarch_shared_forms sf INNER JOIN pk_medicarch_forms f ON f.id=sf.form_id WHERE sf.owner_charidentifier=? AND sf.deleted_at IS NULL AND f.deleted_at IS NULL AND f.signed=1 ORDER BY sf.created_at DESC LIMIT ? OFFSET ?", { identity.charId, pg.perPage, pg.offset }) or {}
    formatDateFieldsInRows(rows, { "shared_at", "viewed_at", "signed_at" })
    return { items = rows, page = pg.page, perPage = pg.perPage, total = pg.total, totalPages = pg.totalPages }
end

local function fetchCases(depId)
    local rows = MySQL.query.await("SELECT id,title,description,created_by_name,created_at,updated_at FROM pk_medicarch_cases WHERE department_id=? AND deleted_at IS NULL ORDER BY updated_at DESC, created_at DESC", { depId }) or {}
    formatDateFieldsInRows(rows, { "created_at", "updated_at" })
    local total = #rows
    return { items = rows, page = 1, perPage = total, total = total, totalPages = 1 }
end

local function templatesFor(depId)
    local dep = Config.Departments[depId]
    if not dep or type(dep.templateKeys) ~= "table" or #dep.templateKeys == 0 then return Config.FormTemplates end
    local map, out = {}, {}
    for _, t in ipairs(Config.FormTemplates or {}) do map[t.key] = t end
    for _, k in ipairs(dep.templateKeys) do if map[k] then out[#out + 1] = map[k] end end
    return out
end

local function actionBootstrap(_, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId)
    if not depId then return nil, err end
    return {
        department = { id = depId, label = dep.label },
        doctor = { fullname = (idn.firstname .. " " .. idn.lastname):gsub("^%s+", ""):gsub("%s+$", ""), job = idn.job, grade = idn.grade, charIdentifier = idn.charId },
        templates = templatesFor(depId),
        patients = fetchPatients(depId, 1, ""),
        history = fetchHistory(depId, 1, nil),
        forms = fetchForms(depId, 1, nil)
    }
end

local function actionPatients(_, idn, p) local depId, _, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end; return fetchPatients(depId, p and p.page or 1, p and p.search or "") end
local function actionHistory(_, idn, p) local depId, _, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end; return fetchHistory(depId, p and p.page or 1, p and p.patientId or nil) end
local function actionForms(_, idn, p) local depId, _, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end; return fetchForms(depId, p and p.page or 1, p and p.patientId or nil) end
local function actionCases(_, idn, p) local depId, _, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end; return fetchCases(depId) end

local function actionCreatePatient(_, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local firstname, lastname = sanitize(p and p.firstname or "", 80), sanitize(p and p.lastname or "", 80)
    local dob, notes = sanitize(p and p.dob or "", 30), sanitize(p and p.notes or "", 1200)
    local patientIdentifier, patientCharId
    local target = tonumber(p and p.targetServerId)
    if target then
        local t = getIdentity(target)
        if not t then return nil, L("notify.invalid_player") end
        firstname = t.firstname ~= "" and t.firstname or firstname
        lastname = t.lastname ~= "" and t.lastname or lastname
        patientIdentifier, patientCharId = t.identifier, t.charId
    end
    if firstname == "" or lastname == "" then return nil, L("errors.invalid_data") end
    if patientCharId then
        local ex = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM pk_medicarch_patients WHERE department_id=? AND charidentifier=? AND deleted_at IS NULL", { depId, patientCharId }) or 0)
        if ex > 0 then return nil, L("notify.patient_exists") end
    end
    local code = nextPatientCode(depId, dep.patientPrefix)
    local doctorName = (idn.firstname .. " " .. idn.lastname):sub(1, 120)
    local pid = MySQL.insert.await("INSERT INTO pk_medicarch_patients (department_id,patient_code,identifier,charidentifier,firstname,lastname,dob,notes,created_by_charidentifier,created_by_name) VALUES (?,?,?,?,?,?,?,?,?,?)", {
        depId, code, patientIdentifier, patientCharId, firstname, lastname, dob, notes, idn.charId, doctorName
    })
    if not pid then return nil, L("errors.generic") end
    logHistory(depId, pid, "registration", "Patient registration", notes, idn)
    webhook(depId, "patient_registered", "Patient Registered", {
        { name = "Department", value = dep.label, inline = true }, { name = "Patient ID", value = code, inline = true }, { name = "Patient", value = firstname .. " " .. lastname, inline = true }, { name = "Doctor", value = doctorName }
    })
    return { message = L("notify.patient_created"), patients = fetchPatients(depId, 1, ""), history = fetchHistory(depId, 1, nil) }
end

local function actionDeletePatient(_, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local patientId = tonumber(p and p.patientId); if not patientId then return nil, L("errors.invalid_data") end
    local pr = MySQL.query.await("SELECT id,patient_code,firstname,lastname FROM pk_medicarch_patients WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { patientId, depId })
    if not pr or not pr[1] then return nil, L("errors.patient_not_found") end
    MySQL.update.await("UPDATE pk_medicarch_patients SET deleted_at=NOW() WHERE id=?", { patientId })
    MySQL.update.await("UPDATE pk_medicarch_records SET deleted_at=NOW() WHERE patient_id=? AND department_id=? AND deleted_at IS NULL", { patientId, depId })
    local forms = MySQL.query.await("SELECT id FROM pk_medicarch_forms WHERE patient_id=? AND department_id=? AND deleted_at IS NULL", { patientId, depId }) or {}
    MySQL.update.await("UPDATE pk_medicarch_forms SET deleted_at=NOW() WHERE patient_id=? AND department_id=? AND deleted_at IS NULL", { patientId, depId })
    for _, r in ipairs(forms) do MySQL.update.await("UPDATE pk_medicarch_shared_forms SET deleted_at=NOW() WHERE form_id=? AND deleted_at IS NULL", { r.id }) end
    webhook(depId, "patient_deleted", "Patient Deleted", {
        { name = "Department", value = dep.label, inline = true }, { name = "Patient ID", value = pr[1].patient_code, inline = true }, { name = "Patient", value = pr[1].firstname .. " " .. pr[1].lastname, inline = true }, { name = "Doctor", value = idn.firstname .. " " .. idn.lastname }
    })
    return { message = L("notify.patient_deleted"), patients = fetchPatients(depId, 1, ""), history = fetchHistory(depId, 1, nil), forms = fetchForms(depId, 1, nil) }
end

local function actionCreateForm(_, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local patientId = tonumber(p and p.patientId); if not patientId then return nil, L("notify.no_patient_selected") end
    local pt = MySQL.query.await("SELECT id,patient_code,firstname,lastname FROM pk_medicarch_patients WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { patientId, depId })
    if not pt or not pt[1] then return nil, L("errors.patient_not_found") end
    local tMap = {}; for _, t in ipairs(templatesFor(depId) or {}) do tMap[t.key] = t end
    local tkey = sanitize(p and p.templateKey or "", 80); local tpl = tMap[tkey]; if not tpl then return nil, L("errors.invalid_data") end
    local title = sanitize(p and p.title or "", 150); if title == "" then title = sanitize(tpl.defaultTitle or tpl.label or "Medical Form", 150) end
    local desc = sanitize(p and p.description or "", 6000)
    local shareable = tpl.shareable
    local doctorName = (idn.firstname .. " " .. idn.lastname):sub(1, 120)
    local patientName = (pt[1].firstname .. " " .. pt[1].lastname):sub(1, 160)
    local formId = MySQL.insert.await("INSERT INTO pk_medicarch_forms (department_id,template_key,title,patient_id,patient_code,patient_name,description,shareable,created_by_charidentifier,created_by_name) VALUES (?,?,?,?,?,?,?,?,?,?)", {
        depId, tkey, title, patientId, pt[1].patient_code, patientName, desc, shareable and 1 or 0, idn.charId, doctorName
    })
    if not formId then return nil, L("errors.generic") end
    logHistory(depId, patientId, "form_created", title, desc, idn)
    webhook(depId, "form_created", "Form Created", {
        { name = "Department", value = dep.label, inline = true }, { name = "Patient ID", value = pt[1].patient_code, inline = true }, { name = "Patient", value = patientName, inline = true }, { name = "Form", value = title }, { name = "Doctor", value = doctorName }
    })
    return { message = L("notify.form_created"), forms = fetchForms(depId, 1, patientId), history = fetchHistory(depId, 1, patientId) }
end

local function actionUpdateForm(_, idn, p)
    local depId, _, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local formId = tonumber(p and p.formId); if not formId then return nil, L("errors.invalid_data") end
    local f = MySQL.query.await("SELECT id,patient_id FROM pk_medicarch_forms WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { formId, depId })
    if not f or not f[1] then return nil, L("errors.form_not_found") end
    local tMap = {}; for _, t in ipairs(templatesFor(depId) or {}) do tMap[t.key] = t end
    local tkey = sanitize(p and p.templateKey or "", 80); local tpl = tMap[tkey]; if not tpl then return nil, L("errors.invalid_data") end
    local title = sanitize(p and p.title or "", 150); if title == "" then title = sanitize(tpl.defaultTitle or tpl.label or "Medical Form", 150) end
    local desc = sanitize(p and p.description or "", 6000)
    local shareable = tpl.shareable
    MySQL.update.await("UPDATE pk_medicarch_forms SET template_key=?,title=?,description=?,shareable=?,signed=0,signed_by_charidentifier=NULL,signed_by_name=NULL,signed_at=NULL WHERE id=?", {
        tkey, title, desc, shareable and 1 or 0, formId
    })
    MySQL.update.await("UPDATE pk_medicarch_shared_forms SET deleted_at=NOW() WHERE form_id=? AND deleted_at IS NULL", { formId })
    logHistory(depId, f[1].patient_id, "form_updated", title, desc, idn)
    return { message = L("notify.form_updated"), forms = fetchForms(depId, 1, f[1].patient_id), history = fetchHistory(depId, 1, f[1].patient_id) }
end

local function actionCreateCase(_, idn, p)
    local depId, _, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local title = sanitize(p and p.title or "", 150)
    local desc = sanitize(p and p.description or "", 6000)
    if title == "" then return nil, L("errors.invalid_data") end
    local doctorName = (idn.firstname .. " " .. idn.lastname):sub(1, 120)
    local caseId = MySQL.insert.await("INSERT INTO pk_medicarch_cases (department_id,title,description,created_by_charidentifier,created_by_name) VALUES (?,?,?,?,?)", {
        depId, title, desc, idn.charId, doctorName
    })
    if not caseId then return nil, L("errors.generic") end
    return { message = L("notify.case_created"), cases = fetchCases(depId) }
end

local function actionUpdateCase(_, idn, p)
    local depId, _, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local caseId = tonumber(p and p.caseId); if not caseId then return nil, L("errors.invalid_data") end
    local title = sanitize(p and p.title or "", 150)
    local desc = sanitize(p and p.description or "", 6000)
    if title == "" then return nil, L("errors.invalid_data") end
    local ex = MySQL.query.await("SELECT id FROM pk_medicarch_cases WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { caseId, depId })
    if not ex or not ex[1] then return nil, L("errors.case_not_found") end
    MySQL.update.await("UPDATE pk_medicarch_cases SET title=?,description=?,updated_at=NOW() WHERE id=?", { title, desc, caseId })
    return { message = L("notify.case_updated"), cases = fetchCases(depId) }
end

local function actionDeleteCase(_, idn, p)
    local depId, _, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local caseId = tonumber(p and p.caseId); if not caseId then return nil, L("errors.invalid_data") end
    local ex = MySQL.query.await("SELECT id FROM pk_medicarch_cases WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { caseId, depId })
    if not ex or not ex[1] then return nil, L("errors.case_not_found") end
    MySQL.update.await("UPDATE pk_medicarch_cases SET deleted_at=NOW() WHERE id=?", { caseId })
    return { message = L("notify.case_deleted"), cases = fetchCases(depId) }
end

local function actionTranscribeCase(src, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    if not Config.CaseTranscriptions.enabled or not inventoryReady() then return nil, L("notify.inventory_unavailable") end
    local itemName = sanitize(Config.CaseTranscriptions.item, 128)
    if itemName == "" then return nil, L("notify.inventory_unavailable") end
    local caseId = tonumber(p and p.caseId); if not caseId then return nil, L("errors.invalid_data") end

    local rows = MySQL.query.await("SELECT id,title,description,created_by_name,created_at,updated_at FROM pk_medicarch_cases WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { caseId, depId })
    local caseRow = rows and rows[1]
    if not caseRow then return nil, L("errors.case_not_found") end

    local blankSheet = findBlankTranscriptSheet(src, itemName)
    if not blankSheet or not blankSheet.id then return nil, L("notify.case_sheet_missing") end

    local transcribedBy = sanitize((idn.firstname .. " " .. idn.lastname):gsub("^%s+", ""):gsub("%s+$", ""), 120)
    local transcribedAt = os.date("%Y-%m-%d %H:%M:%S")
    local metadata = buildCaseTranscriptMetadata(blankSheet.metadata, depId, dep and dep.label or depId, caseRow, transcribedBy, transcribedAt)
    local updated = inventorySetItemMetadata(src, blankSheet.id, metadata, 1)
    if not updated then return nil, L("notify.inventory_unavailable") end

    return { message = L("notify.case_transcribed"), transcript = buildCaseTranscriptPayload(metadata) }
end

local function actionTranscribeForm(src, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local cfg = Config.FormTranscriptions or {}
    if not cfg.enabled or not inventoryReady() then return nil, L("notify.inventory_unavailable") end
    local itemName = sanitize(cfg.item or (Config.CaseTranscriptions and Config.CaseTranscriptions.item) or "", 128)
    if itemName == "" then return nil, L("notify.inventory_unavailable") end
    local formId = tonumber(p and p.formId); if not formId then return nil, L("errors.invalid_data") end

    local rows = MySQL.query.await("SELECT id,template_key,title,patient_code,patient_name,description,created_by_name,signed,signed_by_name,signed_at,created_at FROM pk_medicarch_forms WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { formId, depId })
    local formRow = rows and rows[1]
    if not formRow then return nil, L("errors.form_not_found") end
    if cfg.requireSigned ~= false and not isTruthyFlag(formRow.signed) then
        return nil, L("errors.form_not_signed_for_transcript")
    end

    local blankSheet = findBlankTranscriptSheet(src, itemName)
    if not blankSheet or not blankSheet.id then return nil, L("notify.form_sheet_missing") end

    local transcribedBy = sanitize((idn.firstname .. " " .. idn.lastname):gsub("^%s+", ""):gsub("%s+$", ""), 120)
    local transcribedAt = os.date("%Y-%m-%d %H:%M:%S")
    local metadata = buildFormTranscriptMetadata(blankSheet.metadata, depId, dep and dep.label or depId, formRow, transcribedBy, transcribedAt)
    local updated = inventorySetItemMetadata(src, blankSheet.id, metadata, 1)
    if not updated then return nil, L("notify.inventory_unavailable") end

    return { message = L("notify.form_transcribed"), transcript = buildFormTranscriptPayload(metadata) }
end

local function actionSignForm(_, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local formId = tonumber(p and p.formId); if not formId then return nil, L("errors.invalid_data") end
    local f = MySQL.query.await("SELECT id,patient_id,title,patient_code,patient_name FROM pk_medicarch_forms WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { formId, depId })
    if not f or not f[1] then return nil, L("errors.form_not_found") end
    local doctorName = (idn.firstname .. " " .. idn.lastname):sub(1, 120)
    MySQL.update.await("UPDATE pk_medicarch_forms SET signed=1,signed_by_charidentifier=?,signed_by_name=?,signed_at=NOW() WHERE id=?", { idn.charId, doctorName, formId })
    logHistory(depId, f[1].patient_id, "form_signed", f[1].title, "", idn)
    webhook(depId, "form_signed", "Form Signed", {
        { name = "Department", value = dep.label, inline = true }, { name = "Patient ID", value = f[1].patient_code, inline = true }, { name = "Patient", value = f[1].patient_name, inline = true }, { name = "Form", value = f[1].title }, { name = "Doctor", value = doctorName }
    })
    return { message = L("notify.form_signed"), forms = fetchForms(depId, 1, f[1].patient_id), history = fetchHistory(depId, 1, f[1].patient_id) }
end

local function actionDeleteForm(_, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local formId = tonumber(p and p.formId); if not formId then return nil, L("errors.invalid_data") end
    local f = MySQL.query.await("SELECT id,patient_id,title,patient_code,patient_name FROM pk_medicarch_forms WHERE id=? AND department_id=? AND deleted_at IS NULL LIMIT 1", { formId, depId })
    if not f or not f[1] then return nil, L("errors.form_not_found") end
    MySQL.update.await("UPDATE pk_medicarch_forms SET deleted_at=NOW() WHERE id=?", { formId })
    MySQL.update.await("UPDATE pk_medicarch_shared_forms SET deleted_at=NOW() WHERE form_id=? AND deleted_at IS NULL", { formId })
    webhook(depId, "form_deleted", "Form Deleted", {
        { name = "Department", value = dep.label, inline = true }, { name = "Patient ID", value = f[1].patient_code, inline = true }, { name = "Patient", value = f[1].patient_name, inline = true }, { name = "Form", value = f[1].title }, { name = "Doctor", value = idn.firstname .. " " .. idn.lastname }
    })
    return { message = L("notify.form_deleted"), forms = fetchForms(depId, 1, f[1].patient_id) }
end

local function actionShareForm(_, idn, p)
    local depId, dep, err = getDepartment(idn, p and p.departmentId); if not depId then return nil, err end
    local formId, targetServerId = tonumber(p and p.formId), tonumber(p and p.targetServerId)
    if not formId then return nil, L("errors.invalid_data") end
    local f = MySQL.query.await("SELECT f.id,f.patient_id,f.patient_code,f.patient_name,f.title,f.signed,f.shareable,pt.charidentifier FROM pk_medicarch_forms f LEFT JOIN pk_medicarch_patients pt ON pt.id=f.patient_id AND pt.deleted_at IS NULL WHERE f.id=? AND f.department_id=? AND f.deleted_at IS NULL LIMIT 1", { formId, depId })
    if not f or not f[1] then return nil, L("errors.form_not_found") end
    if not isTruthyFlag(f[1].signed) then return nil, L("errors.form_not_signed") end
    if not isTruthyFlag(f[1].shareable) then return nil, L("errors.invalid_data") end
    local target
    if targetServerId then
        target = getIdentity(targetServerId)
        if not target then return nil, L("notify.invalid_player") end
        if not target.charId then return nil, L("errors.invalid_data") end
    else
        local patientCharId = tonumber(f[1].charidentifier)
        if not patientCharId then return nil, L("errors.patient_not_linked") end
        targetServerId, target = getSourceByCharId(patientCharId)
        if not targetServerId or not target then return nil, L("notify.patient_offline") end
    end
    local doctorName = (idn.firstname .. " " .. idn.lastname):sub(1, 120)
    MySQL.insert.await("INSERT INTO pk_medicarch_shared_forms (form_id,owner_charidentifier,shared_by_charidentifier,shared_by_name,created_at,deleted_at) VALUES (?,?,?,?,NOW(),NULL) ON DUPLICATE KEY UPDATE shared_by_charidentifier=VALUES(shared_by_charidentifier),shared_by_name=VALUES(shared_by_name),created_at=NOW(),deleted_at=NULL", {
        formId, target.charId, idn.charId, doctorName
    })
    TriggerClientEvent("pk_medicarch:client:notify", targetServerId, L("notify.shared_received"), "success")
    webhook(depId, "document_shared", "Form Shared", {
        { name = "Department", value = dep.label, inline = true }, { name = "Patient ID", value = f[1].patient_code, inline = true }, { name = "Form", value = f[1].title, inline = true }, { name = "Doctor", value = doctorName }, { name = "Shared To", value = target.firstname .. " " .. target.lastname }
    })
    return { message = L("notify.form_shared") }
end

local function actionSharedDocs(_, idn, p)
    if not idn.charId then return nil, L("errors.invalid_data") end
    return fetchShared(idn, p and p.page or 1)
end

local function actionSharedDocDetail(_, idn, p)
    if not idn.charId then return nil, L("errors.invalid_data") end
    local docId = tonumber(p and p.docId); if not docId then return nil, L("errors.invalid_data") end
    local rows = MySQL.query.await("SELECT sf.id AS doc_id,sf.form_id,sf.shared_by_name,sf.created_at AS shared_at,sf.viewed_at,f.department_id,f.template_key,f.title,f.patient_code,f.patient_name,f.description,f.created_by_name,f.signed_by_name,f.signed_at,f.created_at FROM pk_medicarch_shared_forms sf INNER JOIN pk_medicarch_forms f ON f.id=sf.form_id WHERE sf.id=? AND sf.owner_charidentifier=? AND sf.deleted_at IS NULL AND f.deleted_at IS NULL AND f.signed=1 LIMIT 1", { docId, idn.charId })
    if not rows or not rows[1] then return nil, L("errors.not_found") end
    if not rows[1].viewed_at then
        MySQL.update.await("UPDATE pk_medicarch_shared_forms SET viewed_at=NOW() WHERE id=?", { docId })
        rows[1].viewed_at = os.date("%Y-%m-%d %H:%M:%S")
    end
    formatDateFields(rows[1], { "shared_at", "viewed_at", "signed_at", "created_at" })
    return rows[1]
end

local actions = {
    bootstrap = actionBootstrap,
    patients = actionPatients,
    history = actionHistory,
    forms = actionForms,
    cases = actionCases,
    create_patient = actionCreatePatient,
    delete_patient = actionDeletePatient,
    create_form = actionCreateForm,
    update_form = actionUpdateForm,
    create_case = actionCreateCase,
    update_case = actionUpdateCase,
    delete_case = actionDeleteCase,
    transcribe_case = actionTranscribeCase,
    transcribe_form = actionTranscribeForm,
    sign_form = actionSignForm,
    delete_form = actionDeleteForm,
    share_form = actionShareForm,
    shared_docs = actionSharedDocs,
    shared_doc_detail = actionSharedDocDetail
}

RegisterNetEvent("pk_medicarch:server:request", function(requestId, action, payload)
    local src = source
    if type(requestId) ~= "number" or type(action) ~= "string" then reply(src, requestId, false, nil, L("errors.invalid_data")); return end
    local handler = actions[action]
    if not handler then reply(src, requestId, false, nil, L("errors.invalid_data")); return end
    local identity = getIdentity(src)
    if not identity then reply(src, requestId, false, nil, L("notify.no_access")); return end
    local ok, result, err = pcall(handler, src, identity, payload or {})
    if not ok then
        print(("[%s] action %s error: %s"):format(RES, action, tostring(result)))
        reply(src, requestId, false, nil, L("errors.generic"))
        return
    end
    if result == nil then reply(src, requestId, false, nil, err or L("errors.generic")); return end
    reply(src, requestId, true, result, nil)
end)

local function init()
    createTables()
    regItems()
end

CreateThread(function() Wait(800); init() end)
AddEventHandler("onResourceStart", function(r)
    if r == RES then
        CreateThread(function() Wait(800); init() end)
        return
    end
    if r == INVENTORY_RES then
        registeredUsableItems = {}
        CreateThread(function() Wait(800); regItems() end)
    end
end)
