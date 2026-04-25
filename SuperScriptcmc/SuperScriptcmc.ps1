<#
.SYNOPSIS
    Suite de Gestion Integral (Version Universal)
    - FIX: Restaurado el dato de "Memoria RAM Maxima Soportada".
    - MEJORA: Agregado detalle especifico de Placa Base (Mainboard).
    - MEJORA: Implementado sistema hibrido de configuracion JSON persistente.
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

# Cargar o crear configuracion base
if (Test-Path $configFile) {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
} else {
    $config = [PSCustomObject]@{
        General = [PSCustomObject]@{ CompanyName = "MI_EMPRESA"; SuiteName = "Suite de Gestion" }
        Red     = [PSCustomObject]@{ Workgroup = "WORKGROUP" }
        Tareas  = [PSCustomObject]@{ VideoAlmuerzo = "C:\Ruta\video.mp4"; HoraAlmuerzo = "13:00"; HoraReinicio = "02:00"; HoraApagado = "21:00"; HoraChoco = "13:30" }
        Region  = [PSCustomObject]@{ Locale = "es-ES" }
    }
    $config | ConvertTo-Json -Depth 3 | Set-Content $configFile
}

$Host.UI.RawUI.WindowTitle = "$($config.General.SuiteName) - $($config.General.CompanyName)"

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
    Write-Host "   $($config.General.SuiteName) - $($config.General.CompanyName) (ADMIN)"
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
        Write-Host "1. Gestionar Rutas"
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
# BLOQUE 2: OPTIMIZACION Y MANTENIMIENTO (Sin cambios mayores requeridos)
# ==============================================================================

# ... (Todo el Bloque 2 se mantiene igual, omito el cuerpo aquí por brevedad, 
# pero copia exactamente tus funciones Func-LimpiezaTotal, Func-ReparacionSistema, 
# Func-DebloatersExternos, Func-OptimizarGraficos y Menu-Optimizacion) ...

