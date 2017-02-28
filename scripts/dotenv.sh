#!/usr/bin/env bash
# Installs the appropriate .env file based on the APP_URL.

. /opt/elasticbeanstalk/support/envvars

if [ -z "$APP_URL" ]
then
    echo "Please set the global variable APP_URL"
else
    source="env/.env.$APP_URL"
    if [ -f "$source" ]
    then
        destination=".env"
        echo "Copying $source to $destination"
        cp "$source" "$destination"
    else
        echo "Couldn't find appropriate env file: $source"
        exit 1
    fi
fi