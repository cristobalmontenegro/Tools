<#
.SYNOPSIS
    SScripCMC v11.0 - Suite de Gestion Integral (Consolidada)
    - Consolidacion de v10.0, v10.1 y Version Universal.
    - Sistema de configuracion JSON persistente (config.json).
    - Hardware detallado: Placa Base, RAM Max Soportada.
    - Monitor de Procesos con loop infinito o conteo de muestras.
    - Catalogo de Software Chocolatey expandido (55+ apps).
#>

# --- VALIDACION DE ADMINISTRADOR ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Acceso denegado. Ejecute como Administrador."
    Start-Sleep -Seconds 3
    exit
}

# --- CONFIGURACION INICIAL Y JSON ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$configFile = Join-Path $PSScriptRoot "config.json"

if (Test-Path $configFile) {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
} else {
    $config = [PSCustomObject]@{
        General = [PSCustomObject]@{ CompanyName = "MI_EMPRESA"; SuiteName = "SScripCMC" }
        Red     = [PSCustomObject]@{ Workgroup = "WORKGROUP" }
        Tareas  = [PSCustomObject]@{ VideoAlmuerzo = "C:\Ruta\video.mp4"; HoraAlmuerzo = "13:00"; HoraReinicio = "02:00"; HoraApagado = "21:00"; HoraChoco = "13:30" }
        Region  = [PSCustomObject]@{ Locale = "es-EC" }
    }
    $config | ConvertTo-Json -Depth 3 | Set-Content $configFile
}

$Host.UI.RawUI.WindowTitle = "$($config.General.SuiteName) v11.0 - $($config.General.CompanyName)"

# --- FUNCIONES AUXILIARES ---
function Save-Config {
    $config | ConvertTo-Json -Depth 3 | Set-Content $configFile
    Write-Host "[!] Configuracion actualizada y guardada en config.json" -ForegroundColor DarkGray
}

function Prompt-Config {
    param([string]$Mensaje, [string]$ValorActual)
    $inputVal = Read-Host "$Mensaje [$ValorActual] (Enter para mantener)"
    if ([string]::IsNullOrWhiteSpace($inputVal)) { return $ValorActual }
    return $inputVal
}

function Show-Header {
    param([string]$Title)
    Clear-Host
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "   $($config.General.SuiteName) v11.0 - $($config.General.CompanyName) (ADMIN)"
    Write-Host "======================================================================" -ForegroundColor Cyan
    if ($Title) {
        Write-Host "   MENU: $Title" -ForegroundColor Yellow
        Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
    }
}

function Pause-Script {
    Write-Host ""
    Read-Host "Presione Enter para continuar..."
}

# ==============================================================================
# BLOQUE 1: GESTION DE USUARIOS
# ==============================================================================

function Func-GestionarRutas {
    Show-Header "RUTAS DE PERFIL"
    Write-Host "--- Detectando discos... ---" -ForegroundColor Yellow
    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    
    Write-Host "Seleccione el disco para NUEVOS perfiles:"
    Write-Host " [C] Disco C: (Defecto)" -ForegroundColor Red
    foreach ($d in $drives | Where-Object { $_ -ne 'C' }) { Write-Host " [$d] Disco $d`:" -ForegroundColor Green }
    Write-Host " [X] Cancelar" -ForegroundColor Gray
    
    $targetDrive = Read-Host "Letra del disco"
    if ($targetDrive -eq "X" -or $targetDrive -eq "x") { return }
    if ($drives -notcontains $targetDrive) { Write-Warning "Disco no valido"; Pause-Script; return }

    $carpetas = @{}
    if ($targetDrive -eq 'C') {
        $carpetas = @{ 'Desktop'='%USERPROFILE%\Desktop'; 'Personal'='%USERPROFILE%\Documents'; '{374DE290-123F-4565-9164-39C4925E467B}'='%USERPROFILE%\Downloads'; 'Favorites'='%USERPROFILE%\Favorites'; 'My Music'='%USERPROFILE%\Music'; 'My Pictures'='%USERPROFILE%\Pictures'; 'My Video'='%USERPROFILE%\Videos' }
    } else {
        $carpetas = @{ 'Desktop'="$($targetDrive):\Usuarios\%USERNAME%\Desktop"; 'Personal'="$($targetDrive):\Usuarios\%USERNAME%\Documents"; '{374DE290-123F-4565-9164-39C4925E467B}'="$($targetDrive):\Usuarios\%USERNAME%\Downloads"; 'Favorites'="$($targetDrive):\Usuarios\%USERNAME%\Favorites"; 'My Music'="$($targetDrive):\Usuarios\%USERNAME%\Music"; 'My Pictures'="$($targetDrive):\Usuarios\%USERNAME%\Pictures"; 'My Video'="$($targetDrive):\Usuarios\%USERNAME%\Videos" }
    }

    $puntoMontajeReg = "HKLM\DefaultUser"; $rutaHiveDefault = "C:\Users\Default\NTUSER.DAT"
    try {
        Write-Host "Modificando plantilla Default User..."
        reg load $puntoMontajeReg $rutaHiveDefault 2>$null | Out-Null
        foreach ($key in $carpetas.Keys) {
            $ruta = "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
            Set-ItemProperty -Path $ruta -Name $key -Value $carpetas[$key] -Type ExpandString -Force
        }
        Write-Host "Rutas redirigidas al disco $targetDrive exitosamente." -ForegroundColor Green
    } catch { Write-Error "Error: $_" } 
    finally { [gc]::collect(); reg unload $puntoMontajeReg 2>$null | Out-Null }
    Pause-Script
}

function Func-CrearUsuario {
    $u = Read-Host "Nombre de usuario (X para volver)"
    if ($u -eq "X" -or $u -eq "x" -or -not $u) { return }
    
    $p = Read-Host "Contrasena" -AsSecureString
    $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($p))

    if (Get-LocalUser -Name $u -ErrorAction SilentlyContinue) {
        Set-LocalUser -Name $u -Password (ConvertTo-SecureString $pass -AsPlainText -Force)
        Write-Host "Usuario actualizado." -ForegroundColor Yellow
    } else {
        New-LocalUser -Name $u -Password (ConvertTo-SecureString $pass -AsPlainText -Force) -FullName $u -Description "Creado por $($config.General.SuiteName)"
        Write-Host "Usuario creado." -ForegroundColor Green
    }
    Add-LocalGroupMember -Group "Users" -Member $u -ErrorAction SilentlyContinue
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member $u -ErrorAction SilentlyContinue
    Pause-Script
}

function Menu-Usuarios {
    while ($true) {
        Show-Header "USUARIOS Y RUTAS"
        Write-Host "1. Gestionar Rutas (Disco D:)"
        Write-Host "2. Crear Usuario Local"
        Write-Host "X. Volver" -ForegroundColor Gray
        
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" { Func-GestionarRutas }
            "2" { Func-CrearUsuario }
        }
    }
}

# ==============================================================================
# BLOQUE 2: OPTIMIZACION Y MANTENIMIENTO
# ==============================================================================

