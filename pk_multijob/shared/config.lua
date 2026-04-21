Config = {}

-- Numero massimo di job simultanei per player (default, sovrascrivibile per gruppo)
Config.DefaultMaxJobs = 3

-- Limite per gruppo specifico
Config.MaxJobsByGroup = {
    ["admin"]     = 5,
    ["moderator"] = 3,
    ["user"]      = 3,
}

-- Job di default assegnato quando si rimuovono tutti gli altri
Config.DefaultJob      = "unemployed"
Config.DefaultJobGrade = 0

-- Abilita notifiche client
Config.Notifications = true
