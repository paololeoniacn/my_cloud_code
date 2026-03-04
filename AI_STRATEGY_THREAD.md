# 🧠 Strategia di Ottimizzazione AI Locale (M4 + Qwen 3.5 Unsloth)

Questo documento traccia il thread decisionale sull'architettura della suite AI locale, con l'obiettivo di trovare il perfetto equilibrio tra **velocità estrema**, **profondità di contesto (64k)** e **accuratezza logica**.

---

## 🛠️ Domande per l'Esperto (Validazione Tecnica)

Abbiamo configurato un server `llama.cpp` che processa il modello **Qwen 3.5 9B (Quantizzazione Q4_K_M)** su un **Mac M4 con 24GB di RAM Unificata**. Ecco i punti critici da validare:

### 1. Efficienza del Calcolo (Flash Attention)
> "Sull'architettura Apple M4, con un contesto di 64k token, l'attivazione della **Flash Attention** (`--flash-attn`) in `llama.cpp` garantisce un guadagno lineare o ci sono colli di bottiglia dovuti alla larghezza di banda della memoria unificata? È il flag ottimale per ridurre il *Time To First Token* (TTFT)?"

### 2. Gestione della Memoria (KV Cache Quantization)
> "Per massimizzare la velocità di generazione, ho impostato la **quantizzazione della Cache KV a q4_0** (`--cache-type-k q4_0` / `--cache-type-v q4_0`). Qual è l'impatto reale sulla *perplessità* dell'output rispetto a una cache f16? Vale la pena recuperare quel ~50% di VRAM occupata dal contesto?"

### 3. Orchestrazione degli Agenti (Batching)
> "Sto orchestrando agenti su un contesto da 64k token. Ha senso spingere il **Batch Size (`-b`) a 2048 o superiore** per velocizzare il caricamento della codebase, o rischio di saturare i core neurali e rallentare l'intera pipeline di inferenza durante la scansione iniziale (RAG/Codebase)?"

### 4. Ragionamento vs Velocità (Thinking Mode)
> "Per un modello 9B, il **Thinking Mode** (Reasoning) apporta un valore logico reale paragonabile ai modelli 'Large', o il costo in latenza e rumore nel contesto (monologhi interni) rende più efficiente un approccio 'Instruct' puro con un System Prompt molto severo?"

---

## 📥 Risposte e Note (Da compilare dopo il confronto)

*   **Risposta 1 (Flash Attention):** Il guadagno è quadratico e fondamentale per 64k token. Evita la materializzazione della matrice di attenzione completa in memoria. Flag impattante sul TTFT (Time To First Token).
*   **Risposta 2 (KV Cache):** La perdita di perplexity con `q4_0` è percepibile (~0.1-0.3). La raccomandazione è `q8_0` come compromesso per refactoring lunghi su codebase ampie, salvando comunque VRAM rispetto a `f16`.
*   **Risposta 3 (Batch Size):** 2048 è rischioso per il parallelo con VS Code e altri processi (causa swap). Il punto di equilibrio su M4 è tra 512 e 1024.
*   **Risposta 4 (Thinking):** Resa decrescente su un 9B. Tende a ripetere o circolare senza convergere. Meglio Instruct puro con System Prompt severo.
*   **Risposta 5 (GPU Offload):** `-ngl 99` va bene per sessioni isolate, ma per stabilità con editor e agenti attivi, tenere qualche layer su CPU (es. `-ngl 80`) aiuta macOS nella gestione della memoria unificata.
*   **Risposta 10 (Campionamento):** Temperatura bassa (0.1-0.2), Top-P (0.9), e soprattutto **Min-P (0.05)** per tagliare le allucinazioni sintattiche. Repeat Penalty leggero (1.05-1.1).

---

## 🛠️ Correzioni Finali (Post-Consulenza)

In base all'analisi del numero di layer per un modello 9B (~32 totali), abbiamo raffinato il parametro `-ngl`:
*   **`-ngl 26`**: Invece di `80` (che portava comunque tutto su GPU), usiamo `26` per lasciare effettivamente circa 6 layer alla CPU. Questa scelta garantisce una fluidità superiore del sistema macOS (VS Code, Browser, Terminale) mentre l'AI sta elaborando i 64k di contesto, con una perdita di velocità sulla generazione trascurabile su M4.

---

## 🏁 Decisione Finale e Parametri

In base alle risposte raccolte, ecco come configureremo il comando di avvio definitivo nel file `handle_project.sh`:

### Parametro da impostare:
```bash
# Esempio di riga di comando target
nohup llama-server -m "$model_path" \
  -c "${LLAMA_CONTEXT_LENGTH:-32768}" \
  -ngl 99 \
  --flash-attn \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  -b 2048 \
  --port 8080 \
  --metrics > "$LLAMA_LOG_FILE" 2>&1 &
```

### Logica della scelta:
*   **Motivazione:** _[Inserire qui il perché della scelta finale]_