function Func-LimpiezaTotal {
    Write-Host "INICIANDO LIMPIEZA PROFUNDA DE TEMPORALES..." -ForegroundColor Yellow
    
    Write-Host "Limpiando C:\Windows\Temp..."
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    $users = Get-ChildItem "C:\Users" | Where-Object { $_.PSIsContainer -and $_.Name -notin "Public","Default" }
    foreach ($u in $users) {
        $tempPath = "$($u.FullName)\AppData\Local\Temp\*"
        Write-Host "Limpiando Temp de: $($u.Name)..."
        Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Limpieza finalizada." -ForegroundColor Green
    Pause-Script
}

function Func-ReparacionSistema {
    Write-Host "--- HERRAMIENTAS DE REPARACION ---" -ForegroundColor Cyan
    
    Write-Host "1. Configurando CHKDSK para el proximo inicio..." -ForegroundColor Yellow
    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
    foreach ($d in $drives) {
        $letra = "$($d.DriveLetter):"
        Write-Host " -> Marcando unidad $letra..." -NoNewline
        try { $null = fsutil dirty set $letra; Write-Host " [OK]" -ForegroundColor Green } 
        catch { Write-Host " [ERROR]" -ForegroundColor Red }
    }
    Write-Host "   Nota: Se ejecutara automaticamente al reiniciar." -ForegroundColor Gray

    Write-Host "`n2. Ejecutando System File Checker (SFC)..." -ForegroundColor Yellow
    sfc /scannow
    
    Write-Host "`n3. Ejecutando DISM (Reparacion de Imagen)..." -ForegroundColor Yellow
    DISM /Online /Cleanup-Image /RestoreHealth
    Write-Host "   Limpiando Tienda de Componentes..."
    DISM /Online /Cleanup-Image /StartComponentCleanup
    
    Write-Host "`nPROCESO COMPLETADO. REINICIE EL EQUIPO." -ForegroundColor Red
    Pause-Script
}

function Func-DebloatersExternos {
    while ($true) {
        Show-Header "SCRIPTS EXTERNOS"
        Write-Host "1. Chris Titus Tech WinUtil"
        Write-Host "2. Debloater Raphi.re"
        Write-Host "3. Debloater Sycnex"
        Write-Host "4. Remover Microsoft Edge"
        Write-Host "X. Volver" -ForegroundColor Gray
        
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" { irm christitus.com/win | iex; Pause-Script }
            "2" { & ([scriptblock]::Create((irm "https://debloat.raphi.re/"))); Pause-Script }
            "3" { iwr -useb https://git.io/debloat|iex; Pause-Script }
            "4" { iex(irm https://cdn.jsdelivr.net/gh/he3als/EdgeRemover@main/get.ps1); Pause-Script }
        }
    }
}

function Func-OptimizarGraficos {
    Write-Host "Quitando transparencias..." -ForegroundColor Cyan
    reg load "HKU\TempDef" "C:\Users\Default\NTUSER.DAT" 2>$null | Out-Null
    $p = "Registry::HKEY_USERS\TempDef\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name "EnableTransparency" -Value 0 -Type DWord -Force
    [gc]::collect(); reg unload "HKU\TempDef" 2>$null | Out-Null

    Get-ChildItem "Registry::HKEY_USERS" | Where-Object { $_.Name -match "S-1-5-21" -and $_.Name -notmatch "_Classes" } | ForEach-Object {
        $p = "Registry::HKEY_USERS\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "EnableTransparency" -Value 0 -Type DWord -Force
    }
    
    $sysPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (!(Test-Path $sysPath)) { New-Item -Path $sysPath -Force | Out-Null }
    New-ItemProperty -Path $sysPath -Name "DisableAcrylicBackgroundOnLogon" -Value 1 -PropertyType DWord -Force | Out-Null

    Write-Host "Optimizacion Completada." -ForegroundColor Green
    Pause-Script
}

function Func-QuitarOOBE {
    Write-Host "`n--- ELIMINANDO OOBE Y EXPERIENCIA DE PRIMER USO ---" -ForegroundColor Yellow

    # --- HKLM: configuracion a nivel maquina ---
    Write-Host "Aplicando configuracion a nivel de maquina (HKLM)..." -ForegroundColor Cyan
    $oobe = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
    if (!(Test-Path $oobe)) { New-Item -Path $oobe -Force | Out-Null }
    Set-ItemProperty -Path $oobe -Name "SkipMachineOOBE" -Value 1 -Force
    Set-ItemProperty -Path $oobe -Name "SkipUserOOBE" -Value 1 -Force

    $sysPol = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    if (!(Test-Path $sysPol)) { New-Item -Path $sysPol -Force | Out-Null }
    Set-ItemProperty -Path $sysPol -Name "EnableFirstLogonAnimation" -Value 0 -Force

    $odPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
    if (!(Test-Path $odPolicy)) { New-Item -Path $odPolicy -Force | Out-Null }
    Set-ItemProperty -Path $odPolicy -Name "PreventFirstRunQuery" -Value 1 -Force
    Set-ItemProperty -Path $odPolicy -Name "DisablePersonalSync" -Value 1 -Force

    $cloud = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (!(Test-Path $cloud)) { New-Item -Path $cloud -Force | Out-Null }
    Set-ItemProperty -Path $cloud -Name "DisableWindowsSpotlightFeatures" -Value 1 -Force
    Set-ItemProperty -Path $cloud -Name "DisableConsumerFeatures" -Value 1 -Force
    Set-ItemProperty -Path $cloud -Name "DisableCloudOptimizedContent" -Value 1 -Force

    # --- HKCU: configuracion del usuario actual ---
    Write-Host "Aplicando configuracion al usuario actual (HKCU)..." -ForegroundColor Cyan
    $cloudUser = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (!(Test-Path $cloudUser)) { New-Item -Path $cloudUser -Force | Out-Null }
    Set-ItemProperty -Path $cloudUser -Name "DisableWindowsSpotlightFeatures" -Value 1 -Force
    Set-ItemProperty -Path $cloudUser -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1 -Force

    $cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    if (!(Test-Path $cdm)) { New-Item -Path $cdm -Force | Out-Null }
    $sugerencias = @("310093Enabled","338387Enabled","338388Enabled","338389Enabled","353694Enabled","353696Enabled")
    foreach ($id in $sugerencias) { Set-ItemProperty -Path $cdm -Name "SubscribedContent-$id" -Value 0 -Force }
    Set-ItemProperty -Path $cdm -Name "RotatingLockScreenEnabled" -Value 0 -Force
    Set-ItemProperty -Path $cdm -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Force
    Set-ItemProperty -Path $cdm -Name "SoftLandingEnabled" -Value 0 -Force
    Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force

    # --- Default User: configuracion para nuevos usuarios ---
    Write-Host "Aplicando configuracion a Default User (nuevos perfiles)..." -ForegroundColor Cyan
    reg load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT" 2>$null | Out-Null
    try {
        $scoobePath = "Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
        $contentPath = "Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (Test-Path "Registry::HKU\DefaultUser") {
            if (!(Test-Path $scoobePath)) { New-Item -Path $scoobePath -Force | Out-Null }
            Set-ItemProperty -Path $scoobePath -Name "ScoobeSystemSettingEnabled" -Value 0 -Force
            if (!(Test-Path $contentPath)) { New-Item -Path $contentPath -Force | Out-Null }
            foreach ($id in $sugerencias) { Set-ItemProperty -Path $contentPath -Name "SubscribedContent-$id" -Value 0 -Force }
            Write-Host "Default User configurado." -ForegroundColor Green
        }
    } catch { Write-Host ("No se pudo acceder a Default User: {0}" -f $_) -ForegroundColor Yellow }
    finally { [gc]::Collect(); reg unload "HKU\DefaultUser" 2>$null | Out-Null }

    Write-Host "`nOOBE y experiencia de primer usuario eliminados." -ForegroundColor Green
    Write-Host "  - Pantallas OOBE/SCOOBE: saltadas" -ForegroundColor Cyan
    Write-Host "  - OneDrive prompt: deshabilitado" -ForegroundColor Cyan
    Write-Host "  - Spotlight/publicidad: deshabilitada" -ForegroundColor Cyan
    Write-Host "  - Sugerencias de apps: deshabilitadas" -ForegroundColor Cyan
    Write-Host "  - Animacion primer ingreso: deshabilitada" -ForegroundColor Cyan
    Write-Host "  - Aplica a usuario actual + nuevos perfiles" -ForegroundColor Cyan
    Write-Host "REINICIE para nuevos perfiles." -ForegroundColor Yellow
    Pause-Script
}

function Menu-Optimizacion {
    while ($true) {
        Show-Header "OPTIMIZACION Y MANTENIMIENTO"
        Write-Host "1. Limpieza de Temporales (Todos los Usuarios)"
        Write-Host "2. Reparacion de Sistema (CHKDSK -> SFC -> DISM)"
        Write-Host "3. Scripts Externos (Titus, Raphi, Edge)"
        Write-Host "4. Crear Punto de Restauracion"
        Write-Host "5. Optimizar Graficos"
        Write-Host "6. Eliminar Widgets"
        Write-Host "7. Bloquear OneDrive"
        Write-Host "8. Quitar OOBE y Experiencia Primer Usuario"
        Write-Host "X. Volver" -ForegroundColor Gray
        
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" { Func-LimpiezaTotal }
            "2" { Func-ReparacionSistema }
            "3" { Func-DebloatersExternos }
            "4" { Checkpoint-Computer -Description "$($config.General.SuiteName)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue; Write-Host "OK"; Pause-Script }
            "5" { Func-OptimizarGraficos }
            "6" { winget uninstall "Windows web experience pack" --accept-source-agreements; Pause-Script }
            "7" { 
                $regPath = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\DisableOneDrive"
                if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
                Set-ItemProperty -Path $regPath -Name "StubPath" -Value 'REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f' -Force
                Write-Host "OneDrive Bloqueado"; Pause-Script 
            }
            "8" { Func-QuitarOOBE }
        }
    }
}

# ==============================================================================
# BLOQUE 3: REGION Y RELOJ
# ==============================================================================

function Set-ECFormatRegional {
    param([string]$Locale = "es-EC")
    Write-Host "Aplicando formatos Ecuador: decimal=punto, miles=coma, semana=lunes..." -ForegroundColor Yellow

    $ApplyToHive = {
        param($hiveRoot)
        $path = "$hiveRoot\Control Panel\International"
        if (!(Test-Path $path)) { return }
        Set-ItemProperty -Path $path -Name "sDecimal" -Value "." -Force
        Set-ItemProperty -Path $path -Name "sThousand" -Value "," -Force
        Set-ItemProperty -Path $path -Name "sMonetaryThousandSep" -Value "," -Force
        Set-ItemProperty -Path $path -Name "sMonetaryDecimal" -Value "." -Force
        Set-ItemProperty -Path $path -Name "sList" -Value "," -Force
        Set-ItemProperty -Path $path -Name "iFirstDayOfWeek" -Value "1" -Force
        Set-ItemProperty -Path $path -Name "sShortDate" -Value "dd/MM/yyyy" -Force
        Set-ItemProperty -Path $path -Name "sLongDate" -Value "dd' de 'MMMM' de 'yyyy" -Force
        Set-ItemProperty -Path $path -Name "sTimeFormat" -Value "HH:mm:ss" -Force
        Set-ItemProperty -Path $path -Name "sShortTime" -Value "HH:mm" -Force
        Set-ItemProperty -Path $path -Name "sYearMonth" -Value "MMMM' de 'yyyy" -Force
        Set-ItemProperty -Path $path -Name "LocaleName" -Value $Locale -Force
        Set-ItemProperty -Path $path -Name "Locale" -Value "2C0A" -Force
        Set-ItemProperty -Path $path -Name "sCountry" -Value "Ecuador" -Force
        $geoPath = "$hiveRoot\Control Panel\International\Geo"
        if (!(Test-Path $geoPath)) { New-Item -Path $geoPath -Force | Out-Null }
        Set-ItemProperty -Path $geoPath -Name "Name" -Value "EC" -Force
        Set-ItemProperty -Path $geoPath -Name "Nation" -Value "66" -Force
    }

    reg load "HKLM\TempDef" "C:\Users\Default\NTUSER.DAT" 2>$null | Out-Null
    if (Test-Path "Registry::HKLM\TempDef") {
        & $ApplyToHive "Registry::HKLM\TempDef"
        [gc]::collect()
        reg unload "HKLM\TempDef" 2>$null | Out-Null
    }

    $profiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { -not $_.Special }
    foreach ($p in $profiles) {
        $sid = $p.SID; $name = $p.LocalPath | Split-Path -Leaf
        if (Test-Path "Registry::HKEY_USERS\$sid") {
            & $ApplyToHive "Registry::HKEY_USERS\$sid"
            Write-Host " -> Online: $name" -ForegroundColor Green
        } else {
            $hiveFile = Join-Path $p.LocalPath "NTUSER.DAT"
            if (Test-Path $hiveFile) {
                reg load "HKLM\Temp_$name" "$hiveFile" 2>$null | Out-Null
                if (Test-Path "Registry::HKLM\Temp_$name") {
                    & $ApplyToHive "Registry::HKLM\Temp_$name"
                    [gc]::collect()
                    reg unload "HKLM\Temp_$name" 2>$null | Out-Null
                    Write-Host " -> Offline: $name" -ForegroundColor Green
                }
            }
        }
    }
    Write-Host "Formatos ecuatorianos aplicados." -ForegroundColor Green
}

function Func-RegionEcuador {
    Write-Host "Configurando separadores ecuatorianos..." -ForegroundColor Yellow
    Set-WinSystemLocale -SystemLocale es-EC
    Set-WinUILanguageOverride -Language es-EC
    $langList = Get-WinUserLanguageList
    if (-not ($langList | Where-Object { $_.LanguageTag -eq "es-EC" })) { $langList.Add("es-EC") }
    Set-WinUserLanguageList $langList -Force
    Set-ECFormatRegional -Locale "es-EC"
    Write-Host "Separadores aplicados: decimal=punto, miles=coma, fecha dd/MM/yyyy." -ForegroundColor Green
    Pause-Script
}

function Func-RelojNTP {
    Write-Host "Iniciando servicio de hora (w32time)..."
    Start-Service w32time -ErrorAction SilentlyContinue
    
    Write-Host "Sincronizando reloj (Windows NTP)..."
    $proc = Start-Process "w32tm" -ArgumentList "/resync" -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -eq 0) { Write-Host "Sincronizacion Exitosa." -ForegroundColor Green }
    else { Write-Warning "Fallo la sincronizacion. Verifique internet." }
    Pause-Script
}

function Func-RelojHTTP {
    Write-Host "Sincronizando reloj (Via Google HTTP Headers)..."
    try {
        $req = Invoke-WebRequest "http://www.google.com" -Method Head -UseBasicParsing -TimeoutSec 5
        $dateStr = $req.Headers["Date"]
        if ($dateStr) {
            $netTime = [DateTime]::Parse($dateStr).ToLocalTime()
            Set-Date -Date $netTime
            Write-Host "Hora actualizada: $netTime" -ForegroundColor Green
        } else { throw "No se recibio fecha." }
    } catch { Write-Error "Fallo la conexion. Verifique internet o proxy." }
    Pause-Script
}

function Func-TareaRelojHTTP {
    $cmd = '$r=Invoke-WebRequest "http://www.google.com" -Method Head -UseBasicParsing; Set-Date ([DateTime]::Parse($r.Headers["Date"]).ToLocalTime())'
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
    $enc = [Convert]::ToBase64String($bytes)
    
    $act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-EncodedCommand $enc -WindowStyle Hidden"
    $trig = New-ScheduledTaskTrigger -AtLogon
    $rep = New-ScheduledTaskTrigger -Daily -At "12:00" 
    
    Register-ScheduledTask -TaskName "SyncRelojHTTP_$($config.General.SuiteName)" -Action $act -Trigger @($trig, $rep) -User "SYSTEM" -RunLevel Highest -Force | Out-Null
    Write-Host "Tarea 'SyncRelojHTTP_$($config.General.SuiteName)' creada (Inicio y 12:00)." -ForegroundColor Green
    Pause-Script
}

function Menu-RegionReloj {
    while ($true) {
        Show-Header "REGION Y RELOJ"
        Write-Host "1. Instalar Espanol (es-EC) + Configurar Separadores [COMPLETO]" -ForegroundColor Green
        Write-Host "2. Solo Configurar Separadores (decimal=punto, miles=coma) [SIN DESCARGA]"
        Write-Host "3. Sincronizar Reloj (Windows NTP - Estandar)"
        Write-Host "4. Sincronizar Reloj (Web HTTP - Alternativo)"
        Write-Host "5. Crear Tarea Auto-Sync (Web HTTP - Diario)"
        Write-Host "X. Volver" -ForegroundColor Gray

        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" {
                Write-Host "`n--- INSTALACION IDIOMA es-EC ---" -ForegroundColor Yellow
                $caps = @("Language.Basic","Language.TextToSpeech","Language.OCR","Language.Handwriting","Language.Speech")
                $langList = Get-WinUserLanguageList
                $yaTiene = ($langList | Where-Object { $_.LanguageTag -eq "es-EC" }) -ne $null
                if ($yaTiene) {
                    Write-Host "es-EC ya esta en la lista de idiomas." -ForegroundColor Green
                } else {
                    $hasInstallLang = Get-Command Install-Language -ErrorAction SilentlyContinue
                    if ($hasInstallLang) {
                        Write-Host "Instalando paquete es-EC via Install-Language..." -ForegroundColor Cyan
                        try { Install-Language -Language es-EC -CopyToSettings -ErrorAction Stop; Write-Host "OK." -ForegroundColor Green }
                        catch { Write-Host "Fallo. Intentando por capabilities..." -ForegroundColor Yellow }
                    }
                    foreach ($cap in $caps) {
                        $capName = "$cap~~~es-ec~0.0.1.0"
                        Write-Host "  $cap..." -ForegroundColor Cyan -NoNewline
                        try { Add-WindowsCapability -Online -Name $capName -ErrorAction Stop | Out-Null; Write-Host " [OK]" -ForegroundColor Green }
                        catch { Write-Host " [ya instalado]" -ForegroundColor DarkGray }
                    }
                }
                Write-Host "`nConfigurando es-EC como locale del sistema..." -ForegroundColor Yellow
                Set-WinSystemLocale -SystemLocale es-EC
                $langList = Get-WinUserLanguageList
                if (-not ($langList | Where-Object { $_.LanguageTag -eq "es-EC" })) { $langList.Add("es-EC") }
                Set-WinUserLanguageList $langList -Force
                try { Set-SystemPreferredUILanguage -Language es-EC } catch {}
                Set-WinUILanguageOverride -Language es-EC
                Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true -ErrorAction SilentlyContinue
                Write-Host "Aplicando separadores: decimal=punto, miles=coma..." -ForegroundColor Yellow
                Set-ECFormatRegional -Locale "es-EC"
                Write-Host "`nLISTO. Idioma es-EC + formato Ecuador aplicados." -ForegroundColor Green
                Write-Host "  Decimal: . | Miles: , | Fecha: dd/MM/yyyy | Semana: lunes" -ForegroundColor Cyan
                Write-Host "REINICIE EL EQUIPO para aplicar completamente." -ForegroundColor Red
                Pause-Script
            }
            "2" { Func-RegionEcuador }
            "3" { Func-RelojNTP }
            "4" { Func-RelojHTTP }
            "5" { Func-TareaRelojHTTP }
        }
    }
}

