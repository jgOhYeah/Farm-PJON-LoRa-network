#!/bin/bash
#JWT_TOKEN_JSON=$(curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"username":"koyugaDev+FarmTenant@gmail.com", "password":"4@rmT3n@n+"}' 'http://localhost:8080/api/auth/login')
#JWT_TOKEN=$(echo "$JWT_TOKEN_JSON" | python3 -c 'import json,sys;obj=json.load(sys.stdin);print(obj["token"])')
#echo "JWT_TOKEN: $JWT_TOKEN"

#curl -v -X GET "http://localhost:8080/api/plugins/telemetry/DEVICE/1f5d1380-6f5c-11eb-b82e-f98a99a9c193" \
#--header "Content-Type:application/json" \
#--header "X-Authorization: $JWT_TOKEN"


# Dodgy but should work temporarily
sudo su postgres -c 'pg_dump thingsboard | xz -c > /home/pi/Backups/database.sql.xz'

# rclone sync -v /home/pi/LoRaData drive:Thingsboard

