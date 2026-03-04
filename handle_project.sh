#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  handle_project.sh — local-ai-suite manager
#  Gestisce: Ollama, Claude Code, Continue.dev, VS Code
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# Aggiunge PATH locale (dove si installa di default Claude Code)
export PATH="$HOME/.local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"
CONTINUE_TEMPLATE="$SCRIPT_DIR/continue.config.template.json"
CONTINUE_CONFIG="$HOME/.continue/config.json"

# ── Colori ──────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log_info()    { [[ "${LOG_LEVEL:-info}" != "quiet" ]] && echo -e "${BLUE}[INFO]${RESET}  $*" || true; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
log_section() { echo -e "\n${BOLD}${CYAN}▶ $*${RESET}"; }
log_debug()   { [[ "${LOG_LEVEL:-info}" == "debug" ]] && echo -e "  [debug] $*" || true; }

# ── Carica .env ─────────────────────────────────────────────────
load_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    log_warn ".env non trovato. Creo da .env.example..."
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    log_warn "Edita $ENV_FILE prima di continuare."
  fi
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
  log_debug "Env caricato da $ENV_FILE"
}

# ── Verifica dipendenze di sistema ─────────────────────────────
check_system() {
  log_section "Verifica sistema"
  local ok=true

  # macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    log_warn "Script ottimizzato per macOS. Procedere con cautela."
  fi

  # Homebrew
  if ! command -v brew &>/dev/null; then
    log_error "Homebrew non trovato. Installa da https://brew.sh"
    ok=false
  else
    log_ok "Homebrew $(brew --version | head -1)"
  fi

  # Node.js (richiesto da Claude Code)
  if ! command -v node &>/dev/null; then
    log_warn "Node.js non trovato (richiesto da Claude Code)"
    ok=false
  else
    local node_ver
    node_ver=$(node --version)
    log_ok "Node.js $node_ver"
  fi

  # Git
  if ! command -v git &>/dev/null; then
    log_warn "Git non trovato"
  else
    log_ok "Git $(git --version | awk '{print $3}')"
  fi

  $ok && log_ok "Sistema OK" || log_warn "Alcuni componenti mancanti — usa: $0 install"
}

# ── Verifica stato componenti ───────────────────────────────────
check_components() {
  log_section "Verifica componenti"
  load_env

  # Ollama
  if command -v ollama &>/dev/null; then
    log_ok "Ollama installato: $(ollama --version 2>/dev/null || echo 'versione sconosciuta')"
  else
    log_warn "Ollama NON installato"
  fi

  # Ollama running
  if curl -s "${OLLAMA_HOST}/api/tags" &>/dev/null; then
    log_ok "Ollama in esecuzione su ${OLLAMA_HOST}"
  else
    log_warn "Ollama NON in esecuzione"
  fi

  # Modelli
  if command -v ollama &>/dev/null; then
    local installed_models
    installed_models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)

    for model in "$PRIMARY_MODEL" "$AUTOCOMPLETE_MODEL" "$EMBEDDING_MODEL"; do
      if echo "$installed_models" | grep -qF "$model"; then
        log_ok "Modello presente: $model"
      else
        log_warn "Modello mancante: $model"
      fi
    done
  fi

  # Claude Code
  if command -v claude &>/dev/null; then
    log_ok "Claude Code installato: $(claude --version 2>/dev/null || echo 'ok')"
  else
    log_warn "Claude Code NON installato"
  fi

  # VS Code
  if command -v code &>/dev/null; then
    log_ok "VS Code installato: $(code --version 2>/dev/null | head -1)"
  else
    log_warn "VS Code NON installato (o 'code' non nel PATH)"
  fi

  # Continue.dev
  if code --list-extensions 2>/dev/null | grep -q "continue.continue"; then
    log_ok "Continue.dev installato"
  else
    log_warn "Continue.dev NON installato"
  fi

  # Continue config
  if [[ -f "$CONTINUE_CONFIG" ]]; then
    log_ok "Continue config presente: $CONTINUE_CONFIG"
  else
    log_warn "Continue config mancante (usa: $0 install per generarlo)"
  fi
}

