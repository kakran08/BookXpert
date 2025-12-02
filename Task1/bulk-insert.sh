#!/bin/bash

INDEX="names_index"

echo "Generating bulk payload..."
> bulk_payload.json

while IFS= read -r name; do
  echo '{"index":{"_index":"'"$INDEX"'"}}' >> bulk_payload.json
  echo '{"name":"'"$name"'"}' >> bulk_payload.json
done < <(jq -r '.[]' names.json)

echo "Sending bulk insert request..."
curl -X POST "localhost:9200/_bulk" \
  -H "Content-Type: application/json" \
  --data-binary @bulk_payload.json

echo -e "\nDone!"
