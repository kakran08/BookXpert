#!/bin/sh

echo "Waiting for Elasticsearch to be ready..."

until curl -s http://elasticsearch:9200 >/dev/null; do
  sleep 2
done

echo "Elasticsearch is up. Creating index..."

curl -X PUT "http://elasticsearch:9200/names_index" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "analysis": {
      "analyzer": {
        "name_search_analyzer": {
          "tokenizer": "standard",
          "filter": ["lowercase", "asciifolding", "3_gram_filter"]
        },
        "name_phonetic_analyzer": {
          "tokenizer": "standard",
          "filter": ["lowercase", "asciifolding", "double_metaphone"]
        }
      },
      "filter": {
        "3_gram_filter": {
          "type": "edge_ngram",
          "min_gram": 3,
          "max_gram": 15
        },
        "double_metaphone": {
          "type": "phonetic",
          "encoder": "double_metaphone",
          "replace": false
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "name": {
        "type": "text",
        "fields": {
          "raw": { "type": "keyword" },
          "ngrams": { "type": "text", "analyzer": "name_search_analyzer" },
          "phonetic": { "type": "text", "analyzer": "name_phonetic_analyzer" }
        }
      }
    }
  }
}'
echo ""
echo "Index created successfully!"
