# 📡 Monitor Linea Internet

Script PowerShell per il monitoraggio continuo della connessione internet: registra ping, latenza, statistiche di rete, processi attivi e consumo di banda, con un log dettagliato ogni volta che si verifica una perdita di pacchetti — utile per diagnosticare disconnessioni intermittenti, cali di linea o problemi di rete difficili da riprodurre.

## ✨ Caratteristiche

- 📶 **Ping continuo** verso un server di riferimento (default: `8.8.8.8`, Google DNS)
- 🕵️ **Diagnosi automatica** ad ogni perdita di pacchetto: statistiche della scheda di rete, processi critici attivi, blocchi del Firewall di Windows, connessioni TCP stabilite e consumo di banda in tempo reale
- 🔌 **Rilevamento automatico della scheda di rete** (fisica o Wi-Fi), con fallback automatico se il nome specificato non viene trovato
- 🛡️ **Monitoraggio processi personalizzabile** (VPN, antivirus, torrent, giochi, ecc.) per capire se un programma specifico sta causando il problema
- 📊 **Snapshot periodici** ogni 30 secondi con connessioni attive e consumo banda, anche in assenza di problemi
- 📄 **Log testuale** completo e leggibile, salvato automaticamente sul Desktop

## 📋 Requisiti

- Windows con **PowerShell** (5.1 o superiore / PowerShell 7+)
- Alcune funzionalità (contatori di banda, log del Firewall) richiedono l'esecuzione **come Amministratore**

## ⚙️ Configurazione

Prima di avviare lo script, apri il file e personalizza i parametri in cima:

```powershell
$target = "8.8.8.8"            # Server di riferimento per il ping
$intervalloSec = 1             # Frequenza del ping (in secondi)
$durataOre = 4                  # Durata totale del monitoraggio (in ore)
$logFile = "$env:USERPROFILE\Desktop\log_linea.txt"

$nomeSchedaFisica = "Ethernet"  # Nome esatto della tua scheda di rete
```

> 💡 Per conoscere il nome esatto della tua scheda di rete, esegui in PowerShell:
> ```powershell
> Get-NetAdapter
> ```

Puoi inoltre modificare liberamente la lista dei processi da monitorare in caso di disconnessione (VPN, antivirus, client torrent, ecc.):

```powershell
$processiDaMonitorare = @(
    "MsMpEng", "NisSrv",
    "wireguard", "openvpn",
    "ProtonVPNService", "ProtonVPN", "NordVPN", "ExpressVPN",
    "qbittorrent", "steam"
)
```

## 🚀 Utilizzo

Apri PowerShell **come Amministratore** (consigliato, per avere accesso completo ai contatori di sistema e ai log del Firewall) e lancia lo script:

```powershell
.\monitor_linea_internet.ps1
```

> 💡 Se PowerShell blocca l'esecuzione dello script, potrebbe essere necessario abilitare temporaneamente l'esecuzione con:
> ```powershell
> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
> ```

Lo script rimarrà in esecuzione per la durata configurata (default 4 ore), mostrando a schermo in tempo reale eventuali perdite di pacchetti o ripristini della connessione.

## 📁 Output

Il log viene salvato in:

```
%USERPROFILE%\Desktop\log_linea.txt
```

Ogni evento registrato include data e ora. In caso di perdita di pacchetti, il log riporta automaticamente:

1. **Statistiche hardware** della scheda di rete (pacchetti inviati/ricevuti, errori, ecc.)
2. **Stato dei processi critici/selezionati** (CPU e memoria utilizzata)
3. **Blocchi recenti del Windows Firewall** (ultimi 2 minuti)
4. **Programmi con connessioni di rete attive** (nome processo, PID, indirizzo remoto)
5. **Top 5 processi per consumo di banda istantaneo** (KB/s)

Esempio di riga di log durante una disconnessione:

```
[2026-07-05 14:32:10] *** PERDITA PACCHETTO #3 *** Errore: Stato: TimedOut
  --> Statistiche hardware scheda di rete:
  --> Stato processi critici/selezionati:
      - NordVPN (PID 4521) - CPU: 12.4s - Memoria: 85.2 MB
  --> Programmi con connessioni di rete stabilite:
      - chrome (PID 8890) -> 142.250.180.14:443
  --> Top processi per consumo di banda istantaneo:
      - steam: 340.2 KB/s
```

E ogni volta che la linea torna a funzionare:

```
[2026-07-05 14:32:15] >>> Linea RIPRISTINATA (Latenza attuale: 24 ms)
```

## ⚙️ Come funziona

1. Identifica la scheda di rete indicata (o ne seleziona una attiva automaticamente)
2. Esegue un ping continuo verso il server target ad intervalli regolari
3. Se il ping fallisce → raccoglie una "istantanea diagnostica" completa del sistema (rete, processi, firewall, banda)
4. Se il ping torna a funzionare → registra il ripristino e la latenza attuale
5. Ogni 30 secondi produce comunque uno snapshot periodico, utile per avere uno storico anche senza problemi
6. Al termine della durata configurata, chiude il monitoraggio e salva il riepilogo finale con il totale dei pacchetti persi

## ⚠️ Note

- Alcune funzioni (in particolare `Get-Counter` per il consumo di banda e `Get-WinEvent` per i log del Firewall) **richiedono privilegi di Amministratore**: se lanciato senza, alcune sezioni del report risulteranno vuote o mostreranno un messaggio di avviso.
- Il log può crescere molto se usato per molte ore con snapshot frequenti: valuta di aumentare l'intervallo degli snapshot periodici se non ti servono informazioni così granulari.
- Lo script usa `8.8.8.8` come target di default: se sospetti un problema specifico con un servizio (es. streaming, gaming), puoi cambiarlo con l'indirizzo IP del servizio interessato.

## 📄 Licenza

Distribuito con licenza [MIT](LICENSE) — libero utilizzo, modifica e ridistribuzione.
