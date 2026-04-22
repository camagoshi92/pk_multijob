
const el = {
  overlay: document.getElementById('overlay'),
  appTitle: document.getElementById('appTitle'),
  subTitle: document.getElementById('subTitle'),
  archiveView: document.getElementById('archiveView'),
  archiveBackBtn: document.getElementById('archiveBackBtn'),
  docsView: document.getElementById('docsView'),
  docsBackBtn: document.getElementById('docsBackBtn'),
  tabs: [...document.querySelectorAll('.tab')],
  tabContents: [...document.querySelectorAll('.tab-content')],

  patientSearch: document.getElementById('patientSearch'),
  searchPatientBtn: document.getElementById('searchPatientBtn'),
  patientsList: document.getElementById('patientsList'),
  patientsPrev: document.getElementById('patientsPrev'),
  patientsNext: document.getElementById('patientsNext'),
  patientsPageInfo: document.getElementById('patientsPageInfo'),
  selectedPatient: document.getElementById('selectedPatient'),

  targetServerId: document.getElementById('targetServerId'),
  patientFirstName: document.getElementById('patientFirstName'),
  patientLastName: document.getElementById('patientLastName'),
  patientDob: document.getElementById('patientDob'),
  patientNotes: document.getElementById('patientNotes'),
  createPatientBtn: document.getElementById('createPatientBtn'),
  deletePatientBtn: document.getElementById('deletePatientBtn'),

  historyList: document.getElementById('historyList'),
  historyPrev: document.getElementById('historyPrev'),
  historyNext: document.getElementById('historyNext'),
  historyPageInfo: document.getElementById('historyPageInfo'),

  formTemplate: document.getElementById('formTemplate'),
  formTitleInput: document.getElementById('formTitleInput'),
  formDescription: document.getElementById('formDescription'),
  createFormBtn: document.getElementById('createFormBtn'),
  cancelFormEditBtn: document.getElementById('cancelFormEditBtn'),
  formsList: document.getElementById('formsList'),
  formsPrev: document.getElementById('formsPrev'),
  formsNext: document.getElementById('formsNext'),
  formsPageInfo: document.getElementById('formsPageInfo'),

  docsAddPatient: document.getElementById('docsAddPatient'),
  docsPatients: document.getElementById('docsPatients'),
  docsArchive: document.getElementById('docsArchive'),
  docsPatientsSearch: document.getElementById('docsPatientsSearch'),
  docsPatientsSearchBtn: document.getElementById('docsPatientsSearchBtn'),
  docsPatientsList: document.getElementById('docsPatientsList'),
  docsArchiveEditor: document.getElementById('docsArchiveEditor'),
  docsArchiveEditorTitle: document.getElementById('docsArchiveEditorTitle'),
  docsArchiveEditorIntro: document.getElementById('docsArchiveEditorIntro'),
  docsArchiveReader: document.getElementById('docsArchiveReader'),
  docsArchiveReaderTitle: document.getElementById('docsArchiveReaderTitle'),
  docsArchiveReaderCaseTitle: document.getElementById('docsArchiveReaderCaseTitle'),
  docsArchiveReaderMeta: document.getElementById('docsArchiveReaderMeta'),
  docsArchiveReaderBody: document.getElementById('docsArchiveReaderBody'),
  docsTranscribeCaseBtn: document.getElementById('docsTranscribeCaseBtn'),
  docsReadCaseEditBtn: document.getElementById('docsReadCaseEditBtn'),
  docsCloseCaseViewBtn: document.getElementById('docsCloseCaseViewBtn'),
  docsArchiveForm: document.getElementById('docsArchiveForm'),
  docsCaseTitleInput: document.getElementById('docsCaseTitleInput'),
  docsCaseDescription: document.getElementById('docsCaseDescription'),
  docsSaveCaseBtn: document.getElementById('docsSaveCaseBtn'),
  docsCancelCaseBtn: document.getElementById('docsCancelCaseBtn'),
  docsCasesTitle: document.getElementById('docsCasesTitle'),
  docsCasesList: document.getElementById('docsCasesList'),
  docsCreateCaseBtn: document.getElementById('docsCreateCaseBtn'),
  docsCasesPrev: document.getElementById('docsCasesPrev'),
  docsCasesNext: document.getElementById('docsCasesNext'),
  docsCasesPageInfo: document.getElementById('docsCasesPageInfo'),
  docsList: document.getElementById('docsList'),
  docDetail: document.getElementById('docDetail'),
  docsPatientForm: document.getElementById('docsPatientForm'),
  docsRegFullName: document.getElementById('docsRegFullName'),
  docsRegDob: document.getElementById('docsRegDob'),
  docsRegProfession: document.getElementById('docsRegProfession'),
  docsRegSex: document.getElementById('docsRegSex'),
  docsRegServerId: document.getElementById('docsRegServerId'),
  docsRegHistory: document.getElementById('docsRegHistory'),
  docsRegisterBtn: document.getElementById('docsRegisterBtn'),
  docsRegisterStatus: document.getElementById('docsRegisterStatus'),
  transcriptView: document.getElementById('transcriptView'),
  transcriptCloseBtn: document.getElementById('transcriptCloseBtn'),
  transcriptSheetTitle: document.getElementById('transcriptSheetTitle'),
  transcriptSheetCaseTitle: document.getElementById('transcriptSheetCaseTitle'),
  transcriptSheetMeta: document.getElementById('transcriptSheetMeta'),
  transcriptSheetBody: document.getElementById('transcriptSheetBody')
};

const state = {
  locale: {},
  mode: null,
  department: null,
  doctor: null,
  selectedPatient: null,
  editingFormId: null,
  editingCaseId: null,
  caseEditorOpen: false,
  viewedCaseId: null,
  docsPanel: 'home',
  docsReturnPanel: null,
  docsSelectedPatientId: null,
  docsOpenedFormId: null,
  transcriptCase: null,
  docsPatientForms: { items: [], page: 1, totalPages: 1 },
  archiveReturnPanel: null,
  patients: { items: [], page: 1, totalPages: 1 },
  history: { items: [], page: 1, totalPages: 1 },
  forms: { items: [], page: 1, totalPages: 1 },
  cases: { items: [], page: 1, totalPages: 1 },
  docs: { items: [], page: 1, totalPages: 1 },
  templates: []
};

const t = (key, fallback) => state.locale?.[key] || fallback || key;

async function post(action, data = {}) {
  const response = await fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
  return response.json();
}

function text(id, key, fallback) {
  const node = document.getElementById(id);
  if (node) node.textContent = t(key, fallback);
}

