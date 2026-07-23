#!/bin/bash

# Cloudflare API credentials
API_EMAIL=$CLOUDFLARE_API_EMAIL
API_KEY=$CLOUDFLARE_API_KEY

# Cloudflare zone and record details
ZONE_ID=$CLOUDFLARE_ZONE_ID
RECORD_NAME=$CLOUDFLARE_DEV_DNS_RECORD_NAME

# Get current public IP address
IP=$(curl -s https://api.ipify.org)

# Get the value of the A record
get_record_value() {
    local record_id="$1"

    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id" \
        -H "Content-Type: application/json" \
        -H "X-Auth-Email: $API_EMAIL" \
        -H "X-Auth-Key: $API_KEY")

    value=$(echo "$response" | grep -oP '(?<="content":")[^"]*')
    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "Record value not found."
        echo "Response: $response"
    fi
}

# Update A record with Cloudflare API
update_record() {
    local record_id="$1"
    local ip_address="$2"

    response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id" \
        -H "Content-Type: application/json" \
        -H "X-Auth-Email: $API_EMAIL" \
        -H "X-Auth-Key: $API_KEY" \
        --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$ip_address\"}")

    # Check the response for success
    success=$(echo "$response" | grep -o '"success":true')
    if [ -n "$success" ]; then
        echo "A record updated successfully with IP: $ip_address"
    else
        echo "Failed to update A record."
        echo "Response: $response"
    fi
}

# Get old A record
record_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME" \
    -H "Content-Type: application/json" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY")

record_id=$(echo "$record_response" | grep -oP '(?<="id":")[^"]*')
if [ -n "$record_id" ]; then
    old_ip=$(get_record_value "$record_id")
    if [ "$IP" != "$old_ip" ]; then
        echo "IP changed. Updating now..."
	update_record "$record_id" "$IP"
    else
        echo "No update needed. IP remains unchanged at $IP"
    fi
else
    echo "A record not found."
    echo "Response: $record_response"
fi
