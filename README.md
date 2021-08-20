# DDNS

This add-on provides a script that updates all A records of a Cloudflare zone with your latest public ip address.
_**Note:** .ml, .tk, .cf, .ga and .gq domains aren't supported by Cloudflare's API_

## Installation

Go to the add-on store of the supervisor and click on _repositories_ under the three dots.
Copy [_https://github.com/sibest19/addon-ddns_](https://github.com/sibest19/addon-ddns) into the field and add this repository.
Now you can install this add-on like any other home-assistant add-on.

## Configuration

1. Create an API token at [Cloudflare](https://dash.cloudflare.com/profile/api-tokens) and give it Zone.DNS permissions.
1. Copy your zone id from your dashboard.
2. To obtain your `dns_records` id run this in your shell and chose the ids of the records you want to update
  ```sh
  curl -X GET "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type:application/json"
  ```
4. Enter these details in the configuration page of this add-on and start it. Watch the log for errors.
  ```yml
  zones:
    - api_key: xxxxxxxxxxxx
      zone_id: 123abc
      dns_records:
        - 456def
        - 789ghi
  update: 300
  ```

> Cloudflare, the Cloudflare logo, and Cloudflare Workers are trademarks and/or registered trademarks of Cloudflare, Inc. in the United States and other jurisdictions.
