#!/bin/bash
# server-health.sh — Monitor de salud del servidor
# Uso: ./server-health.sh [--watch] [--output /ruta/reporte.txt]
 
set -euo pipefail
 
# ── Importar módulo de colores ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/colors.sh"
 
# ── Configuración ──────────────────────────────────────────────────────
DISK_WARN_THRESHOLD=80    # Porcentaje de disco para warning
DISK_CRIT_THRESHOLD=90    # Porcentaje de disco para crítico
MEM_WARN_THRESHOLD=85     # Porcentaje de RAM para warning
REPORT_DIR="/var/log/server-health"
WATCH_MODE=false
WATCH_INTERVAL=60
 
# ── Parseo de argumentos ───────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --watch)   WATCH_MODE=true; shift ;;
    --interval) WATCH_INTERVAL="$2"; shift 2 ;;
    --output)  REPORT_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Uso: $0 [--watch] [--interval segundos] [--output directorio]"
      exit 0 ;;
    *) log_error "Argumento desconocido: $1"; exit 1 ;;
  esac
done
 
# ── Crear directorio de reportes ───────────────────────────────────────
mkdir -p "$REPORT_DIR" 2>/dev/null || REPORT_DIR="/tmp/server-health" && mkdir -p "$REPORT_DIR"
 
# ── Función: Información del sistema ───────────────────────────────────
check_system_info() {
  log_section "INFORMACIÓN DEL SISTEMA"
  echo "  Hostname:    $(hostname)"
  echo "  OS:          $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY | cut -d= -f2 | tr -d \")"
  echo "  Kernel:      $(uname -r)"
  echo "  Uptime:      $(uptime -p)"
  echo "  Fecha/Hora:  $(date)"
}
 
# ── Función: Uso de CPU ────────────────────────────────────────────────
check_cpu() {
  log_section "CPU"
 
  # Uso promedio de CPU (porcentaje idle)
  local CPU_IDLE
  CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\) id.*/\1/' | cut -d. -f1 2>/dev/null || echo "N/A")
  
  if [[ "$CPU_IDLE" =~ ^[0-9]+$ ]]; then
    CPU_USAGE=$((100 - CPU_IDLE))
  else
    CPU_USAGE="N/A"
  fi
 
  echo "  Uso de CPU: ${CPU_USAGE}%"
  echo "  Load Average: $(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo 'N/A')"
 
  # Top 5 procesos por CPU
  echo "  Top 5 procesos por CPU:"
  ps aux --sort=-%cpu 2>/dev/null | head -6 | tail -5 | awk '{printf "    %-10s %5s%% %s\n", $1, $3, $11}' || echo "    N/A"
}
 
# ── Función: Memoria RAM ───────────────────────────────────────────────
check_memory() {
  log_section "MEMORIA RAM"
 
  local TOTAL FREE USED PERCENTAGE
  if command -v free >/dev/null; then
    TOTAL=$(free -m | awk '/^Mem:/{print $2}')
    FREE=$(free -m | awk '/^Mem:/{print $4}')
    USED=$(free -m | awk '/^Mem:/{print $3}')
    PERCENTAGE=$(( (USED * 100) / TOTAL ))
 
    echo "  Total:    ${TOTAL}MB"
    echo "  Usado:    ${USED}MB (${PERCENTAGE}%)"
    echo "  Libre:    ${FREE}MB"
 
    if [ "$PERCENTAGE" -ge "$MEM_WARN_THRESHOLD" ]; then
      log_warn "Memoria al ${PERCENTAGE}% — umbral de alerta: ${MEM_WARN_THRESHOLD}%"
    fi
  else
    echo "  Comando 'free' no encontrado."
  fi
 
  # Top 5 procesos por memoria
  echo "  Top 5 procesos por memoria:"
  ps aux --sort=-%mem 2>/dev/null | head -6 | tail -5 | awk '{printf "    %-10s %5s%% %s\n", $1, $4, $11}' || echo "    N/A"
}
 
