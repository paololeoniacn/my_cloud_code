# Configurazione Ottimizzata per Apple Silicon M4 (24GB RAM)

Questa suite è stata studiata e ottimizzata per sfruttare al meglio l'hardware di un Mac con processore **Apple Silicon M4** e **24GB di RAM unificata**.

La combinazione di modelli qui sotto indicata ti permette di ottenere il massimo equilibrio tra "ragionamento profondo" (necessario per un agente autonomo e per la chat), "latenza assente" (fondamentale per suggerirti in tempo reale del codice mentre digiti) e impatto ridotto sulle risorse della macchina.

## 🧠 Modelli Impostati (Ollama)

Questa è la configurazione corrente presente nel file `.env`:

### 1. Modello Primario / Agente (Claude Code & Chat)
* **Modello:** `qwen2.5:14b-instruct-q4_K_M`
* **Ruolo:** Agisce come la vera intelligenza "pensante". Gestisce Claude Code all'interno del terminale per leggere e alterare intere codebase autonomamente, e funge da interlocutore principale in VS Code per spiegarti bug e logiche architetturali.
* **Perché scelto per M4:** Con 14 Miliardi di parametri, è uno dei modelli intermedi più abili nel ragionamento logico. La versione (quantizzazione) `q4_K_M` pesa circa 8.5 GB e si carica interamente nella tua memoria GPU. L'accelerazione *Metal* del chip M4 ti genererà token a una velocità in grado di superare abbondantemente un modello in cloud standard.

### 2. Modello Autocompletamento (Copilot)
* **Modello:** `qwen2.5-coder:7b-instruct`
* **Ruolo:** È il tuo Copilot. Gira in perenne background mentre l'editor (Continue.dev) è aperto, spiando ciò che stai scrivendo. Nel momento in cui fai una pausa, formula in decimi di secondo la continuazione appropriata suggerendotela nell'editor in grigio.
* **Perché scelto per M4:** Essendo la versione specifica dei modelli scelti da 7 Miliardi di parametri, è microscopico e scattante. Un M4 ha prestazioni fulminee, permettendoti un'esperienza con lag (ritardi) quasi impercettibili tra il tocco di una tastiera e la comparsa del codice grigio.

### 3. Modello Embeddings (Memoria RAG)
* **Modello:** `nomic-embed-text:latest`
* **Ruolo:** Produce "vettori semantici" necessari per tramutare la tua codebase in pura matematica. Quando nella chat scrivi l'istruzione speciale `@Codebase`, questo modello perlustra i tuoi file e consente al Modello Primario di capire quale script devi correggere con precisione chirurgica.
* **Perché scelto per M4:** Nomic ha studiato questo modello per indicizzare immense porzioni testuali rapidamente. Veloce, leggerissimo e nativamente supportato da Continue e Ollama su Mac.

---

## ⚙️ Variabili di Ambiente Critiche (`.env`)

* **`OLLAMA_CONTEXT_LENGTH=65536`**
   Questa variabile comunica a Ollama quanto "nastro mentale" dedicare alla memoria dell'AI. Claude Code per operare ne esige parecchio (minimo 32k). Avendo tu un chip ad elevate prestazioni e 24GB di memoria RAM unificata, la configurazione predefinita è stata ampliata a **65k**. Potrai passare interi script, documentazioni copiose e file di enormi dimensioni al tuo agente senza mai rischiare il classico messaggio "Length constraint exceeded".

---

## 🔄 Consigli Pratici

1. I modelli caricati utilizzeranno una porzione importante della memoria RAM condivisa per generare una predizione, che con questa config si aggira tra gli 11 e i 14 GB a picco. Questo lascia circa 10 GB liberi per il sistema operativo e l'editor, uno specchio idoneo.
2. In caso di cali prestazionali significativi (magari avendo aperti dozzine di tab browser), potresti sostituire temporalmente il Modello Agente scegliendo tramite il comando interattivo (`./handle_project.sh setup-models`) un modello più snello da soli 7B di parametri sacrificando leggermente il ragionamento.
