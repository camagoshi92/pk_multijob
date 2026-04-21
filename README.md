# pk_multijob

Sistema multi-job per RedM/VORP che salva piu lavori per personaggio, permette di cambiare job attivo da menu e fornisce comandi admin per assegnazione e rimozione.

## Struttura

Il resource vero e proprio si trova nella cartella `pk_multijob/`.

File principali:

- `pk_multijob/fxmanifest.lua`
- `pk_multijob/shared/config.lua`
- `pk_multijob/client/client.lua`
- `pk_multijob/client/menu.lua`
- `pk_multijob/server/server.lua`

## Funzionalita

- Salvataggio dei lavori multipli nel database per `charidentifier`
- Cambio del job attivo tramite menu client
- Limite massimo di job configurabile
- Limite diverso per gruppo utente
- Notifiche client attivabili/disattivabili da config
- Fallback automatico a un altro job se viene rimosso quello attivo

## Dipendenze

Il resource usa direttamente:

- `vorp_core`
- `oxmysql`
- `tpz_menu_base`

## Requisiti database

Il codice legge e salva i multi-job nella tabella `characters`, colonna `multijobs`.

Se la colonna non esiste, aggiungila prima di avviare il resource. Esempio:

```sql
ALTER TABLE characters
ADD COLUMN multijobs TEXT NULL;
```

Il formato salvato e JSON.

## Installazione

1. Copia la cartella `pk_multijob` dentro la tua directory `resources`.
2. Verifica che `vorp_core`, `oxmysql` e `tpz_menu_base` siano gia presenti e funzionanti.
3. Aggiungi la colonna `multijobs` alla tabella `characters` se manca.
4. Avvia le dipendenze prima del resource.

Esempio `server.cfg`:

```cfg
ensure oxmysql
ensure vorp_core
ensure tpz_menu_base
ensure pk_multijob
```

## Configurazione

La configurazione si trova in `pk_multijob/shared/config.lua`.

Valori disponibili:

- `Config.DefaultMaxJobs`: numero massimo di job per default
- `Config.MaxJobsByGroup`: override del limite per gruppo VORP
- `Config.DefaultJob`: valore presente in config, non usato dal flusso runtime attuale
- `Config.DefaultJobGrade`: valore presente in config, non usato dal flusso runtime attuale
- `Config.Notifications`: abilita o disabilita le notifiche client

Configurazione attuale:

```lua
Config.DefaultMaxJobs = 3

Config.MaxJobsByGroup = {
    ["admin"]     = 5,
    ["moderator"] = 3,
    ["user"]      = 3,
}

Config.DefaultJob      = "unemployed"
Config.DefaultJobGrade = 0

Config.Notifications = true
```

## Comandi

Comandi player:

- `/pk_myjobs`
  - Apre il menu con i lavori assegnati al personaggio
  - Permette di impostare il job attivo

Comandi admin:

- `/addJob [id] [jobName] [grade] [label]`
  - Assegna un job a un player
  - Esempio: `/addJob 12 sheriff 2 Sheriff`

- `/removeJob [id] [jobName]`
  - Rimuove un job da un player
  - Esempio: `/removeJob 12 sheriff`

Note:

- I comandi admin controllano il gruppo `admin` quando eseguiti in game.
- Da console server i controlli gruppo non vengono applicati.
- Un player non puo avere job duplicati.
- Non e possibile rimuovere l'unico job salvato.

## Flusso del resource

1. Il player apre `/pk_myjobs`.
2. Il client richiede al server la lista dei job salvati.
3. Il server legge `characters.multijobs` per il `charidentifier` del personaggio attivo.
4. Il menu mostra i lavori disponibili e il job attualmente attivo.
5. Alla selezione, il server esegue `vorp:setJob` con nome job e grade salvato.

## Callback ed eventi usati

Callback server registrate:

- `pk_multijob:getMyJobs`
- `pk_multijob:setActiveJob`
- `pk_multijob:addJob`
- `pk_multijob:removeJob`

Eventi rilevanti:

- `pk_multijob:client:notify`
- `vorp:setJob`
- `vorp:setMultiJob`
- `vorp:playerJobChange`
- `vorp_core:Client:OnPlayerSpawned`

## Note operative

- I job multipli vengono salvati come array JSON con campi `name`, `grade` e `label`.
- Al login/spawn il client mostra una notifica con job attivo e grade corrente.
- Se rimuovi il job attivo e ne rimane almeno uno, il resource imposta automaticamente il primo job disponibile come attivo.
- `Config.DefaultJob` e `Config.DefaultJobGrade` sono definiti, ma nel codice attuale non vengono richiamati come fallback automatico.