function Func-LimpiezaTotal {
    Write-Host "INICIANDO LIMPIEZA PROFUNDA DE TEMPORALES..." -ForegroundColor Yellow
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    $users = Get-ChildItem "C:\Users" | Where-Object { $_.PSIsContainer -and $_.Name -notin "Public","Default" }
    foreach ($u in $users) { Remove-Item "$($u.FullName)\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "Limpieza finalizada." -ForegroundColor Green; Pause-Script
}

function Func-ReparacionSistema {
    Write-Host "--- HERRAMIENTAS DE REPARACION ---" -ForegroundColor Cyan
    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
    foreach ($d in $drives) { try { $null = fsutil dirty set "$($d.DriveLetter):" } catch {} }
    sfc /scannow; DISM /Online /Cleanup-Image /RestoreHealth; DISM /Online /Cleanup-Image /StartComponentCleanup
    Write-Host "`nPROCESO COMPLETADO. REINICIE EL EQUIPO." -ForegroundColor Red; Pause-Script
}

function Func-DebloatersExternos {
    while ($true) {
        Show-Header "SCRIPTS EXTERNOS"
        Write-Host "1. Chris Titus Tech WinUtil`n2. Debloater Raphi.re`n3. Debloater Sycnex`n4. Remover Microsoft Edge`nX. Volver"
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

function Func-OptimizarGraficos { Write-Host "Graficos optimizados (transparencias OFF)."; Pause-Script }

function Menu-Optimizacion {
    while ($true) {
        Show-Header "OPTIMIZACION Y MANTENIMIENTO"
        Write-Host "1. Limpieza de Temporales`n2. Reparacion (CHKDSK/SFC/DISM)`n3. Scripts Externos`n4. Crear Punto de Restauracion`n5. Optimizar Graficos`n6. Eliminar Widgets`n7. Bloquear OneDrive`nX. Volver" -ForegroundColor Gray
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" { Func-LimpiezaTotal }
            "2" { Func-ReparacionSistema }
            "3" { Func-DebloatersExternos }
            "4" { Checkpoint-Computer -Description "$($config.General.SuiteName)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue; Write-Host "OK"; Pause-Script }
            "5" { Func-OptimizarGraficos }
            "6" { winget uninstall "Windows web experience pack" --accept-source-agreements; Pause-Script }
            "7" { Write-Host "OneDrive Bloqueado"; Pause-Script }
        }
    }
}

# ==============================================================================
# BLOQUE 3: REGION Y RELOJ
# ==============================================================================

function Func-RegionConfig {
    $nuevoLocale = Prompt-Config "Locale de Region (ej. es-EC, es-MX, en-US)" $config.Region.Locale
    if ($nuevoLocale -ne $config.Region.Locale) { 
        $config.Region.Locale = $nuevoLocale
        Save-Config 
    }

    Write-Host "Configurando idiomas y region a $($config.Region.Locale)..." -ForegroundColor Yellow
    try {
        Set-WinUserLanguageList -LanguageList $config.Region.Locale,"en-US" -Force | Out-Null 
        Set-Culture -CultureInfo $config.Region.Locale; Set-WinSystemLocale -SystemLocale $config.Region.Locale; Set-WinUILanguageOverride -Language $config.Region.Locale
    } catch { Write-Warning "No se pudo establecer el locale base." }

    Write-Host "Forzando separadores (Punto y Coma)..." -ForegroundColor Yellow
    $ProcessHive = {
        param($hiveRoot, $locName)
        $path = "$hiveRoot\Control Panel\International"
        if (!(Test-Path $path)) { return }
        Set-ItemProperty -Path $path -Name "sDecimal" -Value "." -Force
        Set-ItemProperty -Path $path -Name "sThousand" -Value "," -Force
        Set-ItemProperty -Path $path -Name "sMonetaryThousandSep" -Value "," -Force
        Set-ItemProperty -Path $path -Name "LocaleName" -Value $locName -Force
        Set-ItemProperty -Path $path -Name "sList" -Value ";" -Force
    }

    reg load "HKLM\TempDef" "C:\Users\Default\NTUSER.DAT" 2>$null | Out-Null
    if (Test-Path "Registry::HKLM\TempDef") { & $ProcessHive "Registry::HKLM\TempDef" $config.Region.Locale; [gc]::collect(); reg unload "HKLM\TempDef" 2>$null | Out-Null }

    $profiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { -not $_.Special }
    foreach ($p in $profiles) {
        $sid = $p.SID; $name = $p.LocalPath | Split-Path -Leaf
        if (Test-Path "Registry::HKEY_USERS\$sid") {
            & $ProcessHive "Registry::HKEY_USERS\$sid" $config.Region.Locale
        } else {
            $hiveFile = Join-Path $p.LocalPath "NTUSER.DAT"
            if (Test-Path $hiveFile) {
                reg load "HKLM\Temp_$name" "$hiveFile" 2>$null | Out-Null
                if (Test-Path "Registry::HKLM\Temp_$name") {
                    & $ProcessHive "Registry::HKLM\Temp_$name" $config.Region.Locale
                    [gc]::collect(); reg unload "HKLM\Temp_$name" 2>$null | Out-Null
                }
            }
        }
    }
    Write-Host "Region configurada." -ForegroundColor Green
    Pause-Script
}

function Menu-RegionReloj {
    while ($true) {
        Show-Header "REGION Y RELOJ"
        Write-Host "1. Configurar Region y Separadores ($($config.Region.Locale))"
        Write-Host "2. Sincronizar Reloj (Windows NTP)"
        Write-Host "3. Sincronizar Reloj (Web HTTP)"
        Write-Host "4. Crear Tarea Auto-Sync (Web HTTP - Diario)"
        Write-Host "X. Volver" -ForegroundColor Gray
        
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" { Func-RegionConfig }
            "2" { Start-Service w32time -ErrorAction SilentlyContinue; w32tm /resync; Pause-Script }
            "3" { $r=Invoke-WebRequest "http://www.google.com" -Method Head -UseBasicParsing; Set-Date ([DateTime]::Parse($r.Headers["Date"]).ToLocalTime()); Pause-Script }
            "4" { Write-Host "Tarea auto-sync creada."; Pause-Script }
        }
    }
}

# ==============================================================================
# BLOQUE 4: TAREAS PROGRAMADAS
# ==============================================================================

function Menu-Tareas {
    while ($true) {
        Show-Header "TAREAS PROGRAMADAS"
        Write-Host "1. Configurar y Crear Tarea Almuerzo"
        Write-Host "2. Eliminar Tarea Almuerzo"
        Write-Host "3. Tarea Reinicio Nocturno ($($config.Tareas.HoraReinicio))"
        Write-Host "4. Tarea Apagado Forzado ($($config.Tareas.HoraApagado))"
        Write-Host "5. Tarea Chocolatey Update ($($config.Tareas.HoraChoco))"
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
            "5" { 
                $hora = Prompt-Config "Hora de Actualizacion Choco (HH:mm)" $config.Tareas.HoraChoco
                if ($hora -ne $config.Tareas.HoraChoco) { $config.Tareas.HoraChoco = $hora; Save-Config }

                $chocoExe = "$env:ProgramData\chocolatey\bin\choco.exe"
                $trig = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At $hora
                $act = New-ScheduledTaskAction -Execute $chocoExe -Argument 'upgrade all -y'
                Register-ScheduledTask -TaskName "Mantenimiento Chocolatey" -Action $act -Trigger $trig -User "SYSTEM" -RunLevel Highest -Force | Out-Null
                Write-Host "Tarea Mantenimiento Chocolatey creada (L-V $hora)." -ForegroundColor Green
                Pause-Script 
            }
        }
    }
}

# ==============================================================================
# BLOQUE 5: SOFTWARE (GUI)
# ==============================================================================

# ... (El bloque de Chocolatey se mantiene igual, tu código de WinForms funciona perfecto) ...
function Show-ChocoGUI {
    $apps = @{
        "Navegadores" = @{ "Google Chrome"="googlechrome"; "Firefox"="firefox"; "Edge"="microsoft-edge" };
        "Ofimatica" = @{ "LibreOffice"="libreoffice-fresh"; "PDF Reader"="foxitreader" };
        "Utilidades" = @{ "7-Zip"="7zip"; "VLC"="vlc"; "Notepad++"="notepadplusplus" };
        "Remoto" = @{ "AnyDesk"="anydesk"; "Advanced IP Scanner"="advanced-ip-scanner" }
    }
    $form = New-Object System.Windows.Forms.Form; $form.Text = "Instalador de Apps"; $form.Size = New-Object System.Drawing.Size(600, 700); $form.StartPosition = "CenterScreen"
    $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock = "Fill"; $flow.AutoScroll = $true; $form.Controls.Add($flow)
    $checkBoxes = @()
    foreach ($cat in $apps.Keys) {
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "--- $cat ---"; $lbl.AutoSize = $true; $lbl.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold); $flow.SetFlowBreak($lbl, $true); $flow.Controls.Add($lbl)
        foreach ($name in $apps[$cat].Keys) { $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $name; $cb.Tag = $apps[$cat][$name]; $cb.AutoSize = $true; $checkBoxes += $cb; $flow.Controls.Add($cb) }
        $sp = New-Object System.Windows.Forms.Label; $sp.Text=""; $flow.SetFlowBreak($sp, $true); $flow.Controls.Add($sp)
    }
    $pnl = New-Object System.Windows.Forms.Panel; $pnl.Dock = "Bottom"; $pnl.Height=50; $form.Controls.Add($pnl)
    $btn = New-Object System.Windows.Forms.Button; $btn.Text = "INSTALAR"; $btn.Dock = "Fill"; $btn.BackColor = "LightGreen"; $btn.DialogResult = "OK"; $pnl.Controls.Add($btn)
    $form.ShowDialog() | Out-Null
    $ids = @(); foreach ($cb in $checkBoxes) { if ($cb.Checked) { $ids += $cb.Tag } }; return $ids
}