function setUiText() {
  text('appTitle', 'app_title', 'Archivio Medico');
  text('archiveBackBtn', 'back', 'Indietro');
  text('docsBackBtn', 'back', 'Indietro');
  text('tabPatients', 'patients', 'Pazienti');
  text('tabHistory', 'history', 'Storico');
  text('tabForms', 'forms', 'Documenti');
  text('patientsListTitle', 'patient_list', 'Lista Pazienti');
  text('patientInfoTitle', 'patient_info', 'Informazioni Paziente');
  text('registerPatientTitle', 'register_patient', 'Registra Paziente');
  text('deletePatientBtn', 'delete_patient', 'Elimina Paziente');
  text('historyTitle', 'history_list', 'Storico Trattamenti');
  text('createFormTitle', 'create_form', 'Crea Documento');
  text('formsListTitle', 'form_list', 'Documenti Creati');
  text('docsTitle', 'docs_title', 'I Tuoi Documenti Medici');
  text('docsAddPatient', 'add_patient', 'Aggiungi Paziente');
  text('docsPatients', 'patients', 'Pazienti');
  text('docsArchive', 'archive', 'Fascicoli');
  text('docsArchiveEditorTitle', 'case_editor', 'Modulo Fascicolo');
  text('docsArchiveEditorIntro', 'case_intro', 'Premi Crea Fascicolo per crearne uno nuovo oppure clicca un fascicolo a destra per leggerlo.');
  text('docsArchiveReaderTitle', 'case_view', 'Lettura Fascicolo');
  text('docsTranscribeCaseBtn', 'transcribe_case', 'Trascrivi Fascicolo');
  text('docsCasesTitle', 'case_list', 'Fascicoli Aperti');
  text('docsCreateCaseBtn', 'create_case', 'Crea Fascicolo');
  text('transcriptSheetTitle', 'case_transcript', 'Trascrizione Fascicolo');
  text('transcriptCloseBtn', 'close', 'Chiudi');

  el.patientSearch.placeholder = t('search_placeholder', 'Cerca');
  el.targetServerId.placeholder = t('target_server_id', 'ID Server (opzionale)');
  el.patientFirstName.placeholder = t('first_name', 'Nome');
  el.patientLastName.placeholder = t('last_name', 'Cognome');
  el.patientDob.placeholder = t('dob', 'Data di nascita');
  el.patientNotes.placeholder = t('notes', 'Note');
  el.formTitleInput.placeholder = t('title', 'Titolo');
  el.formDescription.placeholder = t('description', 'Descrizione');
  if (el.docsRegFullName) el.docsRegFullName.placeholder = t('full_name', 'Nome e Cognome');
  if (el.docsRegDob) el.docsRegDob.placeholder = t('dob', 'Data di nascita');
  if (el.docsRegProfession) el.docsRegProfession.placeholder = t('job', 'Professione / Lavoro');
  if (el.docsRegSex) el.docsRegSex.placeholder = t('sex', 'Sesso [ Maschio / Femmina ]');
  if (el.docsRegServerId) el.docsRegServerId.placeholder = t('target_server_id', 'ID giocatore online');
  if (el.docsRegHistory) el.docsRegHistory.placeholder = t('medical_notes', 'Dettagli medici confidenziali');
  if (el.docsPatientsSearch) el.docsPatientsSearch.placeholder = t('search_placeholder', 'Cerca per nome, cognome o Patient ID');
  if (el.docsCaseTitleInput) el.docsCaseTitleInput.placeholder = t('case_title', 'Titolo Fascicolo');
  if (el.docsCaseDescription) el.docsCaseDescription.placeholder = t('case_description', 'Dettagli indagine o ricerca');

  el.searchPatientBtn.textContent = t('search', 'Cerca');
  el.createPatientBtn.textContent = t('register_patient', 'Registra Paziente');
  el.createFormBtn.textContent = state.editingFormId ? t('save_changes', 'Salva Modifiche') : t('create_form', 'Crea Documento');
  if (el.cancelFormEditBtn) el.cancelFormEditBtn.textContent = t('cancel_edit', 'Annulla Modifica');
  if (el.docsSaveCaseBtn) el.docsSaveCaseBtn.textContent = state.editingCaseId ? t('save_changes', 'Salva Modifiche') : t('create_case', 'Crea Fascicolo');
  if (el.docsCancelCaseBtn) el.docsCancelCaseBtn.textContent = state.editingCaseId ? t('cancel_edit', 'Annulla Modifica') : t('cancel_case', 'Annulla');
  if (el.docsReadCaseEditBtn) el.docsReadCaseEditBtn.textContent = t('edit', 'Modifica');
  if (el.docsCloseCaseViewBtn) el.docsCloseCaseViewBtn.textContent = t('close_view', 'Chiudi Lettura');
  if (el.docsRegisterBtn) el.docsRegisterBtn.textContent = t('register', 'REGISTRA');
  if (el.docsPatientsSearchBtn) el.docsPatientsSearchBtn.textContent = t('search', 'Cerca');

  [el.patientsPrev, el.historyPrev, el.formsPrev, el.docsCasesPrev].forEach((b) => b && (b.textContent = t('prev', 'Precedente')));
  [el.patientsNext, el.historyNext, el.formsNext, el.docsCasesNext].forEach((b) => b && (b.textContent = t('next', 'Successiva')));
}

function show(mode) {
  state.mode = mode;
  el.overlay.classList.remove('hidden');
  el.overlay.classList.toggle('mode-archive', mode === 'archive');
  el.overlay.classList.toggle('mode-docs', mode === 'docs');
  el.overlay.classList.toggle('mode-transcript', mode === 'transcript');
  if (mode === 'archive') {
    el.overlay.classList.remove('docs-add-open');
    el.overlay.classList.remove('docs-patients-open');
    el.overlay.classList.remove('docs-archive-open');
    el.archiveView.classList.remove('hidden');
    el.docsView.classList.add('hidden');
    if (el.transcriptView) el.transcriptView.classList.add('hidden');
    if (el.archiveBackBtn) {
      el.archiveBackBtn.classList.toggle('visible', !!state.archiveReturnPanel);
    }
  } else if (mode === 'docs') {
    el.archiveView.classList.add('hidden');
    el.docsView.classList.remove('hidden');
    if (el.transcriptView) el.transcriptView.classList.add('hidden');
    if (el.archiveBackBtn) {
      el.archiveBackBtn.classList.remove('visible');
    }
    setDocsPanel('home');
  } else if (mode === 'transcript') {
    el.archiveView.classList.add('hidden');
    el.docsView.classList.add('hidden');
    if (el.transcriptView) el.transcriptView.classList.remove('hidden');
    if (el.archiveBackBtn) {
      el.archiveBackBtn.classList.remove('visible');
    }
  }
}

