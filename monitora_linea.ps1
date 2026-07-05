
# ---- CONFIGURAZIONE UTENTE ----
$target = "8.8.8.8"            # Server di riferimento (Default: Google DNS)
$intervalloSec = 1             # Frequenza del ping (in secondi)
$durataOre = 4                  # Durata totale del monitoraggio (in ore)
$logFile = "$env:USERPROFILE\Desktop\log_linea.txt"

# Nome ESATTO della tua scheda di rete fisica (Esegui 'Get-NetAdapter' in PowerShell per verificarlo)
$nomeSchedaFisica = "Ethernet"  # Modifica in "Wi-Fi" o nel nome corretto della tua scheda

# Lista universale di processi da monitorare in caso di disconnessione.
# Puoi aggiungere o rimuovere qualsiasi programma (es. la tua VPN, il tuo Antivirus o Torrent)
$processiDaMonitorare = @(
    "MsMpEng", "NisSrv",        # Windows Defender / Sicurezza di Windows
    "wireguard", "openvpn",     # Servizi VPN generici
    "ProtonVPNService", "ProtonVPN", "NordVPN", "ExpressVPN", # Client VPN comuni
    "qbittorrent", "steam"      # Possibili app ad alto consumo di banda
)

# -------------------------------

$fineTest = (Get-Date).AddHours($durataOre)

"=== INIZIO MONITORAGGIO: $(Get-Date) ===" | Out-File -FilePath $logFile -Encoding UTF8

$adapter = Get-NetAdapter -Name $nomeSchedaFisica -ErrorAction SilentlyContinue
if ($null -eq $adapter) {
    "ATTENZIONE: Scheda '$nomeSchedaFisica' non trovata. Selezione automatica della prima scheda attiva." | Out-File -FilePath $logFile -Append -Encoding UTF8
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
}
"Scheda di rete monitorata: $($adapter.Name)" | Out-File -FilePath $logFile -Append -Encoding UTF8
"Processi sotto osservazione: $($processiDaMonitorare -join ', ')" | Out-File -FilePath $logFile -Append -Encoding UTF8
"" | Out-File -FilePath $logFile -Append -Encoding UTF8

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
        return @("(Impossibile leggere i contatori di sistema - Esegui come Amministratore)")
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
        $reply = $pingSender.Send($target, 2000)
        if ($reply.Status -eq 'Success') {
            $risultato = [PSCustomObject]@{ Latency = $reply.RoundtripTime }
        } else {
            $erroreDettaglio = "Stato: $($reply.Status)"
        }
    }
    catch {
        $erroreDettaglio = $_.Exception.Message
    }

    $ora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if ($null -eq $risultato) {
        $contatoreSalti++
        $riga = "[$ora] *** PERDITA PACCHETTO #$contatoreSalti *** Errore: $erroreDettaglio"
        Write-Host $riga -ForegroundColor Red
        $riga | Out-File -FilePath $logFile -Append -Encoding UTF8

        $stats = Get-NetAdapterStatistics -Name $adapter.Name | Format-List | Out-String
        "  --> Statistiche hardware scheda di rete:" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $stats | Out-File -FilePath $logFile -Append -Encoding UTF8

        "  --> Stato processi critici/selezionati:" | Out-File -FilePath $logFile -Append -Encoding UTF8
        foreach ($nome in $processiDaMonitorare) {
            $proc = Get-Process -Name $nome -ErrorAction SilentlyContinue
            if ($proc) {
                foreach ($p in $proc) {
                    $cpuScaricata = try { [math]::Round($p.CPU, 1) } catch { "N/A" }
                    "      - $($p.ProcessName) (PID $($p.Id)) - CPU: $($cpuScaricata)s - Memoria: $([math]::Round($p.WorkingSet64/1MB,1)) MB" | Out-File -FilePath $logFile -Append -Encoding UTF8
                }
            }
        }

        try {
            $eventiFirewall = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=5157; StartTime=(Get-Date).AddMinutes(-2)} -ErrorAction SilentlyContinue -MaxEvents 5
            if ($eventiFirewall) {
                "  --> Blocchi Windows Firewall (Ultimi 2 min):" | Out-File -FilePath $logFile -Append -Encoding UTF8
                foreach ($ev in $eventiFirewall) {
                    "      - $($ev.TimeCreated): $($ev.Message.Split("`n")[0])" | Out-File -FilePath $logFile -Append -Encoding UTF8
                }
            }
        } catch {}

        "  --> Programmi con connessioni di rete stabilite:" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $programmi = Get-ProgrammiConnessi
        if ($programmi.Count -gt 0) {
            foreach ($rigaProg in $programmi) {
                "      - $rigaProg" | Out-File -FilePath $logFile -Append -Encoding UTF8
            }
        } else {
            "      (Nessuna connessione attiva rilevata)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }

        "  --> Top processi per consumo di banda istantaneo:" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $topBanda = Get-TopProcessiPerBanda
        foreach ($rigaB in $topBanda) {
            "      - $rigaB" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }

        $ultimoStatoOk = $false
    }

    else {
        $tempo = $risultato.Latency
        if (-not $ultimoStatoOk) {
            "[$ora] >>> Linea RIPRISTINATA (Latenza attuale: $tempo ms)" | Out-File -FilePath $logFile -Append -Encoding UTF8
            Write-Host "[$ora] Linea ripristinata ($tempo ms)" -ForegroundColor Green
            $ultimoStatoOk = $true
        }
        elseif ($tempo -gt 200) {
            "[$ora] Latenza anomala alta: $tempo ms" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }
    }

    Start-Sleep -Seconds $intervalloSec

    if (((Get-Date) - $ultimoSnapshot).TotalSeconds -ge 30) {
        $oraSnap = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$oraSnap] --- Snapshot Periodico della Rete ---" | Out-File -FilePath $logFile -Append -Encoding UTF8
        
        $programmiSnap = Get-ProgrammiConnessi
        if ($programmiSnap.Count -gt 0) {
            foreach ($riga3 in $programmiSnap) {
                "      - $riga3" | Out-File -FilePath $logFile -Append -Encoding UTF8
            }
        }

        $topBandaSnap = Get-TopProcessiPerBanda
        if ($topBandaSnap.Count -gt 0) {
            "      Consumo banda stimato:" | Out-File -FilePath $logFile -Append -Encoding UTF8
            foreach ($rigaB2 in $topBandaSnap) {
                "      - $rigaB2" | Out-File -FilePath $logFile -Append -Encoding UTF8
            }
        }
        $ultimoSnapshot = Get-Date
    }
}

"=== FINE MONITORAGGIO: $(Get-Date) - Totale pacchetti persi: $contatoreSalti ===" | Out-File -FilePath $logFile -Append -Encoding UTF8
Write-Host "Monitoraggio terminato con successo. Log salvato in: $logFile" -ForegroundColor Green