# ==============================================================================
# BLOQUE 4: TAREAS PROGRAMADAS
# ==============================================================================

function Func-TareaChoco {
    $hora = Prompt-Config "Hora de Actualizacion Choco (HH:mm)" $config.Tareas.HoraChoco
    if ($hora -ne $config.Tareas.HoraChoco) { $config.Tareas.HoraChoco = $hora; Save-Config }

    $chocoExe = "$env:ProgramData\chocolatey\bin\choco.exe"
    $trig = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At $hora
    $act = New-ScheduledTaskAction -Execute $chocoExe -Argument 'upgrade all -y'
    $set = New-ScheduledTaskSettingsSet -StartWhenAvailable
    Register-ScheduledTask -TaskName "Mantenimiento Chocolatey" -Action $act -Trigger $trig -User "SYSTEM" -RunLevel Highest -Settings $set -Force | Out-Null
    Write-Host "Tarea 'Mantenimiento Chocolatey' creada (L-V $hora)." -ForegroundColor Green
    Pause-Script
}

function Menu-Tareas {
    while ($true) {
        Show-Header "TAREAS PROGRAMADAS"
        Write-Host "1. Tarea Almuerzo (VLC $($config.Tareas.HoraAlmuerzo))"
        Write-Host "2. Eliminar Tarea Almuerzo"
        Write-Host "3. Tarea Reinicio Nocturno ($($config.Tareas.HoraReinicio))"
        Write-Host "4. Tarea Apagado Forzado ($($config.Tareas.HoraApagado))"
        Write-Host "5. Tarea Chocolatey Update (L-V $($config.Tareas.HoraChoco))"
        Write-Host "X. Volver" -ForegroundColor Gray
        
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" {
                $video = Prompt-Config "Ruta del Video de Almuerzo" $config.Tareas.VideoAlmuerzo
                $hora = Prompt-Config "Hora de Almuerzo (HH:mm)" $config.Tareas.HoraAlmuerzo
                if ($video -ne $config.Tareas.VideoAlmuerzo -or $hora -ne $config.Tareas.HoraAlmuerzo) {
                    $config.Tareas.VideoAlmuerzo = $video
                    $config.Tareas.HoraAlmuerzo = $hora
                    Save-Config
                }

                $vlc = "$env:ProgramFiles\VideoLAN\VLC\vlc.exe"
                $users = Get-LocalUser | Where-Object { $_.Enabled -and $_.Name -ne "Administrador" }
                foreach ($u in $users) {
                    $arg = "--fullscreen --video-on-top --no-video-title-show ""$video"" vlc://quit"
                    $act = New-ScheduledTaskAction -Execute $vlc -Argument $arg
                    $trig = New-ScheduledTaskTrigger -Daily -At $hora
                    Register-ScheduledTask -TaskName "Almuerzo - Bienestar $($u.Name)" -Action $act -Trigger $trig -User $u.Name -Force | Out-Null
                }
                Write-Host "Tarea creada a las $hora con el video $video." -ForegroundColor Green; Pause-Script
            }
            "2" {
                Get-ScheduledTask | Where-Object {$_.TaskName -like "Almuerzo*"} | Unregister-ScheduledTask -Confirm:$false
                Write-Host "Eliminado." -ForegroundColor Yellow; Pause-Script
            }
            "3" {
                $hora = Prompt-Config "Hora de Reinicio (HH:mm)" $config.Tareas.HoraReinicio
                if ($hora -ne $config.Tareas.HoraReinicio) { $config.Tareas.HoraReinicio = $hora; Save-Config }

                $act = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 0"
                $trig = New-ScheduledTaskTrigger -Daily -At $hora
                Register-ScheduledTask -TaskName "ReinicioNocturnoForzado" -Action $act -Trigger $trig -User "SYSTEM" -RunLevel Highest -Force | Out-Null
                Write-Host "Tarea OK." -ForegroundColor Green; Pause-Script
            }
            "4" {
                $hora = Prompt-Config "Hora de Apagado (HH:mm)" $config.Tareas.HoraApagado
                if ($hora -ne $config.Tareas.HoraApagado) { $config.Tareas.HoraApagado = $hora; Save-Config }

                $act = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/s /f /t 0"
                $trig = New-ScheduledTaskTrigger -Daily -At $hora
                Register-ScheduledTask -TaskName "ApagadoNocturno" -Action $act -Trigger $trig -User "SYSTEM" -RunLevel Highest -Force | Out-Null
                Write-Host "Tarea OK." -ForegroundColor Green; Pause-Script
            }
            "5" { Func-TareaChoco }
        }
    }
}