function hide() {
  el.overlay.classList.add('hidden');
  el.archiveView.classList.add('hidden');
  el.docsView.classList.add('hidden');
  if (el.transcriptView) el.transcriptView.classList.add('hidden');
  el.overlay.classList.remove('docs-add-open');
  el.overlay.classList.remove('docs-patients-open');
  el.overlay.classList.remove('docs-archive-open');
  el.overlay.classList.remove('mode-archive');
  el.overlay.classList.remove('mode-docs');
  el.overlay.classList.remove('mode-transcript');
  state.archiveReturnPanel = null;
  state.viewedCaseId = null;
  state.transcriptCase = null;
  resetDocsPatientForm();
  resetFormEditor();
  resetCaseEditor(false);
}

function setDocsPanel(mode) {
  state.docsPanel = (mode === 'add' || mode === 'patients' || mode === 'archive' || mode === 'report') ? mode : 'home';
  const addOpen = state.docsPanel === 'add';
  const patientsOpen = state.docsPanel === 'patients';
  const archiveOpen = state.docsPanel === 'archive';
  const reportOpen = state.docsPanel === 'report';
  el.overlay.classList.toggle('docs-add-open', addOpen);
  el.overlay.classList.toggle('docs-patients-open', patientsOpen);
  el.overlay.classList.toggle('docs-archive-open', archiveOpen);
  el.overlay.classList.toggle('docs-report-open', reportOpen);
  [el.docsAddPatient, el.docsPatients, el.docsArchive].forEach((node) => node && node.classList.remove('active'));
  if (addOpen) {
    if (el.docsAddPatient) el.docsAddPatient.classList.add('active');
  } else if (patientsOpen) {
    if (el.docsPatients) el.docsPatients.classList.add('active');
  } else if (el.docsArchive) {
    el.docsArchive.classList.add('active');
  }
  if (el.docsBackBtn) {
    el.docsBackBtn.classList.toggle('visible', state.docsPanel !== 'home');
  }
  if (patientsOpen) renderDocsPatients();
  if (archiveOpen) {
    renderCaseEditor();
    renderCases();
  }
  if (reportOpen) renderDocsOpenedFormPage();
}

function resetDocsPatientForm() {
  if (el.docsRegFullName) el.docsRegFullName.value = '';
  if (el.docsRegDob) el.docsRegDob.value = '';
  if (el.docsRegProfession) el.docsRegProfession.value = '';
  if (el.docsRegSex) el.docsRegSex.value = '';
  if (el.docsRegServerId) el.docsRegServerId.value = '';
  if (el.docsRegHistory) el.docsRegHistory.value = '';
  if (el.docsRegisterStatus) el.docsRegisterStatus.textContent = '';
}

function setDocsStatus(message, ok) {
  if (!el.docsRegisterStatus) return;
  el.docsRegisterStatus.textContent = message || '';
  el.docsRegisterStatus.style.color = ok ? 'rgba(24,92,44,0.9)' : 'rgba(150,41,41,0.9)';
}

function splitPatientName(fullname) {
  const parts = (fullname || '').trim().replace(/\s+/g, ' ').split(' ').filter(Boolean);
  if (!parts.length) return { firstname: '', lastname: '' };
  if (parts.length === 1) return { firstname: parts[0], lastname: '-' };
  return { firstname: parts.shift(), lastname: parts.join(' ') };
}

function openArchiveWorkspace(tabId, options = {}) {
  state.archiveReturnPanel = options.returnToDocsPanel || null;
  show('archive');
  const targetTab = tabId || 'patientsTab';
  el.tabs.forEach((x) => x.classList.remove('active'));
  el.tabContents.forEach((x) => x.classList.remove('active'));
  const tabButton = el.tabs.find((x) => x.dataset.tab === targetTab) || el.tabs[0];
  if (tabButton) tabButton.classList.add('active');
  const tabContent = document.getElementById(targetTab) || el.tabContents[0];
  if (tabContent) tabContent.classList.add('active');
}