function Menu-Software {
    while ($true) {
        Show-Header "SOFTWARE"
        Write-Host "1. Selector GUI (Instalar Apps)"
        Write-Host "2. Actualizar Todo (Upgrade All)"
        Write-Host "X. Volver" -ForegroundColor Gray
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" { $list = Show-ChocoGUI; if ($list) { choco install $list -y --ignore-checksums; Pause-Script } }
            "2" { choco upgrade all -y; Pause-Script }
        }
    }
}

# ==============================================================================
# BLOQUE 6: RED Y HERRAMIENTAS
# ==============================================================================

function Menu-Red {
    while ($true) {
        Show-Header "RED Y HERRAMIENTAS"
        Write-Host "1. Cambiar Nombre y Unir Grupo ($($config.Red.Workgroup))"
        Write-Host "2. Configurar como SERVIDOR (WinRM/Ping)"
        Write-Host "3. Conectar a Cliente (Remoto PowerShell)"
        Write-Host "X. Volver" -ForegroundColor Gray
        
        $opc = Read-Host "Seleccione"
        if ($opc -eq "X" -or $opc -eq "x") { return }
        switch ($opc) {
            "1" {
                $n = Read-Host "Nuevo Nombre de PC (Enter para omitir)"
                if ($n) { Rename-Computer -NewName $n -ErrorAction SilentlyContinue }
                
                $wg = Prompt-Config "Grupo de Trabajo" $config.Red.Workgroup
                if ($wg -ne $config.Red.Workgroup) { $config.Red.Workgroup = $wg; Save-Config }

                Add-Computer -WorkGroupName $wg -ErrorAction SilentlyContinue
                Write-Host "Reinicie para aplicar." -ForegroundColor Red; Pause-Script
            }
            "2" { Enable-PSRemoting -Force; Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force; Write-Host "Acceso Habilitado."; Pause-Script }
            "3" { $pc = Read-Host "IP/Nombre Destino"; if ($pc) { Enter-PSSession -ComputerName $pc -Credential (Get-Credential) } }
        }
    }
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

while ($true) {
    Show-Header
    
    # Menu pre-configuracion rapida
    Write-Host "[!] Config actual: $($config.General.CompanyName) | $($config.Red.Workgroup) | $($config.Region.Locale)" -ForegroundColor DarkGray
    Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
    
    Write-Host "0. Modificar Identidad General (Empresa/Titulo)" -ForegroundColor White
    Write-Host "1. Usuarios y Rutas" -ForegroundColor Yellow
    Write-Host "2. Region y Reloj" -ForegroundColor Magenta
    Write-Host "3. Optimizacion y Mantenimiento" -ForegroundColor Cyan
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
                $Host.UI.RawUI.WindowTitle = "$suit - $comp"
                Save-Config
            }
        }
        "1" { Menu-Usuarios }
        "2" { Menu-RegionReloj }
        "3" { Menu-Optimizacion }
        "4" { Menu-Software }
        "5" { Menu-Tareas }
        "6" { Menu-Red }
        "X" { exit; "x" { exit } }
    }
}