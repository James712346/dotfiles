#!/bin/bash

# Cloudflare info
ZONE="jamesprince.me"
RECORD="laptop-local"
TOKEN="UJDxidseDnU8gNWPgtG9EUcVISLg_V2WWUrVHmfb"

STATE_FILE="/tmp/.last_ip"
IP=$(ip route get 1 | awk '{print $7; exit}')  # Detect local IP

# Exit if IP hasn't changed
if [[ -f "$STATE_FILE" ]] && [[ "$(cat $STATE_FILE)" == "$IP" ]]; then
    exit 0
fi

# Save current IP
echo "$IP" > "$STATE_FILE"
# Get DNS record ID
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

DNS_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$RECORD_ID/dns_records?name=$RECORD.$ZONE" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

# Update DNS
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$RECORD_ID/dns_records/$DNS_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$RECORD\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":false}")

echo $RESPONSE

