# 🛠️ SuperScriptcmc — Suite de Gestión Integral para Windows (PowerShell)

**ES:** Potente suite interactiva en PowerShell para automatizar, optimizar y estandarizar la configuración y el mantenimiento de equipos **Windows**. Pensada para administradores de TI, técnicos de Helpdesk y entornos empresariales que necesitan desplegar equipos de forma rápida y sin complicaciones.

**EN:** A powerful interactive PowerShell suite to automate, optimize and standardize the setup and maintenance of **Windows** machines. Built for IT admins, Helpdesk technicians and corporate environments that need fast, hassle-free provisioning.

> Elimina la necesidad de memorizar comandos complejos: ofrece un **menú interactivo** y un sistema de configuración «inteligente» que aprende de tu entorno.
> No need to memorize complex commands: it provides an **interactive menu** and a "smart" configuration system that learns from your environment.

---

## ✨ Características principales / Main features

| | Función (ES) | Feature (EN) |
|:-:|:---|:---|
| 🧠 | **Motor de Configuración Híbrido**: sistema de *Smart Prompts* con `config.json`. La primera vez pregunta tus preferencias (empresa, dominio, zona horaria); luego las carga solas. | **Hybrid Config Engine**: *Smart Prompts* backed by `config.json`. Ask once, reuse forever. |
| 👥 | **Gestión Rápida de Usuarios**: creación ágil de usuarios locales y redirección de carpetas de perfil (Escritorio, Documentos, Descargas) a particiones secundarias. | **Fast User Management**: quick local users plus profile-folder redirection to secondary drives. |
| 🧹 | **Mantenimiento y Debloat Profundo**: limpieza de temporales, reparación del sistema (CHKDSK, SFC, DISM) y acceso a scripts de optimización de la comunidad (Chris Titus, Raphi.re, Sycnex). | **Maintenance & Deep Debloat**: temp cleanup, system repair (CHKDSK, SFC, DISM) and community optimization scripts. |
| 📦 | **Despliegue de Software con GUI**: interfaz en Windows Forms para instalar aplicaciones en lote, en silencio, vía **Chocolatey**. | **GUI Software Deployment**: Windows Forms UI for silent, batch app installs via **Chocolatey**. |
| ⏰ | **Automatización de Tareas**: tareas programadas comunes (mantenimiento, apagados nocturnos, reinicios forzados, alarmas/videos para pausas). | **Task Automation**: scheduled tasks (maintenance, nightly shutdown, forced reboots, break-time alarms). |
| 🌐 | **Gestión de Red y Región**: unión a grupo de trabajo, administración remota (WinRM), forzar red privada y sincronización de hora dual (NTP y HTTP). | **Network & Region Management**: workgroup join, WinRM, force private network, dual time sync (NTP/HTTP). |

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

---

## ⚙️ El archivo `config.json` / The `config.json` file

**ES:** Para preparar un **despliegue masivo** (p. ej. un pendrive USB para configurar 50 computadoras), edita `config.json` **antes** de ejecutar el script. Esto precarga rutas, grupos de trabajo y horarios, y luego basta con pulsar «Enter» en cada paso.

**EN:** For **mass deployment** (e.g. a USB stick to configure 50 PCs), edit `config.json` **before** running the script. It preloads paths, workgroups and schedules, so you can just press "Enter" at each step.

---

## 📋 Requisitos / Requirements

- **Windows** 10 / 11 (o Server equivalente).
- **PowerShell** con privilegios de **Administrador**.
- **Conexión a Internet** para el despliegue de software y los scripts de la comunidad.
- **Chocolatey** (la suite puede instalarlo/instalarse por ti) para el módulo de software.

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