# ==============================================================================
# BLOQUE 5: SOFTWARE (GUI)
# ==============================================================================

function Get-InstalledChoco {
    $installed = @()
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        try {
            $raw = & choco list --local-only 2>$null
            foreach ($line in $raw) {
                if ($line -match '^\s*(\S+)\s+v?\d') {
                    $pkg = $Matches[1].ToLower()
                    if ($pkg -ne 'chocolatey') { $installed += $pkg }
                }
            }
        } catch {}
    }
    return $installed
}


function ConvertTo-Color {
    param([string]$C)
    if ($C -match ',') {
        $p = $C -split ','
        [System.Drawing.Color]::FromArgb([int]$p[0], [int]$p[1], [int]$p[2])
    } else {
        [System.Drawing.Color]::$C
    }
}

function New-GUIButton {
    param([string]$Text, [string]$BgColor, [int]$Width = 120, [int]$Height = 34, [string]$Tag = "")
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Size = New-Object System.Drawing.Size($Width, $Height)
    $btn.FlatStyle = "Flat"
    $btn.BackColor = ConvertTo-Color $BgColor
    $btn.ForeColor = "White"
    $btn.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Bold)
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $btn.Tag = $Tag
    return $btn
}

function New-GUIForm {
    param([string]$Title, [string]$InfoText)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$($config.General.SuiteName) - $Title"; $form.Size = New-Object System.Drawing.Size(920, 700); $form.StartPosition = "CenterScreen"; $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $pnlTop = New-Object System.Windows.Forms.Panel; $pnlTop.Dock = "Top"; $pnlTop.Height = 42; $pnlTop.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $InfoText; $lbl.AutoSize = $true; $lbl.Location = New-Object System.Drawing.Point(10, 12); $lbl.ForeColor = "White"; $pnlTop.Controls.Add($lbl)
    $pnlBot = New-Object System.Windows.Forms.Panel; $pnlBot.Dock = "Bottom"; $pnlBot.Height = 50; $pnlBot.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $tbl = New-Object System.Windows.Forms.TableLayoutPanel; $tbl.Dock = "Fill"; $tbl.AutoScroll = $true; $tbl.ColumnCount = 4; $tbl.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $null = $tbl.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 32)))
    $null = $tbl.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
    $null = $tbl.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 32)))
    $null = $tbl.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
    $form.Controls.Add($tbl); $form.Controls.Add($pnlTop); $form.Controls.Add($pnlBot)
    return @{ Form=$form; TopPanel=$pnlTop; BottomPanel=$pnlBot; Table=$tbl; CBs=@(); Row=0; Col=0 }
}

function Add-GUICategory {
    param($Ctx, [string]$Name, [string]$Color = "0,150,213")
    $t = $Ctx.Table
    if ($Ctx.Col -eq 2) {
        $r = $Ctx.Row
        $emptyLbl = New-Object System.Windows.Forms.Label; $emptyLbl.BackColor = [System.Drawing.Color]::FromArgb(35,35,35); $emptyLbl.Dock = "Fill"; $t.Controls.Add($emptyLbl, 2, $r)
        $emptySpacer = New-Object System.Windows.Forms.Panel; $emptySpacer.BackColor = [System.Drawing.Color]::FromArgb(35,35,35); $emptySpacer.Dock = "Fill"; $t.Controls.Add($emptySpacer, 3, $r)
        $Ctx.Row = $r + 1; $Ctx.Col = 0
    }
    $r = $Ctx.Row; $t.RowCount++
    $null = $t.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "  $($Name.ToUpper())"; $lbl.Dock = "Fill"; $lbl.TextAlign = "MiddleLeft"; $lbl.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold); $lbl.ForeColor = ConvertTo-Color $Color; $lbl.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $lbl.Margin = New-Object System.Windows.Forms.Padding(0, 6, 0, 0)
    $t.Controls.Add($lbl, 0, $r); $t.SetColumnSpan($lbl, 4)
    $Ctx.Row = $r + 1
}

function Add-GUICheckboxRow {
    param($Ctx, [string]$Label, $Tag, [string]$LabelColor = "White", [bool]$Checked = $false, [string]$Suffix = "")
    $t = $Ctx.Table; $fc = ConvertTo-Color $LabelColor
    if ($Ctx.Col -eq 0) {
        $r = $Ctx.Row; $t.RowCount++
        $null = $t.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
    } else { $r = $Ctx.Row }
    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "  $Label$Suffix"; $lbl.Dock = "Fill"; $lbl.TextAlign = "MiddleLeft"; $lbl.ForeColor = $fc; $lbl.Font = New-Object System.Drawing.Font("Arial", 9); $lbl.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
    $cb = New-Object System.Windows.Forms.CheckBox; $cb.Dock = "Fill"; $cb.Tag = $Tag; $cb.ForeColor = "White"; $cb.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $cb.Margin = New-Object System.Windows.Forms.Padding(10, 0, 0, 0); $cb.Checked = $Checked
    $Ctx.CBs += $cb
    if ($Ctx.Col -eq 0) {
        $t.Controls.Add($lbl, 0, $r); $t.Controls.Add($cb, 1, $r); $Ctx.Col = 2
    } else {
        $t.Controls.Add($lbl, 2, $r); $t.Controls.Add($cb, 3, $r); $Ctx.Col = 0; $Ctx.Row = $r + 1
    }
}

