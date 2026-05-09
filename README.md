# DevOps Monitoring Scripts 🖥️
 
A production-grade Bash toolkit for Linux server health monitoring.
Built as part of my DevOps/Cloud learning journey.
 
## Features
 
- **CPU monitoring**: usage percentage and top 5 processes
- **Memory monitoring**: RAM usage with configurable thresholds
- **Disk monitoring**: usage per partition with warnings at 80% and critical at 90%
- **Network monitoring**: active interfaces, listening ports, connectivity check
- **Service monitoring**: status of key systemd services
- **Watch mode**: continuous monitoring with configurable intervals
- **Report generation**: timestamped reports saved to disk
 
## Usage
 
```bash
# Single health report
./server-health.sh
 
# Watch mode (refresh every 60 seconds)
./server-health.sh --watch
 
# Custom interval and output directory
./server-health.sh --watch --interval 30 --output /var/log/monitoring
```
 
## Technologies Used
 
- Bash scripting (set -euo pipefail, trap, functions, arrays)
- Linux system commands (ps, ss, df, du, ip, systemctl)
- Text processing (awk, grep, sed)
 
## What I Learned
 
This project covers Phase 1 of my DevOps roadmap:
- Linux permissions, processes, and filesystem management
- Bash scripting best practices (error handling, modular design)
- Network diagnostics and port management
- Production-grade script design patterns
 
## Running Tests
 
```bash
chmod +x tests/test-health.sh
./tests/test-health.sh
```
 
## Author
 
Kamila Opazo — Cloud/DevOps Engineer in training
GitHub: [kamila2021](https://github.com/kamila2021)
