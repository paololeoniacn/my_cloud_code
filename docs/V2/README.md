# 🚀 Local AI Suite V2: Suggerimenti per l'Evoluzione

Questa directory contiene la visione e i possibili miglioramenti per la versione successiva (V2) del progetto local-ai-suite.

---

## 🛠️ Suggerimenti di Implementazione

Per scalare il progetto e migliorarne l'usabilità, si suggeriscono i seguenti step evolutivi:

### 1. Unificazione del Contesto (Context Consistency)
- **Problema:** Attualmente esiste una differenza tra i `32768` token avviati da `llama-server` e i `131072` nel template di `Continue.dev`.
- **V2:** Implementare una variabile globale `LLAMA_CONTEXT_WINDOW` nel `.env` usata sia dallo script di avvio che dal generatore di configurazione di Continue.

### 2. Gestione Dinamica delle Porte (Port Management)
- **Problema:** La porta `8080` è hard-coded e soggetta a conflitti.
- **V2:** Aggiungere `LLAMA_PORT` nel `.env`. Lo script `check` dovrebbe verificare se la porta è libera prima di tentare l'avvio.

### 3. Log Rotation & Management
- **Problema:** Il log in `/tmp/` può diventare molto grande ed è difficile da consultare storicamente.
- **V2:** Integrare un setup di logging ciclico o spostare i log in una cartella persistente (`logs/`) ignorata da Git, facilitando il debug post-mortem.

### 4. Health Check e Auto-Healing
- **Problema:** Se il server crasha silenziosamente, Claude Code smette di rispondere senza errori chiari.
- **V2:** Implementare un mini-monitor in background che verifica l'endpoint `/v1/models` ogni 60 secondi e tenta il riavvio se necessario.

### 5. Multi-Modello & Switching Rapido
- **Problema:** Per passare da un modello "Thinking" a uno "Coder", bisogna modificare il `.env` e riavviare tutto.
- **V2:** Aggiungere un comando `./handle_project.sh switch <model>` per cambiare istantaneamente il server Llama senza riavviare VS Code.

---

## 📈 Tabella delle Priorità

| Feature | Priorità | Sforzo | Beneficio |
| :--- | :--- | :--- | :--- |
| Unificazione Context | Alta | Basso | Molto Alto (Stabilità) |
| DINAMIC PORT | Media | Basso | Prevenzione Errori |
| Health Check | Media | Medio | Affidabilità |
| Multi-Model Switch | Bassa | Alto | Produttività |

---

> [!IMPORTANT]
> Mantenere il focus sull'architettura Apple Silicon (M4) per garantire che queste nuove feature non degradino le prestazioni della UI.
