#!/bin/bash
# utils/colors.sh — Colores para output en terminal
 
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
NC="\033[0m" # No Color (reset)
 
# Funciones de logging con colores
log_info()    { echo -e "${GREEN}[INFO]${NC}  $(date +"%H:%M:%S") $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $(date +"%H:%M:%S") $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $(date +"%H:%M:%S") $1" >&2; }
log_section() { echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}"; }