function Complete-GUITable {
    param($Ctx)
    if ($Ctx.Col -eq 2) {
        $r = $Ctx.Row
        $emptyLbl = New-Object System.Windows.Forms.Label; $emptyLbl.BackColor = [System.Drawing.Color]::FromArgb(35,35,35); $emptyLbl.Dock = "Fill"; $Ctx.Table.Controls.Add($emptyLbl, 2, $r)
        $emptySpacer = New-Object System.Windows.Forms.Panel; $emptySpacer.BackColor = [System.Drawing.Color]::FromArgb(35,35,35); $emptySpacer.Dock = "Fill"; $Ctx.Table.Controls.Add($emptySpacer, 3, $r)
        $Ctx.Row = $r + 1
    }
    $r = $Ctx.Row; $Ctx.Table.RowCount++
    $null = $Ctx.Table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
    $Ctx.Row = $r + 1
}

function Show-ChocoGUI {
    $apps = [ordered]@{
        "Navegadores" = [ordered]@{ "Google Chrome"="googlechrome"; "Firefox"="firefox"; "Brave"="brave"; "Microsoft Edge"="microsoft-edge" }
        "Ofimatica y PDF" = [ordered]@{ "LibreOffice"="libreoffice-fresh"; "LibreOffice Help"="libreoffice-help"; "OnlyOffice"="onlyoffice"; "Foxit Reader"="foxitreader"; "Adobe Reader"="adobereader" }
        "Utilidades de Sistema" = [ordered]@{ "7-Zip"="7zip"; "WinRAR"="winrar"; "Notepad++"="notepadplusplus"; "Everything"="everything"; "WinDirStat"="windirstat"; "TreeSize Free"="treesizefree"; "Double Commander"="doublecmd"; "OpenSSH"="openssh"; "Windows Terminal"="microsoft-windows-terminal"; "PowerShell"="powershell"; "WSL 2"="wsl2"; "AutoHotkey"="autohotkey"; "Wget"="wget" }
        "Multimedia" = [ordered]@{ "VLC"="vlc"; "Audacity"="audacity"; "GIMP"="gimp"; "Inkscape"="inkscape"; "Pinta"="pinta"; "Paint.NET"="paint.net"; "ImageMagick"="imagemagick"; "IrfanView"="irfanview"; "IrfanView Plugins"="irfanviewplugins"; "ImageGlass"="imageglass"; "Darktable"="darktable"; "Spotify"="spotify" }
        "Limpieza" = [ordered]@{ "BleachBit (v5)"="bleachbit"; "Glary Utilities"="glaryutilities-free"; "Recuva"="recuva"; "Defraggler"="defraggler"; "PatchCleaner"="patchcleaner"; "Remove Empty Dirs"="remove-empty-directories"; "DupeGuru"="dupeguru"; "Speccy"="speccy"; "CrystalDiskInfo"="crystaldiskinfo" }
        "Red y Remoto" = [ordered]@{ "PuTTY"="putty"; "Advanced IP Scanner"="advanced-ip-scanner"; "Angry IP Scanner"="angryip"; "TightVNC"="tightvnc"; "AnyDesk"="anydesk"; "RustDesk"="rustdesk"; "Virtual CloneDrive"="virtualclonedrive"; "Chrome Remote Desktop"="chrome-remote-desktop-host"; "Free Download Manager"="freedownloadmanager" }
        "Nube" = [ordered]@{ "Google Drive"="googledrive"; "Nextcloud Client"="nextcloud-client" }
        "Comunicaciones" = [ordered]@{ "Zoom"="zoom"; "Microsoft Teams"="microsoft-teams"; "Thunderbird"="thunderbird" }
        "Utilidades Varias" = [ordered]@{ "Bulk Crap Uninstaller"="bulk-crap-uninstaller"; "iSpy"="ispy"; "Folder Marker"="folder-marker"; "SoundSwitch"="soundswitch"; "TrayStatus"="traystatus"; "Meld"="meld"; "WinMerge"="winmerge" }
    }
    $defaults = @("nextcloud-client","googledrive","imageglass","vlc","bulk-crap-uninstaller","googlechrome","firefox","foxitreader","crystaldiskinfo","speccy","patchcleaner","recuva","bleachbit","anydesk","notepadplusplus","winrar","doublecmd")
    $installed = Get-InstalledChoco

    $ctx = New-GUIForm "Software (Chocolatey)" "Selecciona software para instalar/desinstalar:"
    $x = 10
    foreach ($bd in @(@("Recomendados","30,100,180"), @("Todo","30,100,180"), @("Nada","60,60,60"), @("Invertir","60,60,60"))) {
        $b = New-GUIButton $bd[0] $bd[1] 110 34; $b.Location = New-Object System.Drawing.Point($x, 8); $ctx.BottomPanel.Controls.Add($b); $x += 118
    }
    $bIns = New-GUIButton "INSTALAR" "30,130,76" 130 34; $bIns.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 280), 8); $ctx.BottomPanel.Controls.Add($bIns)
    $bUns = New-GUIButton "DESINSTALAR" "180,50,50" 130 34; $bUns.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 140), 8); $ctx.BottomPanel.Controls.Add($bUns)
    $bCan = New-GUIButton "CANCELAR" "80,40,40" 100 34; $bCan.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 390), 8); $ctx.BottomPanel.Controls.Add($bCan)
    $script:chocoAction = "install"
    $bIns.Add_Click({ $script:chocoAction = "install"; $ctx.Form.DialogResult = "OK"; $ctx.Form.Close() }.GetNewClosure())
    $bUns.Add_Click({ $script:chocoAction = "uninstall"; $ctx.Form.DialogResult = "OK"; $ctx.Form.Close() }.GetNewClosure())
    $bCan.Add_Click({ $ctx.Form.DialogResult = "Cancel"; $ctx.Form.Close() }.GetNewClosure())
    $selBtns = @{ Recomendados = $ctx.BottomPanel.Controls[0]; Todo = $ctx.BottomPanel.Controls[1]; Nada = $ctx.BottomPanel.Controls[2]; Invertir = $ctx.BottomPanel.Controls[3] }
    $selBtns.Recomendados.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = $defaults -contains $cb.Tag } }.GetNewClosure())
    $selBtns.Todo.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = $true } }.GetNewClosure())
    $selBtns.Nada.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = $false } }.GetNewClosure())
    $selBtns.Invertir.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = !$cb.Checked } }.GetNewClosure())

    foreach ($cat in $apps.Keys) {
        Add-GUICategory $ctx $cat "0,150,213"
        foreach ($name in $apps[$cat].Keys) {
            $pkgId = $apps[$cat][$name]; $isInstalled = $installed -contains $pkgId
            $color = if ($isInstalled) { "80,200,100" } else { "White" }
            $suffix = if ($isInstalled) { " [INSTALADO]" } else { "" }
            Add-GUICheckboxRow $ctx $name $pkgId $color $false $suffix
        }
    }
    Complete-GUITable $ctx

    $result = $ctx.Form.ShowDialog()
    if ($result -eq "OK") {
        $ids = @(); foreach ($cb in $ctx.CBs) { if ($cb.Checked) { $ids += $cb.Tag } }
        if ($ids.Count -gt 0) {
            if ($script:chocoAction -eq "uninstall") {
                $c = [System.Windows.Forms.MessageBox]::Show("Desinstalar $($ids.Count) paquetes?", "Confirmar", "YesNo", "Warning")
                if ($c -ne "Yes") { return @() }
            }
            $total = $ids.Count; $ok = 0; $fail = 0
            $action = if ($script:chocoAction -eq "install") { "INSTALANDO" } else { "DESINSTALANDO" }
            Write-Host "`n--- $action $total paquetes ---" -ForegroundColor Yellow
            foreach ($pkg in $ids) {
                $i = [array]::IndexOf($ids, $pkg) + 1
                Write-Host "`n[$i/$total] $pkg" -ForegroundColor Cyan
                try {
                    if ($pkg -eq "bleachbit" -and $script:chocoAction -eq "install") {
                        $chocoArgs = "install bleachbit --version=5.0.2 -y --ignore-checksums"
                    } else { $chocoArgs = "$($script:chocoAction) $pkg -y --ignore-checksums" }
                    $proc = Start-Process "choco" -ArgumentList $chocoArgs -Wait -PassThru -NoNewWindow
                    if ($proc.ExitCode -eq 0) { Write-Host "[OK] $pkg" -ForegroundColor Green; $ok++ }
                    else { Write-Host "[FALLO] $pkg (exit=$($proc.ExitCode))" -ForegroundColor Red; $fail++ }
                } catch { Write-Host ("[ERROR] {0}: {1}" -f $pkg, $_) -ForegroundColor Red; $fail++ }
            }
            Write-Host "`n--- RESUMEN ---" -ForegroundColor Yellow
            Write-Host "Exitosos: $ok" -ForegroundColor Green
            if ($fail -gt 0) { Write-Host "Fallidos: $fail" -ForegroundColor Red }
            Write-Host ""
            return @("DONE")
        }
    }
    return @()
}