function pageInfo(bucket) {
  return `${t('page', 'Page')} ${bucket.page || 1} / ${bucket.totalPages || 1}`;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function formatCaseText(value) {
  const safe = escapeHtml(value || '');
  return safe
    .replace(/\*\*([\s\S]+?)\*\*/g, '<strong>$1</strong>')
    .replace(/__([\s\S]+?)__/g, '<strong>$1</strong>');
}

function renderTemplates() {
  el.formTemplate.innerHTML = '';
  state.templates.forEach((tpl) => {
    const option = document.createElement('option');
    option.value = tpl.key;
    option.textContent = tpl.label || tpl.key;
    option.dataset.title = tpl.defaultTitle || tpl.label || tpl.key;
    el.formTemplate.appendChild(option);
  });
  if (el.formTemplate.options.length > 0) {
    const selected = el.formTemplate.options[0];
    el.formTitleInput.value = selected.dataset.title || '';
  }
}

function resetFormEditor() {
  state.editingFormId = null;
  if (el.formTemplate.options.length > 0) {
    const selected = el.formTemplate.options[0];
    el.formTemplate.value = selected.value;
    el.formTitleInput.value = selected.dataset.title || '';
  } else {
    el.formTitleInput.value = '';
  }
  el.formDescription.value = '';
  if (el.cancelFormEditBtn) el.cancelFormEditBtn.classList.add('hidden');
  setUiText();
}

function renderCaseEditor() {
  const editorOpen = !!state.caseEditorOpen;
  const viewedCase = (state.cases.items || []).find((item) => Number(item.id) === Number(state.viewedCaseId)) || null;
  const readerOpen = !!viewedCase && !editorOpen;
  if (el.docsArchiveEditor) el.docsArchiveEditor.classList.toggle('reader-open', readerOpen);
  if (el.docsArchiveEditorTitle) el.docsArchiveEditorTitle.classList.toggle('hidden', readerOpen);
  if (el.docsArchiveEditorIntro) el.docsArchiveEditorIntro.classList.toggle('hidden', editorOpen || readerOpen);
  if (el.docsArchiveReader) el.docsArchiveReader.classList.toggle('hidden', !readerOpen);
  if (el.docsArchiveForm) el.docsArchiveForm.classList.toggle('hidden', !editorOpen);
  if (el.docsSaveCaseBtn) el.docsSaveCaseBtn.classList.toggle('hidden', !editorOpen);
  if (el.docsCancelCaseBtn) el.docsCancelCaseBtn.classList.toggle('hidden', !editorOpen);
  if (readerOpen) {
    if (el.docsArchiveReaderCaseTitle) el.docsArchiveReaderCaseTitle.textContent = viewedCase.title || '-';
    if (el.docsArchiveReaderMeta) {
      el.docsArchiveReaderMeta.innerHTML = `
        ${t('created_by', 'Created By')}: ${viewedCase.created_by_name || '-'}<br />
        ${t('created_at', 'Created')}: ${viewedCase.created_at || '-'}<br />
        ${t('updated_at', 'Updated At')}: ${viewedCase.updated_at || '-'}
      `;
    }
    if (el.docsArchiveReaderBody) el.docsArchiveReaderBody.innerHTML = formatCaseText(viewedCase.description || '-');
  }
  setUiText();
}

function resetCaseEditor(openEditor = false) {
  state.editingCaseId = null;
  state.caseEditorOpen = !!openEditor;
  if (el.docsCaseTitleInput) el.docsCaseTitleInput.value = '';
  if (el.docsCaseDescription) el.docsCaseDescription.value = '';
  renderCaseEditor();
}

function renderTranscriptSheet() {
  const transcript = state.transcriptCase || {};
  const isFormTranscript = transcript.kind === 'form';
  if (el.transcriptSheetTitle) {
    el.transcriptSheetTitle.textContent = transcript.sheetTitle || (isFormTranscript
      ? t('form_transcript', 'Trascrizione Documento')
      : t('case_transcript', 'Trascrizione Fascicolo'));
  }
  if (el.transcriptSheetCaseTitle) {
    el.transcriptSheetCaseTitle.textContent = transcript.title || '-';
  }
  if (el.transcriptSheetMeta) {
    if (isFormTranscript) {
      const patientLabel = [transcript.patientCode, transcript.patientName].filter(Boolean).join(' - ') || '-';
      el.transcriptSheetMeta.innerHTML = `
        ${t('department', 'Dipartimento')}: ${transcript.departmentLabel || transcript.departmentId || '-'}<br />
        ${t('patient', 'Paziente')}: ${patientLabel}<br />
        ${t('template', 'Template')}: ${transcript.templateKey || '-'}<br />
        ${t('created_by', 'Creato da')}: ${transcript.createdBy || '-'}<br />
        ${t('created_at', 'Creato il')}: ${transcript.createdAt || '-'}<br />
        ${t('status', 'Stato')}: ${transcript.signed ? t('signed', 'Firmato') : t('unsigned', 'Non firmato')}<br />
        ${t('signed_by', 'Firmato da')}: ${transcript.signedBy || '-'}<br />
        ${t('signed_at', 'Firmato il')}: ${transcript.signedAt || '-'}<br />
        ${t('transcribed_by', 'Trascritto da')}: ${transcript.transcribedBy || '-'}<br />
        ${t('transcribed_at', 'Trascritto il')}: ${transcript.transcribedAt || '-'}
      `;
    } else {
      el.transcriptSheetMeta.innerHTML = `
        ${t('department', 'Dipartimento')}: ${transcript.departmentLabel || transcript.departmentId || '-'}<br />
        ${t('created_by', 'Creato da')}: ${transcript.createdBy || '-'}<br />
        ${t('created_at', 'Creato il')}: ${transcript.createdAt || '-'}<br />
        ${t('updated_at', 'Aggiornato il')}: ${transcript.updatedAt || '-'}<br />
        ${t('transcribed_by', 'Trascritto da')}: ${transcript.transcribedBy || '-'}<br />
        ${t('transcribed_at', 'Trascritto il')}: ${transcript.transcribedAt || '-'}
      `;
    }
  }
  if (el.transcriptSheetBody) {
    el.transcriptSheetBody.innerHTML = formatCaseText(transcript.body || t('transcript_empty', 'Nessun contenuto trascritto.'));
  }
}

function startEditingCase(caseFile) {
  state.viewedCaseId = caseFile.id;
  state.editingCaseId = caseFile.id;
  state.caseEditorOpen = true;
  if (el.docsCaseTitleInput) el.docsCaseTitleInput.value = caseFile.title || '';
  if (el.docsCaseDescription) el.docsCaseDescription.value = caseFile.description || '';
  renderCaseEditor();
}

function startEditingForm(form) {
  state.editingFormId = form.id;
  if ([...el.formTemplate.options].some((opt) => opt.value === form.template_key)) {
    el.formTemplate.value = form.template_key;
  }
  el.formTitleInput.value = form.title || '';
  el.formDescription.value = form.description || '';
  if (el.cancelFormEditBtn) el.cancelFormEditBtn.classList.remove('hidden');
  setUiText();
}

function patientCard(patient) {
  const active = state.selectedPatient && state.selectedPatient.id === patient.id ? ' active' : '';
  return `
    <div class="item${active}" data-patient-id="${patient.id}">
      <strong>${patient.patient_code}</strong> - ${patient.firstname} ${patient.lastname}<br />
      <span class="small">${t('dob', 'DOB')}: ${patient.dob || '-'} | ${t('created_at', 'Created')}: ${patient.created_at || '-'}</span>
    </div>`;
}

function renderPatients() {
  el.patientsList.innerHTML = state.patients.items.length
    ? state.patients.items.map(patientCard).join('')
    : `<div class="small">${t('no_results', 'No results')}</div>`;

  el.patientsPageInfo.textContent = pageInfo(state.patients);

  if (state.selectedPatient) {
    el.selectedPatient.innerHTML = `
      <b>${state.selectedPatient.patient_code}</b><br />
      ${state.selectedPatient.firstname} ${state.selectedPatient.lastname}<br />
      ${t('dob', 'DOB')}: ${state.selectedPatient.dob || '-'}<br />
      ${t('notes', 'Notes')}: ${state.selectedPatient.notes || '-'}
    `;
  } else {
    el.selectedPatient.innerHTML = '';
  }

  [...el.patientsList.querySelectorAll('[data-patient-id]')].forEach((node) => {
    node.addEventListener('click', () => {
      const id = Number(node.dataset.patientId);
      state.selectedPatient = state.patients.items.find((x) => x.id === id) || null;
      renderPatients();
      loadHistory(1);
      loadForms(1);
    });
  });
}

function historyCard(h) {
  return `
    <div class="item">
      <strong>${h.patient_code || '-'}</strong> - ${(h.firstname || '')} ${(h.lastname || '')}<br />
      <span>${t('procedure', 'Procedure')}: ${h.record_type || '-'}</span><br />
      <span>${t('reason', 'Reason')}: ${h.reason || '-'}</span><br />
      <span>${t('provider', 'Provider')}: ${h.provider_name || '-'}</span><br />
      <span>${t('timestamp', 'Timestamp')}: ${h.created_at || '-'}</span>
    </div>`;
}

function renderHistory() {
  el.historyList.innerHTML = state.history.items.length
    ? state.history.items.map(historyCard).join('')
    : `<div class="small">${t('no_results', 'No results')}</div>`;
  el.historyPageInfo.textContent = pageInfo(state.history);
}

function formCard(f) {
  const signed = Number(f.signed) === 1;
  return `
    <div class="item" data-form-id="${f.id}">
      <strong>${f.title}</strong><br />
      <span class="small">${f.patient_code} - ${f.patient_name}</span><br />
      <span class="badge ${signed ? 'signed' : 'unsigned'}">${signed ? t('signed', 'Signed') : t('unsigned', 'Unsigned')}</span>
      <div class="actions">
        ${signed ? '' : `<button class="btn ok" data-action="sign" data-id="${f.id}">${t('sign', 'Sign')}</button>`}
        ${signed && Number(f.shareable) === 1 ? `<button class="btn" data-action="share" data-id="${f.id}">${t('share', 'Share')}</button>` : ''}
        <button class="btn danger" data-action="delete" data-id="${f.id}">${t('delete', 'Delete')}</button>
      </div>
    </div>`;
}

function renderForms() {
  el.formsList.innerHTML = state.forms.items.length
    ? state.forms.items.map(formCard).join('')
    : `<div class="small">${t('no_results', 'No results')}</div>`;
  el.formsPageInfo.textContent = pageInfo(state.forms);
}

function caseCard(caseFile) {
  const active = Number(state.viewedCaseId) === Number(caseFile.id) ? ' active' : '';
  return `
    <div class="docs-case-card${active}" data-case-id="${caseFile.id}">
      <strong>${caseFile.title || '-'}</strong><br />
      <span class="small">${t('created_by', 'Created By')}: ${caseFile.created_by_name || '-'}</span><br />
      <span class="small">${t('created_at', 'Created')}: ${caseFile.created_at || '-'} | ${t('updated_at', 'Updated At')}: ${caseFile.updated_at || '-'}</span>
      <div class="docs-case-actions">
        <button class="btn" data-case-action="edit" data-case-id="${caseFile.id}">${t('edit', 'Edit')}</button>
        <button class="btn danger" data-case-action="delete" data-case-id="${caseFile.id}">${t('delete', 'Delete')}</button>
      </div>
    </div>`;
}

function renderCases() {
  if (!el.docsCasesList || !el.docsCasesPageInfo) return;
  el.docsCasesList.innerHTML = state.cases.items.length
    ? state.cases.items.map(caseCard).join('')
    : `<div class="small">${t('no_results', 'No results')}</div>`;
  el.docsCasesPageInfo.textContent = pageInfo(state.cases);

  [...el.docsCasesList.querySelectorAll('[data-case-action]')].forEach((node) => {
    node.addEventListener('click', async (e) => {
      e.stopPropagation();
      const action = node.dataset.caseAction;
      const caseId = Number(node.dataset.caseId);
      const caseFile = state.cases.items.find((item) => Number(item.id) === caseId);
      if (!caseFile) return;

      if (action === 'edit') {
        startEditingCase(caseFile);
        return;
      }

      if (action === 'delete') {
        const res = await post('delete_case', { caseId });
        if (!res.ok) return;
        if (res.data?.cases) state.cases = res.data.cases;
        if (state.editingCaseId === caseId) resetCaseEditor(false);
        if (Number(state.viewedCaseId) === caseId) state.viewedCaseId = null;
        renderCaseEditor();
        renderCases();
      }
    });
  });

  [...el.docsCasesList.querySelectorAll('[data-case-id]')].forEach((node) => {
    node.addEventListener('click', () => {
      if (state.caseEditorOpen) return;
      state.viewedCaseId = Number(node.dataset.caseId);
      renderCases();
      renderCaseEditor();
    });
  });
}

function docsCard(d) {
  return `
    <div class="item" data-doc-id="${d.doc_id}">
      <strong>${d.title || '-'}</strong><br />
      <span class="small">${d.department_id || '-'} | ${d.shared_at || '-'}</span>
    </div>`;
}

function renderDocs() {
  el.docsList.innerHTML = state.docs.items.length
    ? state.docs.items.map(docsCard).join('')
    : '';
  if (!state.docs.items.length) {
    el.docDetail.innerHTML = '';
  }
  [...el.docsList.querySelectorAll('[data-doc-id]')].forEach((node) => {
    node.addEventListener('click', async () => {
      const docId = Number(node.dataset.docId);
      const res = await post('shared_doc_detail', { docId });
      if (!res.ok) return;
      const d = res.data;
      el.docDetail.innerHTML = `
        <b>${d.title || '-'}</b><br />
        ${t('department', 'Department')}: ${d.department_id || '-'}<br />
        ${t('patient_code', 'Patient ID')}: ${d.patient_code || '-'}<br />
        ${t('created_by', 'Created By')}: ${d.created_by_name || '-'}<br />
        ${t('signed_by', 'Signed By')}: ${d.signed_by_name || '-'}<br />
        ${t('signed_at', 'Signed At')}: ${d.signed_at || '-'}<hr />
        ${d.description || '-'}
      `;
    });
  });
}

function docsPatientCard(p) {
  const active = state.docsSelectedPatientId === p.id ? ' active' : '';
  return `
    <div class="item${active}" data-doc-patient-id="${p.id}">
      <strong>${p.patient_code || '-'}</strong> - ${(p.firstname || '')} ${(p.lastname || '')}<br />
      <span class="small">${t('dob', 'DOB')}: ${p.dob || '-'} | ${t('created_at', 'Created')}: ${p.created_at || '-'}</span>
    </div>`;
}

function docsPatientFormCard(form) {
  const signed = Number(form.signed) === 1;
  return `
    <div class="docs-patient-form-card" data-doc-form-id="${form.id}">
      <strong>${form.title || '-'}</strong><br />
      <span class="small">${t('template', 'Template')}: ${form.template_key || '-'} | ${t('created_at', 'Created')}: ${form.created_at || '-'}</span><br />
      <span class="small">${t('status', 'Status')}: ${signed ? t('signed', 'Signed') : t('unsigned', 'Unsigned')}</span>
      <div class="docs-patient-form-actions">
        <button class="btn" data-doc-form-action="edit" data-form-id="${form.id}">${t('edit', 'Edit')}</button>
        <button class="btn danger" data-doc-form-action="delete" data-form-id="${form.id}">${t('delete', 'Delete')}</button>
      </div>
    </div>`;
}

function renderDocsPatientDetail() {
  const items = state.patients?.items || [];
  const selected = items.find((x) => x.id === state.docsSelectedPatientId);

  if (!selected) {
    el.docDetail.innerHTML = `<div class="small">${t('no_selection', 'No selection')}</div>`;
    return;
  }

  const formsHtml = (state.docsPatientForms.items || []).length
    ? state.docsPatientForms.items.map(docsPatientFormCard).join('')
    : `<div class="small">${t('no_results', 'No results')}</div>`;

  el.docDetail.innerHTML = `
    <div class="docs-patient-sheet">
      <div class="docs-patient-meta">
        <b>${selected.patient_code || '-'}</b><br />
        ${selected.firstname || ''} ${selected.lastname || ''}<br />
        ${t('dob', 'DOB')}: ${selected.dob || '-'}<br />
        ${t('created_at', 'Created')}: ${selected.created_at || '-'}<br />
        ${t('notes', 'Notes')}: ${selected.notes || '-'}
      </div>
      <div class="docs-patient-section-title">${t('forms', 'Forms')}</div>
      <div class="docs-patient-forms-list">${formsHtml}</div>
      <div class="docs-patient-actions">
        <button id="docsDeletePatientBtn" class="btn danger">${t('delete_patient', 'Delete Patient')}</button>
        <button id="docsCreateFormBtn" class="btn">${t('create_form', 'Create Form')}</button>
      </div>
    </div>`;

  const deleteBtn = document.getElementById('docsDeletePatientBtn');
  if (deleteBtn) {
    deleteBtn.addEventListener('click', async () => {
      const res = await post('delete_patient', { patientId: selected.id });
      if (!res.ok) return;
      state.docsPatientForms = { items: [], page: 1, totalPages: 1 };
      await loadPatients(1, el.docsPatientsSearch?.value || '');
    });
  }

  const createFormBtn = document.getElementById('docsCreateFormBtn');
  if (createFormBtn) {
    createFormBtn.addEventListener('click', async () => {
      state.selectedPatient = selected;
      openArchiveWorkspace('formsTab', { returnToDocsPanel: 'patients' });
      renderPatients();
      await loadHistory(1);
      await loadForms(1);
      resetFormEditor();
    });
  }

  [...el.docDetail.querySelectorAll('[data-doc-form-action]')].forEach((node) => {
    node.addEventListener('click', async (e) => {
      e.stopPropagation();
      const action = node.dataset.docFormAction;
      const formId = Number(node.dataset.formId);
      const form = (state.docsPatientForms.items || []).find((item) => Number(item.id) === formId);
      if (!form) return;

      if (action === 'edit') {
        state.selectedPatient = selected;
        openArchiveWorkspace('formsTab', { returnToDocsPanel: 'patients' });
        renderPatients();
        await loadHistory(1);
        await loadForms(1);
        startEditingForm(form);
      }

      if (action === 'delete') {
        const res = await post('delete_form', { formId });
        if (!res.ok) return;
        await loadDocsPatientForms(selected.id);
      }
    });
  });

  [...el.docDetail.querySelectorAll('[data-doc-form-id]')].forEach((node) => {
    node.addEventListener('click', () => {
      state.docsOpenedFormId = Number(node.dataset.docFormId);
      state.docsReturnPanel = 'patients';
      setDocsPanel('report');
    });
  });
}

function renderDocsOpenedFormPage() {
  const selected = (state.patients?.items || []).find((x) => x.id === state.docsSelectedPatientId);
  const openedForm = (state.docsPatientForms.items || []).find((item) => Number(item.id) === Number(state.docsOpenedFormId));
  if (!selected || !openedForm) {
    state.docsReturnPanel = 'patients';
    setDocsPanel('patients');
    return;
  }
  const signed = Number(openedForm.signed) === 1;
  el.docDetail.innerHTML = `
    <div class="docs-opened-form-page">
      <div class="docs-patient-section-title">${openedForm.title || '-'}</div>
      <div class="small">${selected.patient_code || '-'} - ${selected.firstname || ''} ${selected.lastname || ''}</div>
      <div class="docs-patient-form-preview">
        <div class="small">${t('template', 'Template')}: ${openedForm.template_key || '-'}</div>
        <div class="small">${t('created_by', 'Created By')}: ${openedForm.created_by_name || '-'}</div>
        <div class="small">${t('created_at', 'Created')}: ${openedForm.created_at || '-'}</div>
        <div class="small">${t('status', 'Status')}: ${signed ? t('signed', 'Signed') : t('unsigned', 'Unsigned')}</div>
        <div class="small">${t('signed_by', 'Signed By')}: ${openedForm.signed_by_name || '-'}</div>
        <div class="small">${t('signed_at', 'Signed At')}: ${openedForm.signed_at || '-'}</div>
        <div class="docs-patient-form-preview-body">${openedForm.description || '-'}</div>
      </div>
      <div class="docs-patient-form-actions">
        <button id="docsOpenedEditBtn" class="btn">${t('edit', 'Edit')}</button>
        ${signed ? `<button id="docsOpenedTranscribeBtn" class="btn">${t('transcribe_form', 'Trascrivi Documento')}</button>` : ''}
        <button id="docsOpenedDeleteBtn" class="btn danger">${t('delete', 'Delete')}</button>
      </div>
    </div>`;

  const editBtn = document.getElementById('docsOpenedEditBtn');
  if (editBtn) {
    editBtn.addEventListener('click', async () => {
      state.selectedPatient = selected;
      openArchiveWorkspace('formsTab', { returnToDocsPanel: 'patients' });
      renderPatients();
      await loadHistory(1);
      await loadForms(1);
      startEditingForm(openedForm);
    });
  }

  const deleteBtn = document.getElementById('docsOpenedDeleteBtn');
  if (deleteBtn) {
    deleteBtn.addEventListener('click', async () => {
      const res = await post('delete_form', { formId: openedForm.id });
      if (!res.ok) return;
      state.docsOpenedFormId = null;
      state.docsReturnPanel = 'patients';
      setDocsPanel('patients');
      await loadDocsPatientForms(selected.id);
    });
  }

  const transcribeBtn = document.getElementById('docsOpenedTranscribeBtn');
  if (transcribeBtn) {
    transcribeBtn.addEventListener('click', async () => {
      await post('transcribe_form', { formId: openedForm.id });
    });
  }
}

async function loadDocsPatientForms(patientId) {
  if (!patientId) {
    state.docsOpenedFormId = null;
    state.docsPatientForms = { items: [], page: 1, totalPages: 1 };
    renderDocsPatientDetail();
    return;
  }
  const res = await post('forms', { page: 1, patientId });
  if (!res.ok) {
    state.docsOpenedFormId = null;
    state.docsPatientForms = { items: [], page: 1, totalPages: 1 };
    renderDocsPatientDetail();
    return;
  }
  state.docsPatientForms = res.data;
  renderDocsPatientDetail();
}

function renderDocsPatients() {
  const items = state.patients?.items || [];
  el.docsPatientsList.innerHTML = items.length
    ? items.map(docsPatientCard).join('')
    : `<div class="small">${t('no_results', 'No results')}</div>`;

  if (!items.find((x) => x.id === state.docsSelectedPatientId)) {
    state.docsSelectedPatientId = items[0] ? items[0].id : null;
  }
  renderDocsPatientDetail();

  [...el.docsPatientsList.querySelectorAll('[data-doc-patient-id]')].forEach((node) => {
    node.addEventListener('click', async () => {
      state.docsSelectedPatientId = Number(node.dataset.docPatientId);
      state.docsOpenedFormId = null;
      state.docsPatientForms = { items: [], page: 1, totalPages: 1 };
      renderDocsPatients();
      await loadDocsPatientForms(state.docsSelectedPatientId);
    });
  });
}

async function submitDocsPatientForm() {
  const name = el.docsRegFullName ? el.docsRegFullName.value : '';
  const parsed = splitPatientName(name);
  const dob = el.docsRegDob ? el.docsRegDob.value : '';
  const job = el.docsRegProfession ? el.docsRegProfession.value.trim() : '';
  const sex = el.docsRegSex ? el.docsRegSex.value.trim() : '';
  const history = el.docsRegHistory ? el.docsRegHistory.value.trim() : '';
  const targetServerId = el.docsRegServerId && el.docsRegServerId.value ? Number(el.docsRegServerId.value) : null;

  if (!parsed.firstname || !parsed.lastname) {
    setDocsStatus(t('errors.invalid_data', 'Dati non validi'), false);
    return;
  }

  const notesChunks = [];
  if (job) notesChunks.push(`Professione: ${job}`);
  if (sex) notesChunks.push(`Sesso: ${sex}`);
  if (history) notesChunks.push(history);

  const res = await post('create_patient', {
    targetServerId,
    firstname: parsed.firstname,
    lastname: parsed.lastname,
    dob,
    notes: notesChunks.join(' | ')
  });

  if (!res.ok) {
    setDocsStatus(res.error || t('errors.generic', 'Errore'), false);
    return;
  }
  if (res.data?.patients) state.patients = res.data.patients;
  if (res.data?.history) state.history = res.data.history;
  setDocsStatus(res.data?.message || t('notify.patient_created', 'Paziente registrato'), true);
  resetDocsPatientForm();
  setDocsPanel('patients');
  state.docsPatientForms = { items: [], page: 1, totalPages: 1 };
  renderDocsPatients();
  await loadDocsPatientForms(state.docsSelectedPatientId);
}

async function loadPatients(page = 1, searchValue = null) {
  const search = searchValue !== null
    ? searchValue
    : (state.mode === 'docs' && state.docsPanel === 'patients'
      ? (el.docsPatientsSearch?.value || '')
      : (el.patientSearch?.value || ''));
  const res = await post('patients', { page, search });
  if (!res.ok) return;
  state.patients = res.data;
  if (state.selectedPatient) {
    state.selectedPatient = state.patients.items.find((x) => x.id === state.selectedPatient.id) || null;
  }
  renderPatients();
  if (state.mode === 'docs' && state.docsPanel === 'patients') {
    renderDocsPatients();
    await loadDocsPatientForms(state.docsSelectedPatientId);
  }
}

async function loadHistory(page = 1) {
  const res = await post('history', { page, patientId: state.selectedPatient ? state.selectedPatient.id : null });
  if (!res.ok) return;
  state.history = res.data;
  renderHistory();
}

async function loadForms(page = 1) {
  const res = await post('forms', { page, patientId: state.selectedPatient ? state.selectedPatient.id : null });
  if (!res.ok) return;
  state.forms = res.data;
  renderForms();
  wireFormActions();
}

async function loadCases(page = 1) {
  const res = await post('cases', { page });
  if (!res.ok) return;
  state.cases = res.data;
  renderCases();
  renderCaseEditor();
}

async function loadDocs(page = 1) {
  const res = await post('shared_docs', { page });
  if (!res.ok) return;
  state.docs = res.data;
  renderDocs();
}

function wireFormActions() {
  [...el.formsList.querySelectorAll('[data-action]')].forEach((node) => {
    node.addEventListener('click', async (e) => {
      e.stopPropagation();
      const action = node.dataset.action;
      const formId = Number(node.dataset.id);

      if (action === 'sign') {
        playSignSound();
        await post('sign_form', { formId });
        await loadForms(state.forms.page);
        await loadHistory(1);
      }

      if (action === 'delete') {
        await post('delete_form', { formId });
        await loadForms(state.forms.page);
      }

      if (action === 'share') {
        await post('share_form', { formId });
      }
    });
  });
}

function playSignSound() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(520, ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(180, ctx.currentTime + 0.22);
    gain.gain.setValueAtTime(0.0001, ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.11, ctx.currentTime + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.25);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + 0.25);
  } catch (_) {}
}

