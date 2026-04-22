Config = {}

Config.Language = 'it'
Config.Debug = false
Config.PaginationSize = 10
Config.OpenDistance = 2.2
Config.DrawDistance = 9.0
Config.OpenControl = 0x760A9C6F -- G

Config.Commands = {
    archive = 'medarch',
    docs = 'meddocs',
    archiveKey = 'F10',
    docsKey = 'F9'
}

Config.Text3D = {
    enabled = true,
    scale = 0.34,
    text = '[G] Archivio Medico'
}

Config.ItemRegistration = {
    enabled = false,
    items = {
        -- { item = 'med_archive_book_val', department = 'valentine' }
    }
}

Config.CaseTranscriptions = {
    enabled = true,
    item = 'foglio_fascicolo'
}

Config.FormTranscriptions = {
    enabled = true,
    item = 'foglio_fascicolo',
    requireSigned = true
}

Config.DateDisplay = {
    serverYear = 1899,
    format = '%d/%m/%Y %H:%M',
}

Config.FormTemplates = {
    {
        key = 'treatment_report',
        label = 'Rapporto Trattamento',
        defaultTitle = 'Rapporto Trattamento',
        shareable = false
    },
    {
        key = 'medical_certificate',
        label = 'Rapporto Medico',
        defaultTitle = 'Rapporto Medico',
        shareable = true
    }
}

Config.Departments = {
    valentine = {
        label = 'Valentine Medical Office',
        patientPrefix = 'VAL',
        jobs = {
            { name = 'medico', minGrade = 0 },
            { name = 'medicval', minGrade = 0 },
            { name = 'Guvernator', minGrade = 0 }
        },
        locations = {
            { coords = vector3(-285.29, 804.75, 119.39) },
            { coords = vector3(-289.18, 807.90, 119.39) }
        },
        webhooks = {
            patient_registered = '',
            patient_deleted = '',
            form_created = '',
            form_signed = '',
            form_deleted = '',
            document_shared = ''
        }
    },
    saintdenis = {
        label = 'Saint Denis Medical Office',
        patientPrefix = 'SDN',
        jobs = {
            { name = 'medico', minGrade = 0 },
            { name = 'medicsd', minGrade = 0 },
            { name = 'Guvernator', minGrade = 0 }
        },
        locations = {
            { coords = vector3(2732.16, -1231.16, 50.37) }
        },
        webhooks = {
            patient_registered = '',
            patient_deleted = '',
            form_created = '',
            form_signed = '',
            form_deleted = '',
            document_shared = ''
        }
    }
}

