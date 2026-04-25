****🛠️ Suite de Gestión Integral para Windows (PowerShell)****

Una potente suite interactiva basada en PowerShell diseñada para automatizar, optimizar y estandarizar la configuración y el mantenimiento de equipos con Windows. Ideal para administradores de TI, técnicos de Helpdesk y entornos empresariales que buscan desplegar equipos de forma rápida y sin complicaciones.

Esta herramienta elimina la necesidad de memorizar comandos complejos ofreciendo un menú interactivo y un sistema de configuración "inteligente" que aprende de tu entorno.

✨ Características Principales
🧠 Motor de Configuración Híbrido: Olvídate de editar código fuente. El script utiliza un sistema de "Smart Prompts" respaldado por un archivo config.json. La primera vez que lo usas, te pregunta tus preferencias (Nombre de empresa, dominio, zona horaria); las siguientes veces, las carga automáticamente.

👥 Gestión Rápida de Usuarios: Creación ágil de usuarios locales y redirección automática de carpetas de perfil (Escritorio, Documentos, Descargas) a particiones secundarias.

🧹 Mantenimiento y Debloat Profundo: Herramientas integradas para limpieza de temporales, reparación del sistema (CHKDSK, SFC, DISM) y acceso directo a los mejores scripts de optimización de la comunidad (Chris Titus, Raphi.re, Sycnex).

📦 Despliegue de Software con GUI: Incluye una interfaz gráfica generada en Windows Forms para instalar aplicaciones en lote de forma silenciosa a través de Chocolatey.

⏰ Automatización de Tareas: Creación sencilla de tareas programadas comunes (Mantenimiento, apagados nocturnos, reinicios forzados, alarmas/videos para pausas laborales).

🌐 Gestión de Red y Región: Unión a grupos de trabajo, habilitación de administración remota (WinRM), forzado de red privada y sincronización de hora dual (NTP y HTTP).

🚀 Cómo Empezar
Descarga o clona este repositorio en el equipo destino.

Haz clic derecho sobre el archivo SScripCMC.ps1 y selecciona Ejecutar con PowerShell (Requiere privilegios de Administrador).

En el menú principal, utiliza la Opción 0 para establecer el nombre de tu empresa y personalizar el título de la herramienta.

Navega por los menús interactivos. El archivo config.json se generará automáticamente en la misma carpeta para guardar tus preferencias.

⚙️ El Archivo config.json
Si deseas preparar la herramienta para un despliegue masivo (ej. en un pendrive USB para configurar 50 computadoras), simplemente edita el archivo config.json antes de ejecutar el script. Esto pre-cargará todas tus rutas, grupos de trabajo y horarios, permitiéndote presionar "Enter" en cada paso sin tener que teclear nada.