el.tabs.forEach((tab) => {
  tab.addEventListener('click', () => {
    el.tabs.forEach((x) => x.classList.remove('active'));
    el.tabContents.forEach((x) => x.classList.remove('active'));
    tab.classList.add('active');
    document.getElementById(tab.dataset.tab).classList.add('active');
  });
});

if (el.docsAddPatient) {
  el.docsAddPatient.addEventListener('click', () => {
    setDocsStatus('', true);
    setDocsPanel('add');
  });
}
if (el.docsPatients) {
  el.docsPatients.addEventListener('click', async () => {
    setDocsPanel('patients');
    await loadPatients(1);
  });
}
if (el.docsArchive) {
  el.docsArchive.addEventListener('click', async () => {
    state.viewedCaseId = null;
    resetCaseEditor(false);
    setDocsPanel('archive');
    await loadCases(1);
  });
}
if (el.docsCreateCaseBtn) {
  el.docsCreateCaseBtn.addEventListener('click', () => resetCaseEditor(true));
}
if (el.docsCancelCaseBtn) {
  el.docsCancelCaseBtn.addEventListener('click', () => resetCaseEditor(false));
}
if (el.docsReadCaseEditBtn) {
  el.docsReadCaseEditBtn.addEventListener('click', () => {
    const caseFile = (state.cases.items || []).find((item) => Number(item.id) === Number(state.viewedCaseId));
    if (!caseFile) return;
    startEditingCase(caseFile);
  });
}
if (el.docsTranscribeCaseBtn) {
  el.docsTranscribeCaseBtn.addEventListener('click', async () => {
    if (!state.viewedCaseId) return;
    await post('transcribe_case', { caseId: state.viewedCaseId });
  });
}
if (el.docsCloseCaseViewBtn) {
  el.docsCloseCaseViewBtn.addEventListener('click', () => {
    state.viewedCaseId = null;
    renderCases();
    renderCaseEditor();
  });
}
if (el.docsSaveCaseBtn) {
  el.docsSaveCaseBtn.addEventListener('click', async () => {
    const activeCaseId = state.editingCaseId;
    const payload = {
      title: el.docsCaseTitleInput ? el.docsCaseTitleInput.value : '',
      description: el.docsCaseDescription ? el.docsCaseDescription.value : ''
    };
    if (state.editingCaseId) payload.caseId = state.editingCaseId;
    const res = await post(state.editingCaseId ? 'update_case' : 'create_case', payload);
    if (!res.ok) return;
    if (res.data?.cases) state.cases = res.data.cases;
    state.viewedCaseId = activeCaseId || state.cases.items?.[0]?.id || null;
    resetCaseEditor(false);
    renderCases();
  });
}
if (el.docsRegisterBtn) {
  el.docsRegisterBtn.addEventListener('click', submitDocsPatientForm);
}
if (el.docsPatientsSearchBtn) {
  el.docsPatientsSearchBtn.addEventListener('click', () => loadPatients(1, el.docsPatientsSearch.value || ''));
}
if (el.docsPatientForm) {
  [...el.docsPatientForm.querySelectorAll('input')].forEach((node) => {
    node.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') submitDocsPatientForm();
    });
  });
}
if (el.docsPatientsSearch) {
  el.docsPatientsSearch.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') loadPatients(1, el.docsPatientsSearch.value || '');
  });
}
if (el.docsBackBtn) {
  el.docsBackBtn.addEventListener('click', () => {
    if (state.docsPanel === 'report') {
      const targetPanel = state.docsReturnPanel || 'patients';
      state.docsReturnPanel = null;
      setDocsPanel(targetPanel);
      return;
    }
    state.viewedCaseId = null;
    resetCaseEditor(false);
    setDocsPanel('home');
  });
}
if (el.archiveBackBtn) {
  el.archiveBackBtn.addEventListener('click', async () => {
    const targetPanel = state.archiveReturnPanel || 'home';
    state.archiveReturnPanel = null;
    resetFormEditor();
    show('docs');
    setDocsPanel(targetPanel);
    if (targetPanel === 'patients') {
      renderDocsPatients();
      await loadDocsPatientForms(state.docsSelectedPatientId);
    } else if (targetPanel === 'archive') {
      state.viewedCaseId = null;
      resetCaseEditor(false);
      await loadCases(1);
    }
  });
}
if (el.transcriptCloseBtn) {
  el.transcriptCloseBtn.addEventListener('click', () => post('close'));
}

