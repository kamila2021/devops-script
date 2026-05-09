# DevOps Monitoring Scripts 🖥️
 
Este es un pequeño toolkit en Bash que construí para automatizar el monitoreo de salud de servidores Linux. Lo desarrollé como parte de mi ruta de aprendizaje en DevOps y Cloud, enfocándome en buenas prácticas de scripting y gestión de sistemas.
 
## 🚀 Funcionalidades
 
- **Monitoreo de CPU**: Porcentaje de uso y el Top 5 de procesos que más consumen.
- **Gestión de Memoria**: Uso de RAM con alertas configurables (Warn/Crit).
- **Control de Disco**: Revisión por partición con umbrales de alerta (80% warning / 90% crítico).
- **Estado de Red**: Interfaces activas, puertos en escucha y prueba rápida de conectividad.
- **Servicios Críticos**: Chequeo de estado de servicios comunes (Nginx, Docker, SSH, etc.).
- **Modo "Watch"**: Monitoreo continuo con intervalos personalizables.
- **Reportes Automáticos**: Genera archivos `.txt` con fecha y hora para auditoría.
 
## 🛠️ Cómo usarlo
 
Primero asegúrate de darle permisos de ejecución:
```bash
chmod +x server-health.sh
```

Luego puedes correrlo de distintas formas:
 
```bash
# Generar un reporte único
./server-health.sh
 
# Modo monitoreo (se actualiza cada 60 segundos)
./server-health.sh --watch
 
# Personalizar intervalo y carpeta de salida
./server-health.sh --watch --interval 30 --output ./mis_reportes
```
 
## 🧠 ¿Qué aprendí con este proyecto?
 
Este fue mi primer paso sólido en la fase 1 de mi roadmap DevOps:
- Dominio de permisos, procesos y gestión de sistemas de archivos en Linux.
- Scripting "profesional": uso de `set -euo pipefail`, manejo de errores y modularidad.
- Diagnóstico de redes y gestión de puertos desde la terminal.
- Diseño de herramientas pensadas para producción (no solo un script que imprime texto, sino algo útil y robusto).
 
## 🧪 Pruebas
 
Incluí una suite de tests básica para asegurar que todo funcione después de cada cambio:
 
```bash
chmod +x tests/test-health.sh
./tests/test-health.sh
```
 
---
**Autor:** Kamila Opazo — Cloud/DevOps Engineer en formación
**GitHub:** [kamila2021](https://github.com/kamila2021)