$script:bloatwareList = [ordered]@{
    "Xbox" = [ordered]@{ "Xbox TCUI"="Microsoft.Xbox.TCUI"; "Xbox Game Bar"="Microsoft.XboxGameOverlay"; "Xbox Identity Provider"="Microsoft.XboxIdentityProvider"; "Xbox Speech-to-Text"="Microsoft.XboxSpeechToTextOverlay"; "Xbox Gaming Overlay"="Microsoft.XboxGamingOverlay"; "Gaming App"="Microsoft.GamingApp" }
    "Social" = [ordered]@{ "Microsoft Teams"="MSTeams"; "Teams (personal)"="MicrosoftTeams"; "Phone Link"="Microsoft.YourPhone"; "Outlook (Windows)"="Microsoft.OutlookForWindows" }
    "Nube" = [ordered]@{ "OneDrive"="Microsoft.OneDrive" }
    "Media" = [ordered]@{ "Clipchamp"="Clipchamp"; "Media Player"="Microsoft.ZuneMusic"; "Solitaire"="Microsoft.MicrosoftSolitaireCollection"; "Movies & TV"="Microsoft.ZuneVideo" }
    "Utilidades MS" = [ordered]@{ "Get Help"="Microsoft.GetHelp"; "Feedback Hub"="Microsoft.WindowsFeedbackHub"; "Get Started"="Microsoft.Getstarted"; "Power Automate"="Microsoft.PowerAutomateDesktop"; "Dev Home"="Microsoft.Windows.DevHome"; "Bing News"="Microsoft.BingNews"; "Bing Weather"="Microsoft.BingWeather"; "Sticky Notes"="Microsoft.MicrosoftStickyNotes"; "To Do"="Microsoft.Todos"; "Quick Assist"="Microsoft.QuickAssist"; "Sound Recorder"="Microsoft.WindowsSoundRecorder"; "People"="Microsoft.People"; "Wallet"="Microsoft.Wallet"; "Maps"="Microsoft.WindowsMaps"; "Mixed Reality"="Microsoft.MixedReality.Portal"; "3D Viewer"="Microsoft.Microsoft3DViewer" }
    "Copilot" = [ordered]@{ "Microsoft Copilot"="Microsoft.Copilot" }
    "Se conservan" = [ordered]@{ "Calculadora"="Microsoft.WindowsCalculator"; "Paint"="Microsoft.WindowsPaint"; "Notepad"="Microsoft.WindowsNotepad"; "Reloj"="Microsoft.WindowsAlarms" }
}

function Show-BloatwareGUI {
    $ctx = New-GUIForm "Quitar Bloatware Windows 11" "Selecciona apps para INSTALAR o DESINSTALAR:"
    $x = 10
    foreach ($bd in @(@("Recomendados","30,100,180"), @("Todo","30,100,180"), @("Nada","60,60,60"), @("Invertir","60,60,60"))) {
        $b = New-GUIButton $bd[0] $bd[1] 110 34; $b.Location = New-Object System.Drawing.Point($x, 8); $ctx.BottomPanel.Controls.Add($b); $x += 118
    }
    $bIns = New-GUIButton "INSTALAR" "30,130,76" 130 34; $bIns.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 280), 8); $ctx.BottomPanel.Controls.Add($bIns)
    $bUns = New-GUIButton "DESINSTALAR" "180,50,50" 130 34; $bUns.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 140), 8); $ctx.BottomPanel.Controls.Add($bUns)
    $bCan = New-GUIButton "CANCELAR" "80,40,40" 100 34; $bCan.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 390), 8); $ctx.BottomPanel.Controls.Add($bCan)
    $script:bloatAction = "uninstall"
    $bIns.Add_Click({ $script:bloatAction = "install"; $ctx.Form.DialogResult = "OK"; $ctx.Form.Close() }.GetNewClosure())
    $bUns.Add_Click({ $script:bloatAction = "uninstall"; $ctx.Form.DialogResult = "OK"; $ctx.Form.Close() }.GetNewClosure())
    $bCan.Add_Click({ $ctx.Form.DialogResult = "Cancel"; $ctx.Form.Close() }.GetNewClosure())
    $selBtns = @{ Recomendados = $ctx.BottomPanel.Controls[0]; Todo = $ctx.BottomPanel.Controls[1]; Nada = $ctx.BottomPanel.Controls[2]; Invertir = $ctx.BottomPanel.Controls[3] }
    $selBtns.Recomendados.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = ($cb.Tag -eq "SECONSERVA") } }.GetNewClosure())
    $selBtns.Todo.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = $true } }.GetNewClosure())
    $selBtns.Nada.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = $false } }.GetNewClosure())
    $selBtns.Invertir.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = !$cb.Checked } }.GetNewClosure())

    foreach ($cat in $script:bloatwareList.Keys) {
        Add-GUICategory $ctx $cat "220,50,50"
        foreach ($name in $script:bloatwareList[$cat].Keys) {
            $pkgPattern = $script:bloatwareList[$cat][$name]; $isConserved = ($cat -eq "Se conservan")
            $isInstalled = Get-AppxPackage -Name "*$pkgPattern*" -ErrorAction SilentlyContinue
            $tag = if ($isConserved) { "SECONSERVA" } else { $pkgPattern }
            $color = if ($isConserved) { "100,200,100" } elseif ($isInstalled) { "220,160,50" } else { "White" }
            $suffix = if ($isInstalled -and -not $isConserved) { " [INSTALADO]" } else { "" }
            Add-GUICheckboxRow $ctx $name $tag $color $false $suffix
        }
    }
    Complete-GUITable $ctx

    $result = $ctx.Form.ShowDialog()
    if ($result -eq "OK") {
        $selected = @(); foreach ($cb in $ctx.CBs) { if ($cb.Checked) { $selected += $cb.Tag } }
        $selected = $selected | Where-Object { $_ -ne "SECONSERVA" }
        if ($selected.Count -gt 0) {
            $actionText = if ($script:bloatAction -eq "install") { "Instalar" } else { "Desinstalar" }
            $c = [System.Windows.Forms.MessageBox]::Show("$actionText $($selected.Count) apps de Windows?", "Confirmar", "YesNo", "Warning")
            if ($c -ne "Yes") { return }
            $total = $selected.Count; $ok = 0; $fail = 0; $skip = 0
            $action = if ($script:bloatAction -eq 'install') { 'INSTALANDO' } else { 'QUITANDO' }
            Write-Host "`n--- $action $total apps ---" -ForegroundColor Yellow
            $i = 0
            foreach ($pattern in $selected) {
                $i++; Write-Host "[$i/$total] $pattern..." -ForegroundColor Cyan -NoNewline
                try {
                    if ($script:bloatAction -eq "uninstall") {
                        $pkg = Get-AppxPackage -Name "*$pattern*" -ErrorAction Stop
                        if ($pkg) { $pkg | Remove-AppxPackage -AllUsers -ErrorAction Stop; Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*$pattern*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; Write-Host " [OK]" -ForegroundColor Green; $ok++ }
                        else { Write-Host " [ya no esta]" -ForegroundColor DarkGray; $skip++ }
                    } else {
                        $pkg = Get-AppxPackage -Name "*$pattern*" -ErrorAction SilentlyContinue
                        if (-not $pkg) { Add-AppxPackage -Register "$env:ProgramFiles\WindowsApps\*\AppxManifest.xml" -ErrorAction Stop; Write-Host " [OK]" -ForegroundColor Green; $ok++ }
                        else { Write-Host " [ya instalado]" -ForegroundColor DarkGray; $skip++ }
                    }
                } catch { Write-Host " [ERROR: $_]" -ForegroundColor Red; $fail++ }
            }
            Write-Host "`n--- RESUMEN ---" -ForegroundColor Yellow
            Write-Host "Exitosos: $ok" -ForegroundColor Green
            if ($skip -gt 0) { Write-Host "Omitidos: $skip" -ForegroundColor DarkGray }
            if ($fail -gt 0) { Write-Host "Fallidos: $fail" -ForegroundColor Red }
            Write-Host ""
            Pause-Script
        }
    }
}

