#!/usr/bin/env bash

echo ">> Load sample sales data."

# Verify Elasticsearch is running
COUNT_HTTP=$(curl -sL -w "%{http_code}" 127.0.0.1:9200 -o /dev/null | grep 000  | wc -l)
COUNT_HTTPS=$(curl -sL -w "%{http_code}" https://127.0.0.1:9200 -k -o /dev/null | grep 000  | wc -l)

if [ "$COUNT_HTTP" -eq "0" -o "$COUNT_HTTPS" -eq "0" ]; then
    if [ "$COUNT_HTTP" -eq "0" ] ; then
        # X-Pack security is not enabled
        HOST="127.0.0.1:9200"
        USER=""
    else
        # X-Pack security is enabled
        HOST="https://127.0.0.1:9200"
        USER="-u elastic:changeme -k"
    fi

    curl -XPOST -s $HOST/_bulk --data-binary "@$SCRIPTS/util/sales_data.bulk" $USER > /dev/null
else
	echo "Elasticsearch is not running. Abort loading sales data..."
fi
