# Let's write the complete README.md to a file just in case it's helpful, or simply format it nicely.
# The user wants a clean, well-formatted Markdown structure for GitHub with prominent headers.

readme_content = """# 📊 Monitoraggio Avanzato Linea Internet (PowerShell)

Lo script in PowerShell incluso in questo repository è uno strumento diagnostico universale progettato per **monitorare la stabilità della connessione internet** e correlare in tempo reale eventuali disconnessioni o rallentamenti alle attività software e hardware del proprio PC.

A differenza dei classici test di ping continui, quando questo strumento rileva una perdita di pacchetti (un "salto" di linea) o una latenza anomala, scatta uno **snapshot istantaneo del sistema**. Questo permette di capire se il problema sia causato dal provider internet (ISP), da un sovraccarico di banda locale o da un conflitto software.

---

## 📋 Funzionalità Principali

* **Monitoraggio Continuo ed Istantaneo:** Esegue un ping al secondo verso un server di riferimento ad alta affidabilità (Default: Google DNS `8.8.8.8`).
* **Diagnostica Avanzata dei Salti di Linea:** In caso di timeout o errore di rete, acquisisce immediatamente nel log:
  * 🛠️ **Stato Hardware:** Statistiche complete della scheda di rete (errori di trasmissione, pacchetti scartati, stato del link).
  * 🛡️ **Processi di Rete e Sicurezza:** Stato, PID e consumi di risorse (CPU e Memoria) di un elenco di software personalizzabile (Antivirus, VPN, client di download).
  * 🌐 **Attività di Rete Attiva:** Elenco completo di tutti i programmi che hanno connessioni TCP stabilite in quel preciso istante.
  * 📈 **Analisi della Banda:** Top 5 processi che stanno occupando più banda in tempo reale (espressa in KB/s).
  * 🧱 **Registri del Firewall:** Analisi degli ultimi 2 minuti dei log di sicurezza di Windows per intercettare eventuali blocchi del Windows Firewall (Event ID 5157).
* **Snapshot Periodici di Controllo:** Ogni 30 secondi salva un riepilogo del traffico per monitorare l'andamento della banda anche quando la linea funziona correttamente, offrendo uno storico comparativo.
* **Report Log Autocontenuto:** Salva un file di testo leggibile e strutturato direttamente sul Desktop dell'utente (`log_linea.txt`).

---

## 🛠️ Personalizzazione e Configurazione

Prima di avviare lo script, apri il file `monitora_linea.ps1` con un editor di testo (es. Blocco Note, VS Code) e modifica le variabili situate nella sezione **`---- CONFIGURAZIONE UTENTE ----`**:

### 1. Scheda di Rete Fisica (`$nomeSchedaFisica`)
Inserisci il nome esatto della tua interfaccia di rete principale (es. `"Ethernet"` o `"Wi-Fi"`).
> **Come trovarlo:** Apri PowerShell e digita `Get-NetAdapter`. Utilizza il valore sotto la colonna *Name* della tua scheda fisica principale. Ignora le schede virtuali o quelle create dalle VPN.

### 2. Parametri del Test (`$durataOre`, `$intervalloSec`)
* `$durataOre`: Imposta la durata totale del monitoraggio continuo (es. `4` per quattro ore, `12` per mezza giornata).
* `$intervalloSec`: Frequenza del ping espressa in secondi (default `1`).

### 3. Lista dei Processi da Monitorare (`$processiDaMonitorare`)
L'array è universale e completamente personalizzabile. Inserisci i nomi dei processi (senza l'estensione `.exe`) di qualunque software installato sul tuo computer che desideri tenere sotto osservazione durante i blocchi di rete:
