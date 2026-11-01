#!/bin/bash
LOG_FILE="access.log"
> "$LOG_FILE"
LINE_COUNT=$((300 + RANDOM % 201))

METHODS=("GET" "POST" "PUT" "PATCH" "DELETE")
URLS=("/api/users" "/api/login" "/api/products" "/api/orders" "/api/health")
STATUSES=(200 203 204 301 400 401 404 403 500 502 503)
IPS=("192.168.1.10" "192.168.1.10" "192.168.1.10" "10.0.0.5" "10.0.0.5" "172.16.0.3" "172.16.0.8" "10.0.0.12" "192.168.1.25")

for i in $(seq 1 "$LINE_COUNT"); do
    
    TIME=$(date "+%d/%b/%Y:%H:%M:%S")
    METHOD=${METHODS[$((RANDOM % ${#METHODS[@]}))]}
    URL=${URLS[$((RANDOM % ${#URLS[@]}))]}
    STATUS=${STATUSES[$((RANDOM % ${#STATUSES[@]}))]}
    IP=${IPS[$((RANDOM % ${#IPS[@]}))]}
    echo "$IP - - [$TIME] \"$METHOD $URL HTTP/1.1\" $STATUS" >> "$LOG_FILE"
done

COUNT=$(wc -l < "$LOG_FILE")
echo "1.Общее количество запросов: $COUNT"
MOST_REQUESTS=$(grep -oE '^([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n 3)
echo "2. Топ-3 IP-адреса с наибольшим числом запросов:"
echo "$MOST_REQUESTS"
ERROR_4XX=$(awk '$NF ~ /^4/ {count++} END {print count+0}' "$LOG_FILE")
ERROR_5XX=$(awk '$NF ~ /^5/ {count++} END {print count+0}' "$LOG_FILE")
echo "3. Количество запросов с кодами 4xx и 5xx: $((ERROR_4XX + ERROR_5XX))"
echo "где запросов с кодами 4xx: $ERROR_4XX"
echo "где запросов с кодами 5xx: $ERROR_5XX"
