Monitoraggio Avanzato Linea Internet (PowerShell)
Questo script in PowerShell è uno strumento diagnostico universale progettato per monitorare la stabilità della tua connessione internet e correlare eventuali disconnessioni alle attività del tuo PC.

A differenza dei classici test di ping continui, quando questo strumento rileva una perdita di pacchetti (un "salto" di linea) o una latenza anomala, scatta uno "snapshot" istantaneo del sistema per aiutarti a capire se il problema è causato dal tuo operatore telefonico (ISP), da un sovraccarico di banda o da un software locale.

📋 Funzionalità principali
Monitoraggio Continuo: Esegue un ping al secondo verso un server stabile (Default: Google DNS 8.8.8.8).

Diagnostica dei Salti di Linea: In caso di timeout o errore, registra nel log:

Stato Hardware: Statistiche in tempo reale della scheda di rete (errori, pacchetti scartati).

Processi di Rete e Sicurezza: Stato e consumi (CPU/Memoria) di un elenco di software personalizzabile (Antivirus, VPN, client di download).

Attività di Rete: Elenco completo dei programmi con connessioni TCP attive in quel preciso istante.

Analisi dei Consumi: Top 5 processi che stanno occupando più banda in tempo reale (in KB/s).

Registri di Sicurezza: Eventuali blocchi recenti generati dal Windows Firewall (Event ID 5157).

Snapshot Periodici: Ogni 30 secondi salva un riepilogo del traffico per monitorare l'andamento della banda anche quando la linea funziona correttamente.

Report Automatico: Salva un file di testo chiaro e leggibile direttamente sul Desktop (log_linea.txt).

🛠️ Personalizzazione e Configurazione
Prima di avviare lo script, apri il file .ps1 con un editor di testo (es. Blocco Note o VS Code) per adattarlo al tuo computer modificando le variabili nella sezione ---- CONFIGURAZIONE UTENTE ----:

1. Scheda di Rete Fisica ($nomeSchedaFisica)
Inserisci il nome esatto della tua scheda di rete principale (es. "Ethernet" o "Wi-Fi").

Come trovarlo: Apri PowerShell e digita Get-NetAdapter. Usa il nome della tua scheda fisica principale (ignora le schede virtuali o quelle create dalle VPN).

2. Durata e Frequenza ($durataOre, $intervalloSec)
Imposta per quante ore desideri che il monitoraggio rimanga attivo (es. 4) e la frequenza del ping in secondi (es. 1).

3. Lista dei Processi Universale ($processiDaMonitorare)
Questa lista è completamente personalizzabile. Puoi inserire i nomi dei processi (senza .exe) di qualsiasi software installato sul tuo PC che desideri tenere sotto osservazione durante un blocco di rete:

PowerShell
$processiDaMonitorare = @(
    "MsMpEng", "NisSrv",        # Windows Defender / Sicurezza di Windows
    "wireguard", "openvpn",     # Servizi VPN generici
    "ProtonVPNService", "NordVPN", "ExpressVPN", # Esempi di client VPN
    "qbittorrent", "steam"      # Esempi di app ad alto consumo di banda
)
🚀 Come Eseguire lo Script
Per poter accedere ai contatori della banda di sistema e ai registri del Firewall di Windows, lo script richiede privilegi di Amministratore.

Clicca con il tasto destro sul menu Start e seleziona Terminale (Amministratore) oppure PowerShell (Amministratore).

Se non lo hai mai fatto sul tuo PC, abilita temporaneamente l'esecuzione degli script digitando:

PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process
(Premi S o Sì per confermare).

Spostati nella cartella in cui hai salvato lo script (es. se lo hai salvato sul Desktop):

PowerShell
cd $env:USERPROFILE\Desktop
Avvia il monitoraggio:

PowerShell
.\monitora_linea.ps1
📂 Come Interpretare i Risultati (log_linea.txt)
Il file generato sul tuo Desktop ti permetterà di isolare la causa del problema:

Problema della Linea (ISP/Router): Se vedi errori di ping ma i consumi di banda dei programmi sono minimi o azzerati, il problema è quasi certamente del tuo provider internet o del router.

Saturazione della Banda: Se il salto di linea coincide con picchi elevati in KB/s di un processo (es. steam, qbittorrent), la linea sta cadendo o rallentando perché il PC sta saturando la banda disponibile.

Conflitto Software: Se noti picchi anomali di CPU/Memoria o blocchi del Firewall in concomitanza con i processi dell'Antivirus o della VPN, il software di sicurezza potrebbe aver momentaneamente bloccato il traffico.