# ── Función: Uso de disco ──────────────────────────────────────────────
check_disk() {
  log_section "DISCO"
 
  # Ver todas las particiones
  echo "  Uso por partición:"
  df -h | grep -v "tmpfs\|udev\|Filesystem" | while read -r LINE; do
    local USAGE MOUNT TOTAL USED
    USAGE=$(echo "$LINE" | awk '{print $5}' | tr -d %)
    MOUNT=$(echo "$LINE" | awk '{print $6}')
    TOTAL=$(echo "$LINE" | awk '{print $2}')
    USED=$(echo "$LINE" | awk '{print $3}')
 
    printf "    %-20s %3s%% usado (%s de %s)\n" "$MOUNT" "$USAGE" "$USED" "$TOTAL"
 
    if [[ "$USAGE" =~ ^[0-9]+$ ]]; then
      if [ "$USAGE" -ge "$DISK_CRIT_THRESHOLD" ]; then
        log_error "CRÍTICO: $MOUNT al ${USAGE}%"
      elif [ "$USAGE" -ge "$DISK_WARN_THRESHOLD" ]; then
        log_warn "Disco $MOUNT al ${USAGE}%"
      fi
    fi
  done
 
  # Top 5 directorios más grandes en /var (donde suelen crecer logs)
  echo "  Top 5 más grandes en /var:"
  du -sh /var/* 2>/dev/null | sort -rh | head -5 | awk '{printf "    %s\t%s\n", $1, $2}' || echo "    N/A"
}
 
# ── Función: Red y puertos ─────────────────────────────────────────────
check_network() {
  log_section "RED"
 
  # Interfaces de red
  echo "  Interfaces activas:"
  if command -v ip >/dev/null; then
    ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{printf "    %s\t%s\n", $7, $2}'
  else
    echo "    Comando 'ip' no encontrado."
  fi
 
  # Puertos en escucha
  echo "  Puertos en escucha:"
  if command -v ss >/dev/null; then
    ss -tlnp 2>/dev/null | grep LISTEN | awk '{printf "    %-25s %s\n", $4, $6}' | head -15 || true
  else
    echo "    Comando 'ss' no encontrado."
  fi
 
  # Verificar conectividad a internet
  echo -n "  Conectividad a internet: "
  if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
  else
    echo -e "${RED}SIN CONEXIÓN${NC}"
  fi
}
 
# ── Función: Estado de servicios ───────────────────────────────────────
check_services() {
  log_section "SERVICIOS SYSTEMD"
 
  # Lista de servicios a verificar (puedes agregar los tuyos)
  local SERVICES=("nginx" "postgresql" "docker" "ssh")
 
  for SERVICE in "${SERVICES[@]}"; do
    if systemctl is-enabled "$SERVICE" > /dev/null 2>&1; then
      if systemctl is-active --quiet "$SERVICE"; then
        echo -e "  ${GREEN}✓${NC} $SERVICE: ACTIVO"
      else
        echo -e "  ${RED}✗${NC} $SERVICE: DETENIDO"
        log_warn "Servicio detenido: $SERVICE"
      fi
    fi
  done
 
  # Servicios que fallaron recientemente
  local FAILED
  if command -v systemctl >/dev/null; then
    FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l || echo "0")
    if [ "$FAILED" -gt 0 ] 2>/dev/null; then
      log_warn "Hay $FAILED servicios en estado FAILED:"
      systemctl --failed --no-legend 2>/dev/null || true
    fi
  else
    echo "  systemctl no disponible."
  fi
}
 
# ── Función principal de reporte ───────────────────────────────────────
generate_report() {
  local TIMESTAMP
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  local REPORT_FILE="$REPORT_DIR/health-${TIMESTAMP}.txt"
 
  {
    echo "=============================================="
    echo "   REPORTE DE SALUD DEL SERVIDOR"
    echo "   $(date)"
    echo "=============================================="
 
    check_system_info
    check_cpu
    check_memory
    check_disk
    check_network
    check_services
 
    echo ""
    echo "  Reporte guardado en: $REPORT_FILE"
  } | tee "$REPORT_FILE"
}
 
# ── Ejecución ──────────────────────────────────────────────────────────
if [ "$WATCH_MODE" = true ]; then
  log_info "Modo watch activado. Corriendo cada ${WATCH_INTERVAL} segundos. Ctrl+C para salir."
  while true; do
    clear
    generate_report
    sleep "$WATCH_INTERVAL"
  done
else
  generate_report
fi