# ── Installa tutto ──────────────────────────────────────────────
install_all() {
  log_section "Installazione componenti"
  load_env

  # 1. Ollama
  if ! command -v ollama &>/dev/null; then
    log_info "Installazione Ollama..."
    brew install ollama
    log_ok "Ollama installato"
  else
    log_ok "Ollama già presente"
  fi

  # 2. Node.js (LTS)
  if ! command -v node &>/dev/null; then
    log_info "Installazione Node.js..."
    brew install node
    log_ok "Node.js installato"
  else
    log_ok "Node.js già presente"
  fi

  # 3. VS Code
  if ! command -v code &>/dev/null; then
    log_info "Installazione VS Code..."
    brew install --cask visual-studio-code
    log_ok "VS Code installato"
  else
    log_ok "VS Code già presente"
  fi

  # 4. Claude Code
  if ! command -v claude &>/dev/null; then
    log_info "Installazione Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    log_ok "Claude Code installato"
  else
    log_ok "Claude Code già presente"
  fi

  # 5. Continue.dev extension
  if ! code --list-extensions 2>/dev/null | grep -q "continue.continue"; then
    log_info "Installazione Continue.dev..."
    code --install-extension continue.continue
    log_ok "Continue.dev installato"
  else
    log_ok "Continue.dev già presente"
  fi

  # 6. Pull modelli mancanti
  pull_models

  # 7. Genera Continue config
  generate_continue_config

  log_ok "\n✅ Installazione completata!"
}

# ── Assicura che Ollama sia avviato ─────────────────────────────
ensure_ollama_running() {
  if ! curl -s "${OLLAMA_HOST}/api/tags" &>/dev/null; then
    log_info "Avvio Ollama in background silenzioso..."
    nohup ollama serve > /dev/null 2>&1 &
    local retries=0
    until curl -s "${OLLAMA_HOST}/api/tags" &>/dev/null || [[ $retries -ge 10 ]]; do
      sleep 1; ((retries++))
    done
    log_ok "Ollama pronto su ${OLLAMA_HOST}"
  else
    log_ok "Ollama già in esecuzione"
  fi
}

# ── Pull modelli Ollama ─────────────────────────────────────────
pull_models() {
  log_section "Modelli Ollama"
  load_env
  ensure_ollama_running

  local installed_models
  installed_models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')

  for model in "$PRIMARY_MODEL" "$AUTOCOMPLETE_MODEL" "$EMBEDDING_MODEL"; do
    if echo "$installed_models" | grep -qF "$model"; then
      log_ok "Già presente: $model"
    else
      log_info "Download: $model ..."
      ollama pull "$model"
      log_ok "Scaricato: $model"
    fi
  done
}

# ── Genera Continue.dev config ──────────────────────────────────
generate_continue_config() {
  log_section "Continue.dev config"
  load_env

  mkdir -p "$HOME/.continue"

  # Sostituisce le variabili nel template
  sed \
    -e "s|\${PRIMARY_MODEL}|${PRIMARY_MODEL}|g" \
    -e "s|\${AUTOCOMPLETE_MODEL}|${AUTOCOMPLETE_MODEL}|g" \
    -e "s|\${EMBEDDING_MODEL}|${EMBEDDING_MODEL}|g" \
    -e "s|\${OLLAMA_HOST}|${OLLAMA_HOST}|g" \
    "$CONTINUE_TEMPLATE" > "$CONTINUE_CONFIG"

  log_ok "Config generata: $CONTINUE_CONFIG"
}

