# 🛠️ SuperScriptcmc — Suite de Gestión Integral para Windows (PowerShell)

**v11.0** · SScripCMC

**ES:** Potente suite interactiva en PowerShell para automatizar, optimizar y estandarizar la configuración y el mantenimiento de equipos **Windows**. Pensada para administradores de TI, técnicos de Helpdesk y entornos empresariales que necesitan desplegar equipos de forma rápida y sin complicaciones.

**EN:** A powerful interactive PowerShell suite to automate, optimize and standardize the setup and maintenance of **Windows** machines. Built for IT admins, Helpdesk technicians and corporate environments that need fast, hassle-free provisioning.

> Elimina la necesidad de memorizar comandos complejos: ofrece un **menú interactivo** y un sistema de configuración «inteligente» que aprende de tu entorno.
> No need to memorize complex commands: it provides an **interactive menu** and a "smart" configuration system that learns from your environment.

---

## ✨ Características principales / Main features

| | Función (ES) | Feature (EN) |
|:-:|:---|:---|
| 🧠 | **Motor de Configuración Híbrido**: sistema de *Smart Prompts* con `config.json`. La primera vez pregunta tus preferencias (empresa, grupo de trabajo, horarios, locale); luego las carga solas. | **Hybrid Config Engine**: *Smart Prompts* backed by `config.json`. Ask once, reuse forever. |
| 👥 | **Gestión Rápida de Usuarios**: creación ágil de usuarios locales y redirección de carpetas de perfil (Escritorio, Documentos, Descargas) a particiones secundarias. | **Fast User Management**: quick local users plus profile-folder redirection to secondary drives. |
| 🧹 | **Mantenimiento y Debloat Profundo**: limpieza de temporales (todos los usuarios), reparación del sistema (CHKDSK → SFC → DISM), punto de restauración, optimización de gráficos, eliminación de Widgets, bloqueo de OneDrive y remoción del OOBE / experiencia de primer usuario. | **Maintenance & Deep Debloat**: temp cleanup (all users), system repair (CHKDSK → SFC → DISM), restore point, graphics tuning, Widgets removal, OneDrive blocking and OOBE / first-run experience removal. |
| 🌎 | **Región y Reloj (Ecuador)**: instalación del idioma **es-EC** con detección de lo ya instalado, formato regional correcto (decimal `.`, miles `,`, fecha `dd/MM/yyyy`, semana inicia lunes) y sincronización de hora dual (**NTP** y vía **HTTP**). | **Region & Clock (Ecuador)**: **es-EC** language install with already-installed detection, correct regional format (decimal `.`, thousands `,`, date `dd/MM/yyyy`, week starts Monday) and dual time sync (**NTP** and **HTTP**). |
| 📦 | **Despliegue de Software con GUI**: interfaz en Windows Forms para instalar/desinstalar aplicaciones en lote, en silencio, vía **Chocolatey** (catálogo de 55+ apps). Incluye *Quitar Bloatware de Windows 11* y *Bloquear Microsoft* (OneDrive / Teams / Copilot / Edge). | **GUI Software Deployment**: Windows Forms UI for silent, batch app installs/uninstalls via **Chocolatey** (55+ app catalog). Includes *Remove Windows 11 Bloatware* and *Block Microsoft* (OneDrive / Teams / Copilot / Edge). |
| ⏰ | **Automatización de Tareas**: tareas programadas de mantenimiento, apagado nocturno, reinicios forzados, actualización diaria de Chocolatey y alarmas/videos para pausas. | **Task Automation**: scheduled maintenance, nightly shutdown, forced reboots, daily Chocolatey update and break-time alarms/videos. |
| 🌐 | **Red y Herramientas**: unión a grupo de trabajo, administración remota (WinRM), forzar red privada, e inspección del equipo (info de hardware detallado y monitor de procesos en tiempo real). | **Network & Tools**: workgroup join, remote administration (WinRM), force private network, and machine inspection (detailed hardware info and real-time process monitor). |

---

## 🆕 Novedades v11.0 / What's new in v11.0

- **Consolidación** de las versiones v10.0, v10.1 y la *Versión Universal* en un solo script.
- **Formato regional de Ecuador** realmente aplicado: se inyectan `Locale`, `sCountry`, `Geo\Name` y `Geo\Nation`, no solo los separadores; se propaga al *Default User*, a todos los perfiles en línea y a los *hives* `NTUSER.DAT` offline.
- **Instalación de idioma es-EC** con detección previa (no vuelve a descargar lo que ya está) y respaldo vía `Add-WindowsCapability`.
- **Quitar Bloatware** con rejilla en dos columnas y set de «Recomendados» seleccionado por defecto.
- **Bloquear Microsoft**: desinstalación de AppX de OneDrive, Teams, Copilot y Edge tolerante a equipos con sesiones de usuario activas.
- **Info de hardware detallado** (placa base, RAM máxima soportada) y **monitor de procesos** en tiempo real.