el.searchPatientBtn.addEventListener('click', () => loadPatients(1));
el.patientsPrev.addEventListener('click', () => loadPatients(Math.max(1, state.patients.page - 1)));
el.patientsNext.addEventListener('click', () => loadPatients(Math.min(state.patients.totalPages || 1, state.patients.page + 1)));
el.historyPrev.addEventListener('click', () => loadHistory(Math.max(1, state.history.page - 1)));
el.historyNext.addEventListener('click', () => loadHistory(Math.min(state.history.totalPages || 1, state.history.page + 1)));
el.formsPrev.addEventListener('click', () => loadForms(Math.max(1, state.forms.page - 1)));
el.formsNext.addEventListener('click', () => loadForms(Math.min(state.forms.totalPages || 1, state.forms.page + 1)));
if (el.docsCasesPrev) el.docsCasesPrev.addEventListener('click', () => loadCases(Math.max(1, state.cases.page - 1)));
if (el.docsCasesNext) el.docsCasesNext.addEventListener('click', () => loadCases(Math.min(state.cases.totalPages || 1, state.cases.page + 1)));

el.formTemplate.addEventListener('change', () => {
  const option = el.formTemplate.selectedOptions[0];
  if (!option) return;
  el.formTitleInput.value = option.dataset.title || '';
});

