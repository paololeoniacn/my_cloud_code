# local-ai-suite

Suite di sviluppo locale con modelli AI, senza vincoli di token.

**Stack:** Ollama · Claude Code · VS Code · Continue.dev

## Setup rapido

```bash
# 1. Clona il repo
git clone <repo-url> local-ai-suite && cd local-ai-suite

# 2. Rendi eseguibile lo script
chmod +x handle_project.sh

# 3. Crea il tuo .env
cp .env.example .env
# edita .env con i tuoi modelli preferiti

# 4. Installa tutto
./handle_project.sh install

# 5. Lancia
./handle_project.sh launch
```

## Comandi

| Comando | Descrizione |
|---|---|
| `./handle_project.sh check` | Verifica stato sistema e componenti |
| `./handle_project.sh install` | Installa Ollama, Claude Code, VS Code, Continue.dev, modelli |
| `./handle_project.sh launch` | Avvia la suite completa |
| `./handle_project.sh update` | Aggiorna tutti i componenti |
| `./handle_project.sh stop` | Ferma Ollama |
| `./handle_project.sh models` | Scarica/aggiorna solo i modelli |
| `./handle_project.sh setup-models`| Scegli interattivamente quali modelli assegnare |
| `./handle_project.sh config` | Rigenera config Continue.dev |

## Configurazione

Tutto in `.env` (non committato). Vedi `.env.example` per i valori disponibili.

Modelli consigliati per M4 24GB:

- Agente: `qwen2.5:14b-instruct-q4_K_M` (già presente) o `qwen2.5-coder:32b`
- Autocomplete: `qwen2.5-coder:7b-instruct` (già presente)
- Embeddings: `nomic-embed-text:latest` (già presente)

### Cambiare i modelli (Interattivo)
Se hai scaricato nuovi modelli tramite Ollama (`ollama run <nome>`) e desideri assegnarli alla suite, non è più necessario modificare manualmente i file. Puoi lanciare:

```bash
./handle_project.sh setup-models
```
Questo comando farà comparire un menù guidato nel terminale, rilevando i modelli disponibili sulla tua macchina e permettendoti di assegnarli dinamicamente ai ruoli di *Agente* (Primario), *Autocompletamento* (Continue.dev) o *Embeddings* (RAG). Il comando aggiornerà automaticamente il file `.env` e la configurazione `config.json`.
*Nota bene: se la suite è attualmente avviata, devi chiudere tutto e lanciare di nuovo `launch` perché le modifiche abbiano effetto.*

## Come funziona

```
.env  ──▶  handle_project.sh  ──▶  Ollama (serve modello)
                                ──▶  VS Code + Continue.dev (autocomplete)
                                ──▶  Claude Code (agente, punta a Ollama)
```

Claude Code usa le variabili `ANTHROPIC_BASE_URL` e `ANTHROPIC_AUTH_TOKEN`
per puntare a Ollama invece che ai server Anthropic — tutto locale.

## Come usare la suite

Dopo aver lanciato con successo `./handle_project.sh launch`, avrai a disposizione due interfacce per lavorare con i modelli:

### 1. Claude Code (L'Agente nel Terminale)
Nel terminale in cui hai digitato il comando `launch`, si aprirà una sessione interattiva contrassegnata da `>_ Claude Code`. 
Puoi usare questo spazio scrivendo in linguaggio naturale (es. *"Crea uno script python HelloWorld in una cartella src e lancialo"*). Sentendosi autorizzato al ruolo di agente, userà i comandi del computer e indagherà sui file in modo totalmente autonomo.

### 2. Continue.dev (Il Copilota in VS Code)
Contemporaneamente, si aprirà il progetto in *VS Code*. Utilizzando l'estensione **Continue** avrai due feature principali:
* **Autocompletamento** (Tab Autocomplete): mentre scrivi, Continue utilizzerà piccoli modelli leggeri (nel nostro caso `qwen2.5-coder:7b`) per suggerirti istantaneamente pezzi di codice in background (stile GitHub Copilot).
* **Chat e RAG (Sidebar o Panel)**: nel menu laterale di VS Code avrai una chat in cui puoi utilizzare la fanzionalità Context (@). Se usi `@Codebase`, lo strumento indicizzerà il tuo progetto con il modello Embedding (`nomic-embed-text`), e potrai poi porre domande trasversali sul tuo codice sfruttando il "ragionamento" logico del modello Primario (`qwen2.5:14b`).