---

## 🚀 Cómo empezar / Getting started

1. **ES:** Descarga o clona este repositorio en el equipo destino. **EN:** Download or clone this repository on the target machine.
2. **ES:** Haz clic derecho sobre **`SuperScriptcmc.ps1`** → **Ejecutar con PowerShell** *(requiere privilegios de Administrador)*.
   **EN:** Right-click **`SuperScriptcmc.ps1`** → **Run with PowerShell** *(Administrator rights required)*.
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\SuperScriptcmc.ps1
   ```
3. **ES:** En el menú principal, usa la **Opción 0** para establecer el nombre de tu empresa y personalizar el título de la herramienta.
   **EN:** In the main menu, use **Option 0** to set your company name and customize the tool's title.
4. **ES:** Navega por los menús. El archivo `config.json` se genera automáticamente. **EN:** Browse the menus. `config.json` is generated automatically.

### 🗺️ Mapa de menús / Menu map

| Opción | Menú | Contenido |
|:-:|:---|:---|
| 0 | Identidad general | Nombre de la empresa y título de la suite |
| 1 | Usuarios y rutas | Redirección de carpetas de perfil · Crear usuario local |
| 2 | Región y reloj | Instalar es-EC + separadores · Solo separadores · Sync NTP · Sync HTTP · Tarea auto-sync |
| 3 | Optimización y mantenimiento | Limpieza · Reparación (CHKDSK/SFC/DISM) · Scripts externos · Punto de restauración · Gráficos · Widgets · Bloquear OneDrive · Quitar OOBE |
| 4 | Software | GUI Chocolatey · Quitar bloatware Win11 · Bloquear Microsoft · Upgrade all · Tarea auto-update |
| 5 | Tareas programadas | Almuerzo (VLC) · Reinicio nocturno · Apagado forzado · Choco update |
| 6 | Red y herramientas | Renombrar/unir grupo · Modo servidor (WinRM) · Cliente remoto · Red privada · Info hardware · Monitor de procesos |

---

## ⚙️ El archivo `config.json` / The `config.json` file

**ES:** Para preparar un **despliegue masivo** (p. ej. un pendrive USB para configurar 50 computadoras), edita `config.json` **antes** de ejecutar el script. Esto precarga rutas, grupos de trabajo y horarios, y luego basta con pulsar «Enter» en cada paso.

**EN:** For **mass deployment** (e.g. a USB stick to configure 50 PCs), edit `config.json` **before** running the script. It preloads paths, workgroups and schedules, so you can just press "Enter" at each step.

```json
{
  "General": { "CompanyName": "MI_EMPRESA", "SuiteName": "SScripCMC" },
  "Red":     { "Workgroup": "WORKGROUP" },
  "Tareas":  { "VideoAlmuerzo": "C:\\Ruta\\video.mp4", "HoraAlmuerzo": "13:00", "HoraReinicio": "02:00", "HoraApagado": "21:00", "HoraChoco": "13:30" },
  "Region":  { "Locale": "es-EC" }
}
```

> ℹ️ Si `config.json` no existe, el script lo crea con estos valores genéricos.
> ℹ️ If `config.json` does not exist, the script creates one with these generic defaults.

---

## 📋 Requisitos / Requirements

- **Windows** 10 / 11 (o Server equivalente).
- **PowerShell** con privilegios de **Administrador**.
- **Conexión a Internet** para el despliegue de software y los scripts de la comunidad.
- **Chocolatey** (la suite puede instalarlo/instalarse por ti) para el módulo de software.
- Algunas funciones (idioma **es-EC**, capabilities, WinRM) requieren **Windows 11 22H2+** o acceso a Windows Update.

---

## ⚠️ Notas / Notes

- Varias acciones (quitar OOBE, eliminar AppX, cambios de locale) **requieren reiniciar** para aplicar por completo.
- La desinstalación de AppX puede fallar si hay usuarios con sesión iniciada; el script lo tolera por acción.
- Revisa siempre los módulos de *debloat* y *scripts externos* antes de usarlos en un equipo de producción.

---

## ☕ Apóyame / Support me

**ES:** Si esta suite te ahorró tiempo, puedes invitarme un café. ¡Gracias!
**EN:** If this suite saved you time, buy me a coffee. Thanks!

<a href="https://ko-fi.com/cristobalmontenegro" target="_blank">
  <img height="36" style="border:0px;height:36px;" src="https://storage.ko-fi.com/cdn/kofi6.png?v=6" border="0" alt="Buy Me a Coffee at ko-fi.com" />
</a>

## 📄 Autor y licencia / Author & license

**ES:** Publicado bajo la licencia MIT. **EN:** Released under the MIT License.

— **Cristóbal Montenegro** ([@cristobalmontenegro](https://github.com/cristobalmontenegro))
