# CLAUDE.md — local-ai-suite

## Stack
- **Backend:** `llama-server` (llama.cpp) for serving GGUF models.
- **Frontend / Agents:** Claude Code (CLI Agent), VS Code with Continue.dev (IDE Copilot).
- **Models:** Optimized Qwen 2.5/3.5 (Unsloth), `nomic-embed-text` for RAG.
- **Infrastructure:** Apple Silicon (M4 preferred, 24GB RAM optimization).
- **Orchestration:** Bash scripts (`handle_project.sh`), `.env` configuration.

## Comandi
- **Setup:** `./handle_project.sh install` (installa dipendenze, VS Code, Claude Code).
- **Check-up:** `./handle_project.sh check` (verifica integrità sistema e modelli).
- **Avvio Suite:** `./handle_project.sh launch` (backend + VS Code + Claude Code).
- **Beast Mode:** `./handle_project.sh beast` (Claude Code autonomo senza conferme).
- **Modelli:** `./handle_project.sh setup-models` (selettore interattivo), `./handle_project.sh pull <repo>` (download da HuggingFace).
- **Config:** `./handle_project.sh config` (rigenera config Continue.dev).
- **Manutenzione:** `./handle_project.sh update` (aggiorna software), `./handle_project.sh stop` (ferma backend).

## Architettura
- **Orchestrazione:** Lo script `handle_project.sh` funge da controller centrale, gestendo il ciclo di vita del server Llama e la sincronizzazione delle configurazioni per l'IDE.
- **Mocking API:** Il server locale utilizza l'alias `claude-3-5-sonnet-20241022` per essere compatibile "out-of-the-box" con Claude Code senza validazioni cloud.
- **Ottimizzazione Risorse:** 
  - **GPU Offload:** `-ngl 26` (lascia 6 layer alla CPU su M4 per fluidità UI).
  - **Memory:** KV Cache `q8_0`, Batch size `1024`, Flash Attention abilitata.
- **Config Workflow:** `.env` → `handle_project.sh` → `continue.config.template.json` → `~/.continue/config.json`.

## File critici
- `handle_project.sh`: Logica core di gestione del progetto.
- `.env`: Variabili di ambiente, modelli assegnati e path `MODELS_DIR`.
- `continue.config.template.json`: Template per l'integrazione VS Code.
- `docs/OPTIMIZATION_SHEET.md`: Linee guida per performance M4.
- `docs/V2/README.md`: Storico problemi di stabilità e roadmap evolutiva.

## Convenzioni
- **Naming:** Usa snake_case per script e variabili interne; CAPS_LOCK per variabili `.env`.
- **Modelli:** I file GGUF si trovano in `/Users/paolo.leoni/git/models` (cartella esterna al repo). Il path è configurabile tramite `MODELS_DIR` in `.env`.
- **Aggiungere un modello:** scaricarlo con `./handle_project.sh pull <repo>` oppure copiarlo manualmente in `$MODELS_DIR`.
- **Logs:** Monitorare `/tmp/llama_server.log` per debug inferenza o errori di caricamento.
- **Safety:** Usare la "Beast Mode" con cautela; per task complessi preferire `launch` con supervisione.

## What not to do
- **Non saturare la GPU:** Mai usare `-ngl 32` (o il valore massimo dei layer) se si lavora interattivamente; causa stuttering della UI di macOS.
- **Evitare Disallineamento Context:** Mai impostare una `contextLength` in Continue.dev superiore a quella del `llama-server` (rischio amnesia AI).
- **No Hardcoding Porte:** Non assumere che la porta `8080` sia sempre libera; controllare lo stato con `check` prima del `launch`.
- **Evitare Cache Fragili:** Non usare quantizzazioni della cache inferiori a `q8_0` (es. `q4_0`) su contesti lunghi per non degradare la coerenza LOGICA.
- **Nessun Silenzio su Crash:** Se Claude Code non risponde, non assumere problemi di rete; verificare sempre l'endpoint locale `/v1/models`.