if (el.cancelFormEditBtn) {
  el.cancelFormEditBtn.addEventListener('click', () => resetFormEditor());
}

el.createPatientBtn.addEventListener('click', async () => {
  const res = await post('create_patient', {
    targetServerId: el.targetServerId.value ? Number(el.targetServerId.value) : null,
    firstname: el.patientFirstName.value,
    lastname: el.patientLastName.value,
    dob: el.patientDob.value,
    notes: el.patientNotes.value
  });
  if (!res.ok) return;
  if (res.data.patients) state.patients = res.data.patients;
  if (res.data.history) state.history = res.data.history;
  renderPatients();
  renderHistory();
  el.targetServerId.value = '';
  el.patientFirstName.value = '';
  el.patientLastName.value = '';
  el.patientDob.value = '';
  el.patientNotes.value = '';
});

el.deletePatientBtn.addEventListener('click', async () => {
  if (!state.selectedPatient) return;
  const res = await post('delete_patient', { patientId: state.selectedPatient.id });
  if (!res.ok) return;
  state.selectedPatient = null;
  if (res.data.patients) state.patients = res.data.patients;
  if (res.data.history) state.history = res.data.history;
  if (res.data.forms) state.forms = res.data.forms;
  renderPatients();
  renderHistory();
  renderForms();
});