# ── Selezione interattiva modelli ───────────────────────────────
interactive_model_selection() {
  log_section "Configurazione interattiva modelli"
  load_env
  ensure_ollama_running

  # Estrai modelli in una lista pulita (rimuovi l'intestazione e prendi la prima colonna)
  local installed_models
  installed_models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')

  if [[ -z "$installed_models" ]]; then
    log_error "Nessun modello trovato in Ollama. Usa '$0 models' o '$0 install' prima."
    return 1
  fi

  # Converte la stringa in array
  local models_array=()
  while IFS= read -r line; do
    models_array+=("$line")
  done <<< "$installed_models"
  models_array+=("SALTA") # Opzione per saltare la selezione specifica

  # Funzione helper per modificare il .env e gestire l'input
  update_env_model() {
    local env_var_name=$1
    local title=$2
    local current_val=$3

    echo -e "\n${CYAN}>> $title${RESET} (Attuale: ${GREEN}$current_val${RESET})"
    PS3="Scegli un numero per $env_var_name (es. 1): "
    
    select choice in "${models_array[@]}"; do
      if [[ -n "$choice" ]]; then
        if [[ "$choice" == "SALTA" ]]; then
          log_info "Modifica saltata."
        elif [[ "$choice" == "$current_val" ]]; then
          log_info "Modello già impostato."
        else
          # Sostituisci nel file .env (usiamo perl per maggiore compatibilità sed cross-platform)
          perl -pi -e "s/^${env_var_name}=.*/${env_var_name}=${choice}/g" "$ENV_FILE"
          
          # Se la variabile non esisteva nel .env, la aggiungiamo
          if ! grep -q "^${env_var_name}=" "$ENV_FILE"; then
            echo "${env_var_name}=${choice}" >> "$ENV_FILE"
          fi
          log_ok "Impostato $env_var_name = $choice"
        fi
        break
      else
        echo "Opzione non valida. Riprova."
      fi
    done
  }

  echo -e "Qui puoi assegnare quali modelli già scaricati usare per la suite."
  update_env_model "PRIMARY_MODEL" "Modello Primario (Claude Code)" "${PRIMARY_MODEL:-none}"
  update_env_model "AUTOCOMPLETE_MODEL" "Modello Autocompletamento (Continue.dev)" "${AUTOCOMPLETE_MODEL:-none}"
  update_env_model "EMBEDDING_MODEL" "Modello Embedding (Continue.dev RAG)" "${EMBEDDING_MODEL:-none}"

  # Dopo la modifica, rigenera le configurazioni dipendenti
  log_info "\nRigenero file di configurazione..."
  load_env # ricarica i nuovi valori
  generate_continue_config

  log_ok "\nConfigurazione modelli completata!"
  log_warn "Se la suite (launch) è attualmente in esecuzione, riavviala per applicare le modifiche."
}

# ── Update ──────────────────────────────────────────────────────
update_all() {
  log_section "Aggiornamento componenti"
  load_env

  log_info "Aggiornamento Ollama..."
  if brew upgrade ollama 2>/dev/null; then
    log_ok "Ollama aggiornato"
    if pgrep -x ollama &>/dev/null; then
      log_info "Riavvio daemon Ollama in background per applicare l'aggiornamento..."
      pkill -x ollama || true
    fi
  else
    log_ok "Ollama già aggiornato"
  fi

  log_info "Aggiornamento Claude Code..."
  npm update -g @anthropic-ai/claude-code 2>/dev/null && log_ok "Claude Code aggiornato" \
    || log_warn "Impossibile aggiornare Claude Code via npm (potrebbe usare altro installer)"

  log_info "Aggiornamento Continue.dev..."
  code --install-extension continue.continue --force 2>/dev/null \
    && log_ok "Continue.dev aggiornato" || log_warn "Aggiornamento Continue.dev fallito"

  log_info "Aggiornamento modelli Ollama..."
  ensure_ollama_running
  for model in "$PRIMARY_MODEL" "$AUTOCOMPLETE_MODEL" "$EMBEDDING_MODEL"; do
    log_info "  Pull: $model"
    ollama pull "$model" && log_ok "  $model aggiornato"
  done

  log_ok "Update completato"
}

