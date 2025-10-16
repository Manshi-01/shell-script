#!/bin/bash
## Simple monitoring : logs CPU , memory , disk, nginx status

LOG_FILE="/var/log/server_health.log"
THRESHOLD_CPU=75 # % (1-min avaerage) threshold for alerting
THRESHOLD_MEM=80 # % used threshold
THRESHOLD_DISK=85 # % used threshold on /
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

#gather metrics
CPU_LOAD=$(awk -F' ' '{print $1*100} ' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
# alternatively:use top or mpstat for per-core normalized, but keep simple
MEM_USED_PERCENT=$(free -m | awk 'NR==2{printf("%.0f", $3*100/$2)}')
DISK_USED_PERCENT=$(df / | awk 'END{print $5}' | tr -d '%')


NGINX_STATUS=$(systemctl is-active nginx)

{
  echo "===== $DATE - $HOSTNAME ====="
  echo "NGINX status: $NGINX_STATUS"
  echo "CPU Load (1-min or approx): $CPU_LOAD"
  echo "Memory used (%): $MEM_USED_PERCENT"
  echo "Disk used on / (%): $DISK_USED_PERCENT"
  echo "------- top 5 processes by cpu -------"
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
  echo "======================================"
} >> $LOG_FILE

# Basic alerting: write to /var/log/server_alerts.log if thresholds exceeded
ALERT_FILE="/var/log/server_alerts.log"
# Ensure the alert log file exists
sudo touch $ALERT_FILE
sudo chmod 644 $ALERT_FILE

if [ "${CPU_LOAD%%.*}" -ge "$THRESHOLD_CPU" ] || [ "$MEM_USED_PERCENT" -ge "$THRESHOLD_MEM" ] || [ "$DISK_USED_PERCENT" -ge "$THRESHOLD_DISK" ] || [ "$NGINX_STATUS" != "active" ]; then
  echo "[$DATE] ALERT: resource threshold hit on $HOSTNAME - CPU:$CPU_LOAD MEM:$MEM_USED_PERCENT DISK:$DISK_USED_PERCENT NGINX:$NGINX_STATUS" >> $ALERT_FILE
  # Example: send a simple local email (requires mailutils) or push to a webhook
  # echo "Server ALERT: $HOSTNAME CPU:$CPU_LOAD MEM:$MEM_USED_PERCENT DISK:$DISK_USED_PERCENT NGINX:$NGINX_STATUS" | mail -s "Server Alert: $HOSTNAME" you@example.com
fi