el.createFormBtn.addEventListener('click', async () => {
  if (!state.selectedPatient) return;
  const payload = {
    patientId: state.selectedPatient.id,
    templateKey: el.formTemplate.value,
    title: el.formTitleInput.value,
    description: el.formDescription.value
  };
  if (state.editingFormId) payload.formId = state.editingFormId;
  const res = await post(state.editingFormId ? 'update_form' : 'create_form', payload);
  if (!res.ok) return;
  if (res.data.forms) state.forms = res.data.forms;
  if (res.data.history) state.history = res.data.history;
  resetFormEditor();
  renderForms();
  renderHistory();
  wireFormActions();
});

window.addEventListener('message', (event) => {
  const msg = event.data;
  if (!msg || !msg.action) return;

  if (msg.action === 'close') {
    hide();
    return;
  }

  if (msg.action === 'openArchive') {
    state.archiveReturnPanel = null;
    resetFormEditor();
    state.viewedCaseId = null;
    resetCaseEditor(false);
    state.locale = msg.locale || {};
    state.department = msg.payload.department;
    state.doctor = msg.payload.doctor;
    state.templates = msg.payload.templates || [];
    state.selectedPatient = null;
    state.patients = msg.payload.patients || state.patients;
    state.history = msg.payload.history || state.history;
    state.forms = msg.payload.forms || state.forms;
    setUiText();
    show('docs');
    setDocsPanel('home');
    el.subTitle.textContent = `${t('department', 'Department')}: ${state.department?.label || '-'} | ${t('doctor', 'Doctor')}: ${state.doctor?.fullname || '-'}`;
    renderTemplates();
    renderPatients();
    renderHistory();
    renderForms();
    wireFormActions();
    return;
  }

  if (msg.action === 'openDocs') {
    state.viewedCaseId = null;
    resetCaseEditor(false);
    state.locale = msg.locale || {};
    state.docs = msg.payload || state.docs;
    setUiText();
    show('docs');
    el.subTitle.textContent = '';
    el.docDetail.innerHTML = '';
    resetDocsPatientForm();
    setDocsPanel('archive');
    loadCases(1);
    return;
  }

  if (msg.action === 'openCaseTranscript') {
    state.locale = msg.locale || {};
    state.transcriptCase = msg.payload || {};
    setUiText();
    el.subTitle.textContent = '';
    renderTranscriptSheet();
    show('transcript');
  }
});

window.addEventListener('keydown', (e) => { if (e.key === 'Escape') post('close'); });









