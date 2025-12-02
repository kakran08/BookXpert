#!/bin/bash
set -e

echo " Starting Elasticsearch + Init container"
sudo chown -R 1000:1000 ./esdata
docker compose up -d

echo ""
echo " Waiting for Elasticsearch to become healthy"
while true; do
    STATUS=$(docker inspect --format='{{json .State.Health.Status}}' elasticsearch 2>/dev/null | tr -d '"')

    if [ "$STATUS" = "healthy" ]; then
        echo "Elasticsearch is healthy!"
        break
    fi

    echo "Status: $STATUS (waiting 3s...)"
    sleep 3
done

echo ""
echo " Running index initialization (init-es.sh)"
docker logs es-init --follow &

# Wait until init container finishes
while docker ps -a --format '{{.Names}}' | grep -q "es-init"; do
    if [ "$(docker inspect -f '{{.State.Running}}' es-init)" = "false" ]; then
        break
    fi
    sleep 2
done

chmod +x bulk-insert.sh
chmod +x search.sh

echo ""
echo "Performing Bulk Insert of Names"
./bulk-insert.sh

echo ""
echo "SETUP COMPLETE!"
echo "You can now run: ./search.sh \"<query>\""
echo "Example: ./search.sh \"Katherin\""
