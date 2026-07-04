Monitoraggio Linea Internet (PowerShell)
Questo script in PowerShell è progettato per monitorare in modo continuo la stabilità della tua connessione internet. A differenza di un semplice ping continuo, quando rileva una perdita di pacchetti (un "salto" di linea) o una latenza anomala, scatta uno "snapshot" istantaneo del sistema per aiutarti a capire perché la linea è caduta o rallentata.

📋 Funzionalità principali
Monitoraggio Real-Time: Esegue un ping ogni secondo verso un server di riferimento (Default: Google DNS 8.8.8.8).

Diagnostica dei Salti di Linea: In caso di timeout o errore, registra nel log:

Le statistiche dettagliate della scheda di rete (errori, pacchetti scartati).

Lo stato e il consumo di risorse dei principali software di sicurezza/VPN (Windows Defender, ProtonVPN, WireGuard).

Eventuali blocchi recenti del Windows Firewall (Log Security ID 5157).

L'elenco dei programmi con connessioni TCP attive in quel preciso istante.

I top 5 processi che stanno consumando più banda (in KB/s).

Snapshot Periodici: Ogni 30 secondi salva un riepilogo del traffico di rete per avere uno storico dell'utilizzo della banda.

Report Finale: Salva tutto in un file di testo leggibile sul tuo Desktop (log_linea.txt).

🛠️ Configurazione Preliminare
Prima di avviare lo script, apri il file .ps1 con un editor di testo (es. Blocco Note o VS Code) per personalizzare le variabili iniziali in base alle tue esigenze:

Nome della scheda di rete ($nomeSchedaFisica): Inserisci il nome esatto della tua scheda di rete fisica (es. "Ethernet" o "Wi-Fi"). Puoi scoprire il nome corretto aprendo PowerShell e digitando Get-NetAdapter. Non inserire i nomi delle schede virtuali create da VPN.

Durata del test ($durataOre): Imposta per quante ore vuoi che il monitoraggio rimanga attivo (Default: 4).

Destinazione dei Log ($logFile):
Di default il file viene salvato sul Desktop dell'utente corrente come log_linea.txt.

🚀 Come Eseguire lo Script
Per poter leggere i contatori di banda e i log di sicurezza del Firewall, lo script richiede privilegi di amministratore.

Clicca con il tasto destro sul menu Start di Windows e seleziona Terminale (Amministratore) oppure PowerShell (Amministratore).

Se non lo hai mai fatto prima, abilita l'esecuzione degli script sul tuo computer digitando:

PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process
(Rispondi Sì se richiesto).

Raggiungi la cartella in cui hai salvato lo script (es. se è nel Desktop):

PowerShell
cd $env:USERPROFILE\Desktop
Avvia lo script:

PowerShell
.\monitora_linea.ps1
📂 Struttura del Log Prodotto
Il file log_linea.txt conterrà voci strutturate come segue:

Latenza Alta: Registra i picchi in cui la risposta del ping supera i 200ms.

Ripristino Linea: Segnala l'esatto momento in cui la connessione torna a funzionare dopo un'interruzione.

Snapshot di Errore: In caso di disconnessione totale, troverai una sezione dedicata con i dettagli dei programmi attivi e la velocità in KB/s di chi stava occupando la banda.

⚠️ Nota sulla Sicurezza: Lo script analizza esclusivamente i nomi dei processi e gli indirizzi IP/Porte delle connessioni attive per finalità di diagnosi. Nessun dato sensibile o contenuto dei pacchetti viene letto o memorizzato.