$script:blockItems = @(
    @{ Name="OneDrive"; Uninstall=@{ Label="Desinstalar OneDrive"; Action={
        taskkill /f /im OneDrive.exe 2>$null; $od64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"; $od32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
        if (Test-Path $od64) { & $od64 /uninstall } elseif (Test-Path $od32) { & $od32 /uninstall }
        try { Get-AppxPackage -AllUsers *OneDrive* | Remove-AppxPackage -AllUsers -ErrorAction Stop } catch {}
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" Personal "$env:USERPROFILE\Documents" -Force
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" Desktop "$env:USERPROFILE\Desktop" -Force
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" "My Pictures" "$env:USERPROFILE\Pictures" -Force
        Remove-Item "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    }}; Block=@{ Label="Bloquear OneDrive"; Action={
        $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"; if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        New-ItemProperty -Path $p -Name "DisableFileSync" -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $p -Name "DisableFileSyncNGSC" -PropertyType DWord -Value 1 -Force | Out-Null
    }}}
    @{ Name="Teams"; Uninstall=@{ Label="Desinstalar Teams"; Action={
        try { Get-AppxPackage *MSTeams* -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Stop } catch {}
        try { Get-AppxPackage *MicrosoftTeams* -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Stop } catch {}
        try { Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*Teams*" } | Remove-AppxProvisionedPackage -Online -ErrorAction Stop } catch {}
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Teams" -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Teams" -Force -ErrorAction SilentlyContinue
    }}; Block=@{ Label="Bloquear Teams"; Action={
        $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Chat"; if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        New-ItemProperty -Path $p -Name "ChatIcon" -PropertyType DWord -Value 3 -Force | Out-Null
    }}}
    @{ Name="Copilot"; Uninstall=@{ Label="Desinstalar Copilot"; Action={
        try { Get-AppxPackage *Microsoft.Copilot* -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Stop } catch {}
        try { Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*Copilot*" } | Remove-AppxProvisionedPackage -Online -ErrorAction Stop } catch {}
    }}; Block=@{ Label="Bloquear Copilot"; Action={
        foreach ($rk in @("HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot","HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot")) {
            if (!(Test-Path $rk)) { New-Item -Path $rk -Force -ErrorAction SilentlyContinue | Out-Null }
            New-ItemProperty -Path $rk -Name "TurnOffWindowsCopilot" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
        }
        $cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        New-ItemProperty -Path $cdm -Name "SilentInstalledAppsEnabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
    }}}
    @{ Name="Edge"; Uninstall=@{ Label="Desinstalar Edge (COMPLETO)"; Action={
        Write-Host "Matando procesos de Edge..." -ForegroundColor Yellow
        @("msedge","msedge-crx","MicrosoftEdge","MicrosoftEdgeCP","MicrosoftEdgeSM","edgeUpdate","edgecrashpad") | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 2

        Write-Host "Deteniendo servicios Edge Update..." -ForegroundColor Yellow
        @("edgeupdate","edgeupdatem","MicrosoftEdgeElevationService") | ForEach-Object {
            Stop-Service $_ -Force -ErrorAction SilentlyContinue
            Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }

        Write-Host "Desinstalando Edge..." -ForegroundColor Yellow
        $setup = Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($setup) { & $setup.FullName -uninstall -system-level -verbose-logging -force-uninstall }
        try { Get-AppxPackage -AllUsers *MicrosoftEdge* | Remove-AppxPackage -AllUsers -ErrorAction Stop } catch {}
        try { Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*MicrosoftEdge*" } | Remove-AppxProvisionedPackage -Online -ErrorAction Stop } catch {}

        Write-Host "Desinstalando Edge Update..." -ForegroundColor Yellow
        $odUpdate = "C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
        if (Test-Path $odUpdate) { & $odUpdate /uninstall }
        $odUpdateX64 = "C:\Program Files\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
        if (Test-Path $odUpdateX64) { & $odUpdateX64 /uninstall }

        Write-Host "Eliminando carpetas Edge..." -ForegroundColor Yellow
        @("C:\Program Files (x86)\Microsoft\Edge","C:\Program Files\Microsoft\Edge","C:\Program Files (x86)\Microsoft\EdgeUpdate","C:\Program Files\Microsoft\EdgeUpdate","$env:LOCALAPPDATA\Microsoft\Edge","$env:LOCALAPPDATA\Microsoft\EdgeUpdate") | ForEach-Object {
            if (Test-Path $_) { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }
        }

        Write-Host "Eliminando servicios Edge del registro..." -ForegroundColor Yellow
        @("edgeupdate","edgeupdatem","MicrosoftEdgeElevationService") | ForEach-Object {
            Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Services\$_" -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host "Bloqueando reinstalacion de Edge..." -ForegroundColor Yellow
        $p1 = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; if (!(Test-Path $p1)) { New-Item -Path $p1 -Force | Out-Null }
        New-ItemProperty -Path $p1 -Name "DoNotUpdateToEdgeWithChromium" -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $p1 -Name "ExcludeFromUpgrade" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
        $p2 = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\Main"; if (!(Test-Path $p2)) { New-Item -Path $p2 -Force | Out-Null }
        New-ItemProperty -Path $p2 -Name "AllowPrelaunch" -PropertyType DWord -Value 0 -Force | Out-Null
        New-ItemProperty -Path $p2 -Name "DefaultBrowserSettingEnabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

        Write-Host "`nEdge eliminado y bloqueado." -ForegroundColor Green
    }}; Block=@{ Label="Bloquear Edge (solo politicas)"; Action={
        $p1 = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; if (!(Test-Path $p1)) { New-Item -Path $p1 -Force | Out-Null }
        New-ItemProperty -Path $p1 -Name "DoNotUpdateToEdgeWithChromium" -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $p1 -Name "ExcludeFromUpgrade" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
        $p2 = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\Main"; if (!(Test-Path $p2)) { New-Item -Path $p2 -Force | Out-Null }
        New-ItemProperty -Path $p2 -Name "AllowPrelaunch" -PropertyType DWord -Value 0 -Force | Out-Null
    }}; Redirect=@{ Label="Instalar MSEdgeRedirect"; Action={
        if (Get-Command choco -ErrorAction SilentlyContinue) { choco install msedgeredirect -y 2>$null } else { Write-Host "Chocolatey no disponible" -ForegroundColor Red }
    }}}
)

function Show-BlockMicrosoft {
    $ctx = New-GUIForm "Bloquear Microsoft" "Selecciona acciones de bloqueo/desinstalacion:"
    $x = 10
    foreach ($bd in @(@("Todo","30,100,180"), @("Nada","60,60,60"), @("Invertir","60,60,60"))) {
        $b = New-GUIButton $bd[0] $bd[1] 110 34; $b.Location = New-Object System.Drawing.Point($x, 8); $ctx.BottomPanel.Controls.Add($b); $x += 118
    }
    $bIns = New-GUIButton "DESINSTALAR" "180,50,50" 130 34; $bIns.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 280), 8); $ctx.BottomPanel.Controls.Add($bIns)
    $bBlk = New-GUIButton "BLOQUEAR" "180,130,30" 130 34; $bBlk.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 140), 8); $ctx.BottomPanel.Controls.Add($bBlk)
    $bCan = New-GUIButton "CANCELAR" "80,40,40" 100 34; $bCan.Location = New-Object System.Drawing.Point(($ctx.BottomPanel.Width - 390), 8); $ctx.BottomPanel.Controls.Add($bCan)
    $bIns.Add_Click({
        $selected = @(); foreach ($cb in $ctx.CBs) { if ($cb.Checked -and $cb.Tag.Type -eq "Uninstall") { $selected += $cb.Tag.Action } }
        if ($selected.Count -gt 0) { $ctx.ActionList = $selected; $ctx.Form.DialogResult = "OK"; $ctx.Form.Close() }
        else { [System.Windows.Forms.MessageBox]::Show("No hay acciones de desinstalacion seleccionadas.", "Aviso", "OK", "Information") }
    }.GetNewClosure())
    $bBlk.Add_Click({
        $selected = @(); foreach ($cb in $ctx.CBs) { if ($cb.Checked -and ($cb.Tag.Type -eq "Block" -or $cb.Tag.Type -eq "Redirect")) { $selected += $cb.Tag.Action } }
        if ($selected.Count -gt 0) { $ctx.ActionList = $selected; $ctx.Form.DialogResult = "OK"; $ctx.Form.Close() }
        else { [System.Windows.Forms.MessageBox]::Show("No hay acciones de bloqueo/redireccion seleccionadas.", "Aviso", "OK", "Information") }
    }.GetNewClosure())
    $bCan.Add_Click({ $ctx.Form.DialogResult = "Cancel"; $ctx.Form.Close() }.GetNewClosure())
    $selBtns = @{ Todo = $ctx.BottomPanel.Controls[0]; Nada = $ctx.BottomPanel.Controls[1]; Invertir = $ctx.BottomPanel.Controls[2] }
    $selBtns.Todo.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = $true } }.GetNewClosure())
    $selBtns.Nada.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = $false } }.GetNewClosure())
    $selBtns.Invertir.Add_Click({ foreach ($cb in $ctx.CBs) { $cb.Checked = !$cb.Checked } }.GetNewClosure())

    foreach ($item in $script:blockItems) {
        Add-GUICategory $ctx $item.Name "220,160,50"
        foreach ($actType in @("Uninstall","Block","Redirect")) {
            if ($item.$actType) { Add-GUICheckboxRow $ctx $item.$actType.Label @{ Type=$actType; Action=$item.$actType.Action } "White" $false "" }
        }
    }
    Complete-GUITable $ctx

    $result = $ctx.Form.ShowDialog()
    if ($result -eq "OK") {
        $selected = $ctx.ActionList
        if ($selected.Count -gt 0) {
            $c = [System.Windows.Forms.MessageBox]::Show("Ejecutar $($selected.Count) acciones?", "Confirmar", "YesNo", "Warning")
            if ($c -ne "Yes") { return }
            $total = $selected.Count; $ok = 0; $fail = 0
            Write-Host "`n--- EJECUTANDO $total ACCIONES ---" -ForegroundColor Yellow
            $i = 0; foreach ($action in $selected) {
                $i++; Write-Host "[$i/$total]" -ForegroundColor Cyan -NoNewline
                try { & $action; Write-Host " [OK]" -ForegroundColor Green; $ok++ }
                catch { Write-Host " [ERROR: $_]" -ForegroundColor Red; $fail++ }
            }
            Write-Host "`n--- RESUMEN ---" -ForegroundColor Yellow
            Write-Host "Exitosas: $ok" -ForegroundColor Green
            if ($fail -gt 0) { Write-Host "Fallidas: $fail" -ForegroundColor Red }
            Write-Host ""; Pause-Script
        }
    }
}

