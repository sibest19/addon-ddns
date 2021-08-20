#!/usr/bin/with-contenv bashio
set +u

CONFIG_PATH=/data/options.json

time=$(bashio::config 'update')
ip1=$(curl -s -X GET "https://api4.my-ip.io/ip.txt")

bashio::log.info "Your IP: $ip1"

for i in $(bashio::config 'zones|keys'); do
    api_key=$(bashio::config "zones[$i].api_key")
    if answer=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$(bashio::config "zones[$i].zone_id")/dns_records/$(bashio::config "zones[$i].dns_record_id")?type=A&match=all" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json") &&
        [ $(echo $answer | jq -r '.success') == 'true' ]; then
        domains=$(echo $answer | jq -r '.result')
    else
        bashio::log.error "Failed getting records $(echo $answer | jq -r '.errors')"
    fi
    for i in $(echo $domains | jq -r '.[] | @base64'); do
        if answer=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$(echo $i | base64 -d | jq -r '.zone_id')/dns_records/$(echo $i | base64 -d | jq -r '.id')" \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            -d '{"content": "'$ip1'", "name": "'$(echo $i | base64 -d | jq -r '.name')'", "type": "A", "ttl": 1, "proxied": true}') &&
            [ $(echo $answer | jq -r '.success') == 'true' ]; then
            bashio::log.info "Updated $(echo $i | base64 -d | jq -r '.name')"
        else
            bashio::log.error "Failed updating $(echo $i | base64 -d | jq -r '.name') $(echo $answer | jq -r '.errors | .[0]')"
        fi
    done
done
sleep "$time"

while true; do
    if ip2=$(curl -s -X GET "https://api4.my-ip.io/ip.txt") &&
        [ $ip1 != $ip2 ]; then
        bashio::log.info "New IP: $ip2"
        for i in $(bashio::config "zones[$i].zone_id"); do
            api_key=$(bashio::config "zones[$i].api_key")
            if answer=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$(bashio::config "zones[$i].zone_id")/dns_records/$(bashio::config "zones[$i].dns_record_id")?type=A&match=all" \
                -H "Authorization: Bearer $api_key" \
                -H "Content-Type: application/json") &&
                [ $(echo $answer | jq -r '.success') == 'true' ]; then
                domains=$(echo $answer | jq -r '.result')
            else
                bashio::log.error "Failed getting records $(echo $answer | jq -r '.errors')"
            fi
            for i in $(echo $domains | jq -r '.[] | @base64'); do
                if answer=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$(echo $i | base64 -d | jq -r '.zone_id')/dns_records/$(echo $i | base64 -d | jq -r '.id')" \
                    -H "Authorization: Bearer $api_key" \
                    -H "Content-Type: application/json" \
                    -d '{"content": "'$ip2'", "name": "'$(echo $i | base64 -d | jq -r '.name')'", "type": "A", "ttl": 1, "proxied": true}') &&
                    [ $(echo $answer | jq -r '.success') == 'true' ]; then
                    bashio::log.info "Updated $(echo $i | base64 -d | jq -r '.name')"
                else
                    bashio::log.error "Failed updating $(echo $i | base64 -d | jq -r '.name') $(echo $answer | jq -r '.errors | .[0]')"
                fi
            done
            ip1="$ip2"
        done
    fi
    sleep "$time"
done
