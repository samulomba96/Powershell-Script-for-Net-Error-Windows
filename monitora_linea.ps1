# ============================================================
# Script di monitoraggio linea internet
# Registra ping continui + statistiche scheda di rete + processi
# antivirus/firewall/VPN attivi al momento dei salti
# ============================================================

$logFile = "$env:USERPROFILE\Desktop\log_linea.txt"
$target = "8.8.8.8"          # Server da pingare (Google DNS)
$intervalloSec = 1           # ogni quanti secondi fare ping
$durataOre = 4                # per quante ore monitorare (modifica pure)

# ---- IMPORTANTE ----
# Metti qui il nome ESATTO della tua scheda Ethernet fisica
# (quello che ti restituisce Get-NetAdapter), NON quello di WireGuard/ProtonVPN
$nomeSchedaFisica = "Ethernet"   # <-- modifica se il nome è diverso

$fineTest = (Get-Date).AddHours($durataOre)

"=== INIZIO MONITORAGGIO: $(Get-Date) ===" | Out-File -FilePath $logFile -Encoding UTF8

# Prendi la scheda fisica specificata (non quella VPN)
$adapter = Get-NetAdapter -Name $nomeSchedaFisica -ErrorAction SilentlyContinue
if ($null -eq $adapter) {
    "ATTENZIONE: scheda '$nomeSchedaFisica' non trovata. Uso la prima scheda attiva disponibile." | Out-File -FilePath $logFile -Append -Encoding UTF8
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
}
"Scheda di rete monitorata: $($adapter.Name)" | Out-File -FilePath $logFile -Append -Encoding UTF8

# Elenco processi di sicurezza/VPN noti da tenere d'occhio
$processiSospetti = @(
    "MsMpEng",          # Windows Defender - motore antivirus
    "NisSrv",           # Windows Defender - protezione di rete
    "ProtonVPNService","ProtonVPN",
    "wireguard"
)
"Processi monitorati per correlazione: $($processiSospetti -join ', ')" | Out-File -FilePath $logFile -Append -Encoding UTF8
"" | Out-File -FilePath $logFile -Append -Encoding UTF8

# Funzione: elenca i programmi che in questo momento hanno connessioni di rete attive
# (utile per capire cosa stava scaricando quando è saltata la linea)
function Get-ProgrammiConnessi {
    $connessioni = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
        Select-Object -Property OwningProcess, RemoteAddress, RemotePort -Unique

    $risultato = @()
    $pidGiaVisti = @{}

    foreach ($c in $connessioni) {
        if (-not $pidGiaVisti.ContainsKey($c.OwningProcess)) {
            $pidGiaVisti[$c.OwningProcess] = $true
            $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
            if ($p) {
                $risultato += "$($p.ProcessName) (PID $($c.OwningProcess)) -> $($c.RemoteAddress):$($c.RemotePort)"
            }
        }
    }
    return $risultato
}

# Funzione: mostra i programmi che stanno trasferendo più dati in questo momento
# (byte al secondo - utile per capire chi sta effettivamente scaricando, non solo chi è connesso)
function Get-TopProcessiPerBanda {
    try {
        $campione = Get-Counter '\Process(*)\IO Data Bytes/sec' -ErrorAction Stop
        $risultato = $campione.CounterSamples |
            Where-Object { $_.CookedValue -gt 50000 -and $_.InstanceName -notin @('idle','_total','system') } |
            Sort-Object CookedValue -Descending |
            Select-Object -First 5

        $righe = @()
        foreach ($r in $risultato) {
            $velocitaKB = [math]::Round($r.CookedValue / 1KB, 1)
            $righe += "$($r.InstanceName): $velocitaKB KB/s"
        }
        return $righe
    }
    catch {
        return @("(impossibile leggere i contatori di sistema)")
    }
}

$contatoreSalti = 0
$ultimoStatoOk = $true
$ultimoSnapshot = Get-Date
$pingSender = New-Object System.Net.NetworkInformation.Ping