function Menu-Software {
    while ($true) {
        Show-Header "SOFTWARE"
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host "Chocolatey no detectado. Instalando..." -ForegroundColor Yellow
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"
        }
        Write-Host "1. Instalar/Desinstalar Software (GUI Chocolatey)"
        Write-Host "2. Quitar Bloatware Windows 11"
        Write-Host "3. Bloquear Microsoft (OneDrive/Teams/Copilot/Edge)"
        Write-Host "4. Actualizar Todo (Upgrade All)"
        Write-Host "5. Crear Tarea Auto-Update (Laborables)"
        Write-Host "X. Volver" -ForegroundColor Gray
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" { Show-ChocoGUI | Out-Null }
            "2" { Show-BloatwareGUI }
            "3" { Show-BlockMicrosoft }
            "4" { choco upgrade all -y; Pause-Script }
            "5" { Func-TareaChoco }
        }
    }
}

# ==============================================================================
# BLOQUE 6: RED Y HERRAMIENTAS
# ==============================================================================

function Func-InfoHardware {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "                  RESUMEN DE HARDWARE" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $sys = Get-CimInstance Win32_ComputerSystem
    $mobo = Get-CimInstance Win32_BaseBoard
    Write-Host "--- SISTEMA ---" -ForegroundColor Yellow
    Write-Host "Fabricante : $($sys.Manufacturer)"
    Write-Host "Modelo     : $($sys.Model)"
    Write-Host "Placa Base : $($mobo.Manufacturer) - $($mobo.Product)"
    Write-Host "Nombre     : $($sys.Name)"
    Write-Host "Dominio/Grup: $($sys.Workgroup)"

    $cpu = Get-CimInstance Win32_Processor
    Write-Host "`n--- PROCESADOR ---" -ForegroundColor Yellow
    Write-Host "Modelo     : $($cpu.Name)"
    Write-Host "Nucleos    : $($cpu.NumberOfCores) Fisicos / $($cpu.NumberOfLogicalProcessors) Logicos"

    $ram = Get-CimInstance Win32_PhysicalMemory
    $memArray = Get-CimInstance Win32_PhysicalMemoryArray
    $totalRam = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
    $maxRam = 0
    if ($memArray.MaxCapacity) { $maxRam = [math]::Round(($memArray.MaxCapacity / 1024 / 1024), 0) }

    Write-Host "`n--- MEMORIA RAM ---" -ForegroundColor Yellow
    Write-Host "Total Inst : $([math]::Round($totalRam, 1)) GB"
    if ($maxRam -gt 0) { Write-Host "Max Soportada: $maxRam GB" -ForegroundColor Green }
    else { Write-Host "Max Soportada: (No reportado por BIOS)" -ForegroundColor DarkGray }
    Write-Host "Slots Usados: $($ram.Count)"
    foreach ($r in $ram) {
        Write-Host " -> Slot: $([math]::Round($r.Capacity/1GB, 0)) GB @ $($r.Speed) MHz ($($r.Manufacturer))" -ForegroundColor DarkGray
    }

    $disks = Get-CimInstance Win32_DiskDrive
    Write-Host "`n--- ALMACENAMIENTO ---" -ForegroundColor Yellow
    foreach ($d in $disks) {
        $sizeGB = [math]::Round($d.Size / 1GB, 0)
        Write-Host " -> Modelo: $($d.Model)"
        Write-Host "    Capacidad: $sizeGB GB"
        Write-Host "    Interfaz:  $($d.InterfaceType)" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "--- RED ACTIVA ---" -ForegroundColor Yellow
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        $ip = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4).IPAddress
        Write-Host " -> $($_.Name) ($($_.InterfaceDescription))"
        Write-Host "    IP: $ip" -ForegroundColor Green
    }
    
    Pause-Script
}

function Func-MonitorProcesos {
    Clear-Host
    Write-Host "--- MONITOR DE PROCESOS ---" -ForegroundColor Cyan
    $inp = Read-Host "Cuantas muestras? (0 = Infinito, Enter = 1)"
    if ($inp -eq "") { $veces = 1 } else { $veces = [int]$inp }
    
    $infinito = ($veces -eq 0)
    $contador = 0
    
    while ($true) {
        Clear-Host
        $time = Get-Date -Format "HH:mm:ss"
        Write-Host "--- MONITOR DE RECURSOS ($time) ---" -ForegroundColor Cyan
        if ($infinito) { Write-Host "(Presione cualquier tecla para salir...)" -ForegroundColor Gray }
        
        Write-Host "`n[TOP RAM]" -ForegroundColor Yellow
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | Format-Table Id, ProcessName, @{N='RAM(MB)';E={[math]::Round($_.WorkingSet/1MB,0)}} -AutoSize
        
        Write-Host "`n[TOP CPU]" -ForegroundColor Yellow
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Format-Table Id, ProcessName, CPU -AutoSize

        if (!$infinito) {
            $contador++
            if ($contador -ge $veces) { break }
        } else {
            if ([Console]::KeyAvailable) { 
                $null = [Console]::ReadKey($true)
                break 
            }
        }
        Start-Sleep -Seconds 2
    }
    Pause-Script
}

function Menu-Red {
    while ($true) {
        Show-Header "RED Y HERRAMIENTAS"
        Write-Host "1. Renombrar y Unir Grupo ($($config.Red.Workgroup))"
        Write-Host "2. Configurar como SERVIDOR (Permitir Acceso WinRM/Ping)"
        Write-Host "3. Conectar a Cliente (Remoto PowerShell)"
        Write-Host "4. Forzar Red Privada"
        Write-Host "5. Info Hardware (Detallado)"
        Write-Host "6. Monitor de Procesos (Tiempo Real)"
        Write-Host "7. Massgrave (Activacion Windows/Office)"
        Write-Host "X. Volver" -ForegroundColor Gray
        
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" {
                $n = Read-Host "Nuevo Nombre"
                if ($n) { Rename-Computer -NewName $n -ErrorAction SilentlyContinue }
                
                $wg = Prompt-Config "Grupo de Trabajo" $config.Red.Workgroup
                if ($wg -ne $config.Red.Workgroup) { $config.Red.Workgroup = $wg; Save-Config }

                Add-Computer -WorkGroupName $wg -ErrorAction SilentlyContinue
                Write-Host "Reinicie para aplicar." -ForegroundColor Red; Pause-Script
            }
            "2" {
                Enable-PSRemoting -Force
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
                New-NetFirewallRule -DisplayName "Allow Ping" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow -ErrorAction SilentlyContinue
                Write-Host "Acceso Remoto y Ping Habilitados." -ForegroundColor Green; Pause-Script
            }
            "3" {
                $pc = Read-Host "IP/Nombre Destino (X para cancelar)"
                if ($pc -ne "X" -and $pc -ne "x") {
                    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $pc -Concatenate -Force
                    Enter-PSSession -ComputerName $pc -Credential (Get-Credential)
                }
            }
            "4" {
                Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
                Write-Host "Red ahora es PRIVADA." -ForegroundColor Green; Pause-Script
            }
            "5" { Func-InfoHardware }
            "6" { Func-MonitorProcesos }
            "7" { irm https://get.activated.win | iex; Pause-Script }
        }
    }
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

while ($true) {
    Show-Header
    Write-Host "[!] Config actual: $($config.General.CompanyName) | $($config.Red.Workgroup) | $($config.Region.Locale)" -ForegroundColor DarkGray
    Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
    
    Write-Host "0. Modificar Identidad General (Empresa/Titulo)" -ForegroundColor White
    Write-Host "1. Usuarios y Rutas" -ForegroundColor Yellow
    Write-Host "2. Region y Reloj (Menu)" -ForegroundColor Magenta
    Write-Host "3. Optimizacion y Mantenimiento (Limpieza/Reparacion/Debloat)" -ForegroundColor Cyan
    Write-Host "4. Software (GUI y Tareas)" -ForegroundColor Green
    Write-Host "5. Tareas Programadas" -ForegroundColor Blue
    Write-Host "6. Red y Herramientas" -ForegroundColor Gray
    Write-Host "X. Salir" -ForegroundColor Red
    
    $m = Read-Host "Opcion"
    switch ($m) {
        "0" {
            $comp = Prompt-Config "Nombre de la Empresa" $config.General.CompanyName
            $suit = Prompt-Config "Nombre de tu Suite" $config.General.SuiteName
            if ($comp -ne $config.General.CompanyName -or $suit -ne $config.General.SuiteName) {
                $config.General.CompanyName = $comp
                $config.General.SuiteName = $suit
                $Host.UI.RawUI.WindowTitle = "$suit v11.0 - $comp"
                Save-Config
            }
        }
        "1" { Menu-Usuarios }
        "2" { Menu-RegionReloj }
        "3" { Menu-Optimizacion }
        "4" { Menu-Software }
        "5" { Menu-Tareas }
        "6" { Menu-Red }
        "X" { exit }
        "x" { exit }
    }
}