Config.Locale = {
    it = {
        notify = {
            no_access = 'Non hai accesso a questo dipartimento.',
            no_department = 'Dipartimento non valido.',
            saved = 'Operazione completata.',
            shared_received = 'Hai ricevuto un documento medico condiviso.',
            no_patient_selected = 'Seleziona un paziente prima di creare un documento.',
            invalid_player = 'ID giocatore non valido.',
            patient_offline = 'Il paziente deve essere online per ricevere il documento.',
            patient_exists = 'Paziente gia registrato in questo dipartimento.',
            patient_created = 'Paziente registrato con successo.',
            patient_deleted = 'Paziente eliminato.',
            form_created = 'Documento creato.',
            form_updated = 'Documento aggiornato.',
            form_signed = 'Documento firmato.',
            form_deleted = 'Documento eliminato.',
            case_created = 'Fascicolo creato.',
            case_updated = 'Fascicolo aggiornato.',
            case_deleted = 'Fascicolo eliminato.',
            case_transcribed = 'Fascicolo trascritto sul foglio.',
            case_sheet_missing = 'Ti serve un foglio fascicolo vuoto.',
            case_sheet_blank = 'Questo foglio fascicolo e ancora vuoto.',
            form_transcribed = 'Documento trascritto sul foglio.',
            form_sheet_missing = 'Ti serve un foglio fascicolo vuoto.',
            inventory_unavailable = 'Inventario non disponibile.',
            form_shared = 'Documento condiviso con successo.',
            docs_empty = 'Non hai documenti condivisi.'
        },
        errors = {
            invalid_data = 'Dati non validi.',
            generic = 'Si e verificato un errore.',
            patient_required = 'Registrazione paziente obbligatoria.',
            patient_not_found = 'Paziente non trovato.',
            patient_not_linked = 'Il paziente non e collegato a un personaggio. Registralo con ID server.',
            case_not_found = 'Fascicolo non trovato.',
            form_not_found = 'Documento non trovato.',
            form_not_signed = 'Il documento deve essere firmato prima della condivisione.',
            form_not_signed_for_transcript = 'Il documento deve essere firmato prima della trascrizione.',
            not_found = 'Nessun risultato trovato.'
        },
        ui = {
            app_title = 'Archivio Medico',
            close = 'Chiudi',
            back = 'Indietro',
            refresh = 'Aggiorna',
            search = 'Cerca',
            patients = 'Pazienti',
            history = 'Storico',
            forms = 'Documenti',
            archive = 'Fascicoli',
            shared_docs = 'Documenti Condivisi',
            department = 'Dipartimento',
            doctor = 'Dottore',
            page = 'Pagina',
            prev = 'Precedente',
            next = 'Successiva',
            no_results = 'Nessun risultato',
            no_selection = 'Nessuna selezione',
            search_placeholder = 'Cerca per nome, cognome o Patient ID',
            patient_list = 'Lista Pazienti',
            patient_info = 'Informazioni Paziente',
            patient_code = 'Patient ID',
            first_name = 'Nome',
            last_name = 'Cognome',
            dob = 'Data di nascita',
            notes = 'Note',
            created_at = 'Creato il',
            register_patient = 'Registra Paziente',
            target_server_id = 'Server ID (opzionale)',
            delete_patient = 'Elimina Paziente',
            registration_required = 'Registrazione paziente richiesta per i documenti.',
            history_list = 'Storico Trattamenti',
            reason = 'Motivazione',
            provider = 'Provider Medico',
            timestamp = 'Timestamp',
            procedure = 'Procedura',
            template = 'Template',
            title = 'Titolo',
            description = 'Descrizione',
            create_form = 'Crea Documento',
            shareable = 'Condivisibile al paziente',
            form_list = 'Documenti Creati',
            status = 'Stato',
            actions = 'Azioni',
            unsigned = 'Non firmato',
            signed = 'Firmato',
            sign = 'Firma',
            edit = 'Modifica',
            share = 'Condividi',
            delete = 'Elimina',
            save_changes = 'Salva Modifiche',
            cancel_edit = 'Annulla Modifica',
            patient = 'Paziente',
            open = 'Apri',
            created_by = 'Creato da',
            signed_by = 'Firmato da',
            signed_at = 'Firmato il',
            no_docs = 'Nessun documento condiviso.',
            docs_title = 'I Tuoi Documenti Medici',
            docs_hint = 'Apri e mostra i documenti ricevuti dai medici.',
            share_prompt = 'Inserisci il Server ID del giocatore con cui condividere:',
            transcribe_form = 'Trascrivi Documento',
            form_transcript = 'Trascrizione Documento',
            case_list = 'Fascicoli Aperti',
            case_editor = 'Modulo Fascicolo',
            case_title = 'Titolo Fascicolo',
            case_description = 'Dettagli indagine o ricerca',
            create_case = 'Crea Fascicolo',
            save_case = 'Salva Fascicolo',
            cancel_case = 'Annulla',
            case_intro = 'Premi Crea Fascicolo per crearne uno nuovo oppure clicca un fascicolo a destra per leggerlo.',
            case_view = 'Lettura Fascicolo',
            close_view = 'Chiudi Lettura',
            updated_at = 'Aggiornato il',
            transcribe_case = 'Trascrivi Fascicolo',
            case_transcript = 'Trascrizione Fascicolo',
            transcribed_by = 'Trascritto da',
            transcribed_at = 'Trascritto il',
            transcript_empty = 'Nessun contenuto trascritto.'
        }
    },
    en = {
        notify = {
            no_access = 'You do not have access to this department.',
            no_department = 'Invalid department.',
            saved = 'Operation completed.',
            shared_received = 'You received a shared medical document.',
            no_patient_selected = 'Select a patient before creating a form.',
            invalid_player = 'Invalid player ID.',
            patient_offline = 'The patient must be online to receive the document.',
            patient_exists = 'Patient is already registered in this department.',
            patient_created = 'Patient registered successfully.',
            patient_deleted = 'Patient deleted.',
            form_created = 'Form created.',
            form_updated = 'Form updated.',
            form_signed = 'Form signed.',
            form_deleted = 'Form deleted.',
            case_created = 'Case file created.',
            case_updated = 'Case file updated.',
            case_deleted = 'Case file deleted.',
            case_transcribed = 'Case file transcribed onto the sheet.',
            case_sheet_missing = 'You need a blank case sheet.',
            case_sheet_blank = 'This case sheet is still blank.',
            form_transcribed = 'Form transcribed onto the sheet.',
            form_sheet_missing = 'You need a blank case sheet.',
            inventory_unavailable = 'Inventory unavailable.',
            form_shared = 'Form shared successfully.',
            docs_empty = 'No shared documents found.'
        },
        errors = {
            invalid_data = 'Invalid data.',
            generic = 'An error occurred.',
            patient_required = 'Patient registration is required.',
            patient_not_found = 'Patient not found.',
            patient_not_linked = 'This patient is not linked to a character. Register the patient using a server ID.',
            case_not_found = 'Case file not found.',
            form_not_found = 'Form not found.',
            form_not_signed = 'Form must be signed before sharing.',
            form_not_signed_for_transcript = 'Form must be signed before transcription.',
            not_found = 'No results found.'
        },
        ui = {
            app_title = 'Medical Database Office',
            close = 'Close',
            back = 'Back',
            refresh = 'Refresh',
            search = 'Search',
            patients = 'Patients',
            history = 'History',
            forms = 'Forms',
            archive = 'Cases',
            shared_docs = 'Shared Documents',
            department = 'Department',
            doctor = 'Doctor',
            page = 'Page',
            prev = 'Prev',
            next = 'Next',
            no_results = 'No results',
            no_selection = 'No selection',
            search_placeholder = 'Search by first name, last name or Patient ID',
            patient_list = 'Patient List',
            patient_info = 'Patient Information',
            patient_code = 'Patient ID',
            first_name = 'First Name',
            last_name = 'Last Name',
            dob = 'Date of Birth',
            notes = 'Notes',
            created_at = 'Created At',
            register_patient = 'Register Patient',
            target_server_id = 'Server ID (optional)',
            delete_patient = 'Delete Patient',
            registration_required = 'Patient registration is required before forms.',
            history_list = 'Treatment History',
            reason = 'Reason',
            provider = 'Medical Provider',
            timestamp = 'Timestamp',
            procedure = 'Procedure',
            template = 'Template',
            title = 'Title',
            description = 'Description',
            create_form = 'Create Form',
            shareable = 'Can be shared with patient',
            form_list = 'Created Forms',
            status = 'Status',
            actions = 'Actions',
            unsigned = 'Unsigned',
            signed = 'Signed',
            sign = 'Sign',
            edit = 'Edit',
            share = 'Share',
            delete = 'Delete',
            save_changes = 'Save Changes',
            cancel_edit = 'Cancel Edit',
            patient = 'Patient',
            open = 'Open',
            created_by = 'Created By',
            signed_by = 'Signed By',
            signed_at = 'Signed At',
            no_docs = 'No shared documents.',
            docs_title = 'Your Medical Documents',
            docs_hint = 'Open and show shared medical documents.',
            share_prompt = 'Insert target Server ID:',
            transcribe_form = 'Transcribe Form',
            form_transcript = 'Form Transcript',
            case_list = 'Open Cases',
            case_editor = 'Case Form',
            case_title = 'Case Title',
            case_description = 'Investigation or research details',
            create_case = 'Create Case',
            save_case = 'Save Case',
            cancel_case = 'Cancel',
            case_intro = 'Press Create Case to create a new one or click a case on the right to read it.',
            case_view = 'Case Reader',
            close_view = 'Close Reader',
            updated_at = 'Updated At',
            transcribe_case = 'Transcribe Case',
            case_transcript = 'Case Transcript',
            transcribed_by = 'Transcribed By',
            transcribed_at = 'Transcribed At',
            transcript_empty = 'No transcribed content.'
        }
    }
}
