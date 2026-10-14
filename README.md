# 🧰 Tools

**ES:** Herramientas variadas que uso a diario, agrupadas en un solo repositorio. Cada subcarpeta es un proyecto independiente y se puede usar por separado.

**EN:** A grab-bag of everyday tools, grouped in a single repository. Each subfolder is an independent project and can be used on its own.

---

## 🇪🇸 Contenido

| Proyecto | Tecnología | Descripción |
|:---|:---|:---|
| [**SuperScriptcmc**](./SuperScriptcmc) | PowerShell | Suite interactiva de administración para Windows (**v11.0**): gestión de usuarios, debloat, despliegue de software con GUI (Chocolatey), tareas programadas, formato regional/idioma **es-EC** y configuración de red. Configuración persistente vía `config.json`. |
| [**LectorRetenciones**](./LectorRetenciones) | HTML/JS | Lector de **comprobantes de retención del SRI (Ecuador)** que funciona 100% en el navegador: arrastras el XML y lo muestra en tablas legibles. |
| [**FlippingBook**](./FlippingBook) | HTML/JS | Visor de **PDF con efecto de libro** de páginas que se hojean (basado en `turn.js` y `pdf.js`). |
| [**actualizar.sh**](./actualizar.sh) | Bash | Script de actualización integral del sistema: APT, Snap, Flatpak, firmware (fwupd) y herramientas de desarrollo. |

## 🇬🇧 Contents

| Project | Technology | Description |
|:---|:---|:---|
| [**SuperScriptcmc**](./SuperScriptcmc) | PowerShell | Interactive Windows administration suite (**v11.0**): user management, debloat, GUI software deployment (Chocolatey), scheduled tasks, **es-EC** region/language setup and network configuration. Persistent config via `config.json`. |
| [**LectorRetenciones**](./LectorRetenciones) | HTML/JS | **Ecuador SRI withholding-receipt** reader that runs fully in the browser: drop the XML and it renders readable tables. |
| [**FlippingBook**](./FlippingBook) | HTML/JS | **PDF viewer with a page-flip book effect** (built on `turn.js` and `pdf.js`). |
| [**actualizar.sh**](./actualizar.sh) | Bash | All-in-one system update script: APT, Snap, Flatpak, firmware (fwupd) and dev tools. |

---

## 🚀 Uso rápido / Quick start

**SuperScriptcmc (Windows, PowerShell como Administrador):**
```powershell
powershell -ExecutionPolicy Bypass -File .\SuperScriptcmc\SuperScriptcmc.ps1
```

**LectorRetenciones / FlippingBook:** abre el archivo `.html` correspondiente en tu navegador.

**actualizar.sh (Linux):**
```bash
chmod +x actualizar.sh
./actualizar.sh
```

---

## ☕ Apóyame / Support me

**ES:** Si alguna herramienta te resultó útil, puedes invitarme un café. ¡Gracias!
**EN:** If any tool was useful, you can buy me a coffee. Thanks!

<a href="https://ko-fi.com/cristobalmontenegro" target="_blank">
  <img height="36" style="border:0px;height:36px;" src="https://storage.ko-fi.com/cdn/kofi6.png?v=6" border="0" alt="Buy Me a Coffee at ko-fi.com" />
</a>

## 📄 Licencia / License

**ES:** Publicado bajo la licencia MIT. **EN:** Released under the MIT License.