# ── Avvia la suite ──────────────────────────────────────────────
launch() {
  log_section "Avvio suite"
  load_env

  # Auto-update se abilitato
  if [[ "${AUTO_UPDATE:-false}" == "true" ]]; then
    log_info "AUTO_UPDATE abilitato — controllo aggiornamenti..."
    update_all
  fi

  # Avvia Ollama in background se non già in esecuzione
  ensure_ollama_running

  # Esporta variabili per Claude Code → Ollama
  export ANTHROPIC_AUTH_TOKEN=ollama
  export ANTHROPIC_API_KEY=""
  export ANTHROPIC_BASE_URL="${OLLAMA_HOST}"
  export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH}"

  # Apri VS Code
  local workspace="${WORKSPACE_PATH:-}"
  if [[ -z "$workspace" ]]; then
    echo ""
    read -rp ">> Inserisci il path del progetto da aprire (o premi Invio per la cartella corrente '.'): " workspace
    workspace="${workspace:-.}"
  fi

  # Espande il carattere ~ se l'utente lo ha inserito (es: ~/Documenti/Progetto)
  workspace="${workspace/#\~/$HOME}"

  log_info "Apertura VS Code: $workspace"
  code "$workspace"

  # Spostati nella cartella in modo che Claude Code lavori direttamente lì dentro
  cd "$workspace" || log_warn "Impossibile muoversi in $workspace, Claude Code userà la cartella corrente"


  # Avvia Claude Code (opzionale)
  echo ""
  read -rp ">> Vuoi avviare anche l'agente da terminale Claude Code? [y/N]: " start_claude
  if [[ "$start_claude" =~ ^[Yy] ]]; then
    log_info "Avvio Claude Code con modello: ${PRIMARY_MODEL}"
    log_info "(usa Ctrl+C per uscire)\n"
    claude --model "${PRIMARY_MODEL}"
  else
    log_ok "Claude Code ignorato. La suite è pronta per l'uso all'interno di VS Code con Continue.dev!"
  fi
}

# ── Stop ────────────────────────────────────────────────────────
stop() {
  log_section "Stop suite"
  if pgrep -x ollama &>/dev/null; then
    pkill -x ollama && log_ok "Ollama fermato"
  else
    log_info "Ollama non era in esecuzione"
  fi
}

# ── Help ────────────────────────────────────────────────────────
usage() {
  echo -e "
${BOLD}local-ai-suite — handle_project.sh${RESET}

${BOLD}Uso:${RESET}
  $0 <comando>

${BOLD}Comandi:${RESET}
  ${GREEN}check${RESET}      Verifica stato sistema e componenti
  ${GREEN}install${RESET}    Installa tutto (Ollama, Claude Code, VS Code, Continue.dev, modelli)
  ${GREEN}update${RESET}     Aggiorna tutti i componenti e modelli
  ${GREEN}launch${RESET}     Avvia la suite completa (Ollama + VS Code + Claude Code)
  ${GREEN}stop${RESET}       Ferma Ollama
  ${GREEN}models${RESET}     Scarica/aggiorna solo i modelli configurati in .env
  ${GREEN}setup-models${RESET} Configura dinamicamente quali modelli usare (interattivo)
  ${GREEN}config${RESET}     Rigenera il config di Continue.dev da template
  ${GREEN}help${RESET}       Mostra questo messaggio

${BOLD}Config:${RESET}
  Edita ${CYAN}.env${RESET} per cambiare modelli e impostazioni
  Template: ${CYAN}.env.example${RESET}
"
}

# ── Entry point ─────────────────────────────────────────────────
case "${1:-help}" in
  check)   check_system; check_components ;;
  install) install_all ;;
  update)  update_all ;;
  launch)  launch ;;
  stop)    stop ;;
  models)  pull_models ;;
  setup-models) interactive_model_selection ;;
  config)  generate_continue_config ;;
  help|--help|-h) usage ;;
  *)
    log_error "Comando sconosciuto: $1"
    usage
    exit 1
    ;;
esac
