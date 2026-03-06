# 🧠 Strategia di Ottimizzazione AI Locale (M4 + Qwen 3.5 Unsloth)

Questo documento traccia il thread decisionale sull'architettura della suite AI locale, con l'obiettivo di trovare il perfetto equilibrio tra **velocità estrema**, **profondità di contesto (64k)** e **accuratezza logica**.

---

## 🛠️ Domande per l'Esperto (Validazione Tecnica)

Abbiamo configurato un server `llama.cpp` che processa il modello **Qwen 3.5 9B (Quantizzazione Q4_K_M)** su un **Mac M4 con 24GB di RAM Unificata**. Ecco i punti critici da validare:

### 1. Efficienza del Calcolo (Flash Attention)
> "Sull'architettura Apple M4, con un contesto di 64k token, l'attivazione della **Flash Attention** (`--flash-attn`) in `llama.cpp` garantisce un guadagno lineare o ci sono colli di bottiglia dovuti alla larghezza di banda della memoria unificata? È il flag ottimale per ridurre il *Time To First Token* (TTFT)?"

### 2. Gestione della Memoria (KV Cache Quantization)
> "Per massimizzare la velocità di generazione, ho impostato la **quantizzazione della Cache KV a q8_0**. Dato che il modello è un **UD (Unsloth Dynamic)**, dove i layer critici (iniziali/finali) sono preservati a bit più alti, quanto è importante mantenere la coerenza dei riferimenti a lunga distanza con una cache q8_0 rispetto a una q4_0?"

### 3. Orchestrazione degli Agenti (Batching)
> "Su M4, spingere il **Batch Size (`-b`) a 1024** garantisce un prefill veloce senza causare swap critico con VS Code attivo? Qual è il limite di pressione sulla memoria unificata prima di degradare le prestazioni?"

### 4. Ragionamento vs Velocità (Thinking Mode)
> "Per un modello 9B, il **Thinking Mode** (Reasoning) apporta un valore logico reale paragonabile ai modelli 'Large', o il costo in latenza e rumore nel contesto (monologhi interni) rende più efficiente un approccio 'Instruct' puro con un System Prompt molto severo?"

---

## 📥 Risposte e Note (Da compilare dopo il confronto)

*   **Risposta 1 (Flash Attention):** Il guadagno è quadratico e fondamentale per 64k token. Evita la materializzazione della matrice di attenzione completa in memoria. Flag impattante sul TTFT (Time To First Token).
*   **Risposta 2 (KV Cache):** Per refactoring su contesti da 64k, la cache `q8_0` è fondamentale per la coerenza dei riferimenti a distanza. Su un modello `UD`, mantenere alta la qualità della cache protegge il vantaggio logico dei layer non uniformi.
*   **Risposta 3 (Batch Size):** 1024 è il punto di equilibrio. Valori superiori (2048) caricano troppo la memoria unificata in parallelo con altri processi.
*   **Risposta 5 (GPU Offload):** Con 32 layer totali, `-ngl 26` significa **26 layer su GPU** e **6 su CPU**. Questo garantisce stabilità al sistema operativo senza sacrificare la velocità di generazione.
*   **Nota Tecnica UD:** La quantizzazione dinamica (Unsloth Dynamic) mantiene i layer di attenzione più profondi a precisione maggiore, migliorando la tenuta logica su task complessi.
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
