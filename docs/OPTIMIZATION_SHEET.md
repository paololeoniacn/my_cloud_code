# 📋 Scheda di Ottimizzazione: Qwen-local (M4 Optimized)

Questa scheda riassume la configurazione "Best-Practice" per far girare modelli Qwen su hardware Apple Silicon (M4 24GB) mantenendo prestazioni elevate e stabilità del sistema operativo.

---

## 🚀 Parametri di Lancio (Llama-Server)

Usa questi flag per massimizzare il throughput e la reattività:

| Parametro | Valore Consigliato | Motivazione |
| :--- | :--- | :--- |
| **Model Alias** | `claude-3-5-sonnet-20241022` | Permette a tool come Claude Code di funzionare senza errori di validazione client. |
| **Context (`-c`)** | `32768` (o `65536`) | Equilibrio tra memoria occupata e capacità di ragionamento su file lunghi. |
| **GPU Offload (`-ngl`)** | `26` | Lascia ~6 layer sulla CPU per evitare lo stuttering dell'UI macOS (M4 con 32 layer totali). |
| **Batch Size (`-b`)** | `1024` | Ottimizza il prefill senza saturare la banda della memoria unificata. |
| **Flash Attention** | `--flash-attn` | Riduce drasticamente il costo computazionale dell'attenzione su contesti ampi. |
| **KV Cache Type** | `--cache-type-k q8_0 --cache-type-v q8_0` | Mantiene alta la qualità della cache per contesti lunghi (superiore a q4_0). |

---

## 🧠 Configurazione del Campionamento (Sampling)

Per un'agente di programmazione, la "deterniminatezza" è fondamentale. Usa questi valori per il modello Qwen 2.5/3.5:

- **Temperature:** `0.1` - `0.2` (Bassa per evitare divagazioni sintattiche)
- **Top-P:** `0.9`
- **Min-P:** `0.05` (Fondamentale per tagliare le allucinazioni "low-probability")
- **Repeat Penalty:** `1.05` - `1.1`

---

## 🛠️ Suggerimenti di Miglioramento (V2 Strategy)

Se stai costruendo un nuovo sistema, segui queste indicazioni per superare l'attuale "stato dell'arte":

1.  **Sincronizzazione Context IDE/Server:** Assicurati che il valore `contextLength` nell'IDE (es. Continue.dev) sia identico o inferiore a quello del server. Se l'IDE invia 100k token e il server ne legge 32k, l'AI perderà la memoria delle parti iniziali.
2.  **Health Check Silenzioso:** Implementa un loop di controllo `/v1/models`. Se il server non risponde entro 10 secondi, tenta un "hot-restart" dei processi Llama.
3.  **Prompt Engineering di Sistema:** Qwen risponde meglio se gli viene dato un ruolo esplicito: 
    > *"Sei un Senior Software Engineer specializzato in Apple Silicon. Rispondi in modo conciso, usa markdown e fornisci sempre codice eseguibile."*
4.  **Isolamento delle Risorse:** Se possibile, usa la priorità di processo (`nice -n -5`) per il server Llama, garantendo che i calcoli non vengano interrotti da update di sistema o altri background task.

---

## 📦 Stack Suggerito
- **Backend:** `llama-server` (llama.cpp)
- **Modello:** `Qwen2.5-Coder-32B-Instruct-GGUF` (se la RAM lo permette) o `Qwen2.5-9B-UD-Q4_K_M` (per velocità pura).
- **Proxy:** Facoltativo, per gestire multi-embedding o load balancing locale.
