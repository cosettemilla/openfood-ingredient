#!/bin/bash

usage() {
  echo "Usage: $0 -i \"<ingredient>\" -d /path/to/folder"
  echo " -i ingredient to search (case-insensitive)"
  echo " -d folder containing products.csv (tab-separated)"
  echo " -h show help"
  exit 1
}

while getopts ":i:d:h" opt; do
  case ${opt} in
    i ) INGREDIENT=$OPTARG ;;
    d ) DATA_DIR=$OPTARG ;;
    h ) usage ;;
    \? ) usage ;;
  esac
done

if [ -z "$INGREDIENT" ] || [ -z "$DATA_DIR" ]; then
  usage
fi

CSV="$DATA_DIR/products.csv"

if [ ! -s "$CSV" ]; then
  echo "ERROR: $CSV not found or empty."
  exit 1
fi

if ! command -v csvcut >/dev/null; then
  echo "ERROR: csvcut not found. Please install csvkit<1.0.5."
  exit 1
fi

tmp_matches="$(mktemp)"

# Column numbers: 43 = ingredients_text, 11 = product_name, 1 = code
csvcut -t -c 43,11,1 "$CSV" \
| csvgrep -c 1 -r "(?i)${INGREDIENT}" \
| csvcut -c 2,3 \
| csvformat -T \
| tail -n +2 \
| tee "$tmp_matches"

count=$(wc -l < "$tmp_matches")
echo "----"
echo "Found $count product(s) containing: \"$INGREDIENT\""

rm "$tmp_matches"