while ((Get-Date) -lt $fineTest) {

    $erroreDettaglio = $null
    $risultato = $null
    try {
        $reply = $pingSender.Send($target, 2000)  # timeout 2000 ms
        if ($reply.Status -eq 'Success') {
            $risultato = [PSCustomObject]@{ Latency = $reply.RoundtripTime }
        }
        else {
            $erroreDettaglio = "Stato: $($reply.Status)"
        }
    }
    catch {
        $erroreDettaglio = $_.Exception.Message
    }

    $ora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if ($null -eq $risultato) {
        # Pacchetto perso = possibile salto di linea
        $contatoreSalti++
        $riga = "[$ora] *** PERDITA PACCHETTO #$contatoreSalti *** Errore esatto: $erroreDettaglio"
        Write-Host $riga -ForegroundColor Red
        $riga | Out-File -FilePath $logFile -Append -Encoding UTF8

        # Quando c'è un problema, salva anche le statistiche della scheda di rete
        $stats = Get-NetAdapterStatistics -Name $adapter.Name | Format-List | Out-String
        "  --> Statistiche scheda al momento del problema:" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $stats | Out-File -FilePath $logFile -Append -Encoding UTF8

        # Controlla quali processi di sicurezza/VPN sono attivi in questo momento
        "  --> Processi di sicurezza/VPN attivi al momento del problema:" | Out-File -FilePath $logFile -Append -Encoding UTF8
        foreach ($nome in $processiSospetti) {
            $proc = Get-Process -Name $nome -ErrorAction SilentlyContinue
            if ($proc) {
                foreach ($p in $proc) {
                    "      - $($p.ProcessName) (PID $($p.Id)) - CPU: $([math]::Round($p.CPU,1))s - Memoria: $([math]::Round($p.WorkingSet64/1MB,1)) MB" | Out-File -FilePath $logFile -Append -Encoding UTF8
                }
            }
        }

        # Controlla se il servizio Windows Firewall ha registrato blocchi recenti (ultimi 2 minuti)
        try {
            $eventiFirewall = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=5157; StartTime=(Get-Date).AddMinutes(-2)} -ErrorAction SilentlyContinue -MaxEvents 5
            if ($eventiFirewall) {
                "  --> Blocchi Windows Firewall negli ultimi 2 minuti:" | Out-File -FilePath $logFile -Append -Encoding UTF8
                foreach ($ev in $eventiFirewall) {
                    "      - $($ev.TimeCreated): $($ev.Message.Split("`n")[0])" | Out-File -FilePath $logFile -Append -Encoding UTF8
                }
            }
        } catch {
            # Il log "Security" con auditing sulle connessioni potrebbe non essere abilitato: non è un errore critico
        }

        # Quale programma stava scaricando/comunicando al momento del salto
        "  --> Programmi con connessioni di rete attive al momento del problema:" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $programmi = Get-ProgrammiConnessi
        if ($programmi.Count -gt 0) {
            foreach ($riga2 in $programmi) {
                "      - $riga2" | Out-File -FilePath $logFile -Append -Encoding UTF8
            }
        } else {
            "      (nessuna connessione attiva rilevata in questo istante)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }

        # Chi sta effettivamente trasferendo più dati in questo momento (velocità reale)
        "  --> Programmi che trasferiscono più dati in questo istante:" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $topBanda = Get-TopProcessiPerBanda
        foreach ($rigaB in $topBanda) {
            "      - $rigaB" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }

        $ultimoStatoOk = $false
    }
    else {
        $tempo = $risultato.Latency
        if (-not $ultimoStatoOk) {
            # La linea è tornata su dopo un salto: lo segnaliamo
            "[$ora] Linea RIPRISTINATA (latenza: $tempo ms)" | Out-File -FilePath $logFile -Append -Encoding UTF8
            $ultimoStatoOk = $true
        }
        elseif ($tempo -gt 200) {
            # Latenza anomala anche se non è caduto il pacchetto
            $riga = "[$ora] Latenza alta: $tempo ms"
            $riga | Out-File -FilePath $logFile -Append -Encoding UTF8
        }
    }

    Start-Sleep -Seconds $intervalloSec

    # Ogni 30 secondi, registra comunque uno snapshot di chi sta scaricando
    # (utile per avere un quadro continuo, non solo nei momenti di problema)
    if (((Get-Date) - $ultimoSnapshot).TotalSeconds -ge 30) {
        $oraSnap = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$oraSnap] --- Snapshot periodico programmi connessi ---" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $programmiSnap = Get-ProgrammiConnessi
        if ($programmiSnap.Count -gt 0) {
            foreach ($riga3 in $programmiSnap) {
                "      - $riga3" | Out-File -FilePath $logFile -Append -Encoding UTF8
            }
        } else {
            "      (nessuna connessione attiva)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }

        "      Velocità di trasferimento (top 5 programmi attivi):" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $topBandaSnap = Get-TopProcessiPerBanda
        if ($topBandaSnap.Count -gt 0) {
            foreach ($rigaB2 in $topBandaSnap) {
                "      - $rigaB2" | Out-File -FilePath $logFile -Append -Encoding UTF8
            }
        } else {
            "      (nessun trasferimento dati significativo rilevato)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }

        $ultimoSnapshot = Get-Date
    }
}

"=== FINE MONITORAGGIO: $(Get-Date) - Totale perdite pacchetto: $contatoreSalti ===" | Out-File -FilePath $logFile -Append -Encoding UTF8
Write-Host "Monitoraggio terminato. Controlla il file: $logFile" -ForegroundColor Green