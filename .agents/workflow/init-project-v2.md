Esplora questo codebase a fondo per generare un CLAUDE.md preciso, utile e consapevole della stabilità del progetto.

Segui questa sequenza di analisi:

**Step 1 — Mappa la struttura e il contesto**
Usa Glob per trovare:
- file di configurazione (package.json, build.gradle, application.properties, *.config.*)
- entry point (main.*, index.*, app.*, Demetra*.java)
- file di test (*.test.*, *.spec.*, src/test/)
- CI/CD (.github/workflows/, .gitlab-ci.yml)
- **Contesto Storico**: Cartelle come `INCIDENTS/`, `POSTMORTEMS/`, `ADR/` o `docs/`.
- **Observability**: File `logback*`, `log4j*`, configurazioni Sentry o Grafana.

**Step 2 — Leggi i file chiave e Cross-Cutting concerns**
Per ogni file trovato, ricava:
- Stack tecnologico (linguaggi, framework, librerie principali)
- Comandi disponibili (scripts, Gradle tasks, Makefile targets)
- Architettura (struttura cartelle, pattern, separazione layer)
- **Componenti AOP/Filtri**: Aspetti (`@Aspect`) che intercettano chiamate API o Batch (es. logging centralizzato, validazione).
- Configurazioni non ovvie (porte custom, feature flag, setup ambiente locale).

**Step 3 — Analisi "Lezioni Apprese" e Pattern Pericolosi**
Cerca attivamente (usa Grep/analisi post-mortem):
- **Causa Radice Incidenze**: Leggi gli incidenti recenti in `INCIDENTS/` per identificare limiti di stabilità (es. OOM, saturazione log, timeout).
- Pattern pericolosi: hardcoded credentials, workaround ("hack", "workaround"), dipendenze fragili.
- **Limiti di Logging**: Verifica se ci sono livelli di log eccessivi in produzione (es. Hibernate SQL in PRD).

**Step 4 — Scrivi CLAUDE.md**
Crea il file CLAUDE.md nella root del progetto con questa struttura rigorosa:

```markdown
# CLAUDE.md — [nome progetto]

## Stack
[tecnologie principali, versioni rilevanti, setup infrastrutturale]

## Comandi
[comandi per: dev, test, build, deploy — copiabili direttamente]

## Architettura
[struttura cartelle, pattern chiave, come si connettono i moduli, AOP/logging context]

## File critici
[i 5-10 file più importanti, inclusi componenti di stabilità e file storici incidenti]

## Convenzioni
[naming, pattern di codice, stile, approccio ai test]

## What not to do
[IMPORTANT: priorità assoluta alle cause di crash in produzione e violazioni reali trovate nel codice/incidenti]
```

**Regole importanti:**
- La sezione "What not to do" deve documentare i pericoli reali emersi dai post-mortem.
- Ogni riga deve essere informazione operativa, non rumore generico.
- Ogni volta che viene risolto un incidente core, aggiorna CLAUDE.md per prevenire regressioni.
