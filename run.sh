#!/usr/bin/with-contenv bashio
set +u

CONFIG_PATH=/data/options.json

time=$(bashio::config 'update')
ip1=$(curl -s -X GET "https://api4.my-ip.io/ip.txt")

bashio::log.info "Your IP: $ip1"

for i in $(bashio::config 'zones|keys'); do
    api_key=$(bashio::config "zones[$i].api_key")
    for j in $(bashio::config "zones[$i].dns_records|keys"); do
        if answer=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$(bashio::config "zones[$i].zone_id")/dns_records/$(bashio::config "zones[$i].dns_records[$j]")" \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            -d '{"content": "'$ip1'"}') &&
            [ $(echo $answer | jq -r '.success') == 'true' ]; then
            bashio::log.info "Updated DNS record id \"$(bashio::config "zones[$i].dns_records[$j]")\"."
        else
            bashio::log.error "Failed updating DNS record id \"$(bashio::config "zones[$i].dns_records[$j]")\". $(echo $answer | jq -r '.errors | .[0]')"
        fi
    done
done

sleep "$time"

while true; do
    if ip2=$(curl -s -X GET "https://api4.my-ip.io/ip.txt") &&
        [ $ip1 != $ip2 ]; then
        bashio::log.info "New IP: $ip2"
        api_key=$(bashio::config "zones[$i].api_key")
        for j in $(bashio::config "zones[$i].dns_records|keys"); do
            if answer=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$(bashio::config "zones[$i].zone_id")/dns_records/$(bashio::config "zones[$i].dns_records[$j]")" \
                -H "Authorization: Bearer $api_key" \
                -H "Content-Type: application/json" \
                -d '{"content": "'$ip1'"}') &&
                [ $(echo $answer | jq -r '.success') == 'true' ]; then
                bashio::log.info "Updated DNS record id \"$(bashio::config "zones[$i].dns_records[$j]")\"."
            else
                bashio::log.error "Failed updating DNS record id \"$(bashio::config "zones[$i].dns_records[$j]")\". $(echo $answer | jq -r '.errors | .[0]')"
            fi
        done
    fi
    sleep "$time"
done
