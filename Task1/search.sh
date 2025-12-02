#!/bin/sh
# Usage: ./search.sh "Katherin"

ES_URL="http://localhost:9200"
INDEX="names_index"

if [ -z "$1" ]; then
  echo "Usage: $0 \"<name_to_search>\""
  exit 1
fi

SEARCH_TERM="$1"

echo "Searching for: $SEARCH_TERM"
echo ""

curl -s -X POST "$ES_URL/$INDEX/_search" \
  -H "Content-Type: application/json" \
  -d "{
    \"size\": 10,
    \"query\": {
      \"multi_match\": {
        \"query\": \"$SEARCH_TERM\",
        \"fields\": [
          \"name^1\",
          \"name.ngrams^3\",
          \"name.phonetic^4\"
        ],
        \"fuzziness\": \"AUTO\",
        \"operator\": \"or\"
      }
    }
  }" | jq .
