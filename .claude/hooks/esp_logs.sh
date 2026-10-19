#!/usr/bin/env bash
# Called by session_start.sh: ESP log summary (24h) from both Loki servers + ESPHome version.
# Informational only; must never fail the session start (every query is guarded).

LOKI_NIE="${LOKI_NIE:-http://logs.lan:3100}"
LOKI_NAM="${LOKI_NAM:-http://logs.nam:3100}"
WINDOW="24h"
TOP_N=3
# RF gateway noise (OpenMQTTGateway 433 MHz decodes) is not device health
SEL='job="mqtt_logger", mqtt_topic!~".+/RTL_433toMQTT"'

loki_query() { # <base_url> <logql>
  curl -sfG -m 5 "$1/loki/api/v1/query" --data-urlencode "query=$2" 2>/dev/null
}

loki_lines() { # <base_url> <logql> -> raw log lines, newest first
  curl -sfG -m 8 "$1/loki/api/v1/query_range" --data-urlencode "query=$2" \
    --data-urlencode "since=$WINDOW" --data-urlencode "limit=1000" 2>/dev/null |
    jq -r '.data.result[]?.values[]?[1]' 2>/dev/null
}

site_report() { # <label> <url>
  local label="$1" url="$2" counts nodes24 nodes7d
  if ! counts=$(loki_query "$url" "sum by (mqtt_node, level) (count_over_time({$SEL}[$WINDOW]))") ||
     ! echo "$counts" | jq -e '.data.result' >/dev/null 2>&1; then
    echo "- $label: unreachable ($url)"
    return 0
  fi
  local rows
  rows=$(echo "$counts" | jq -r '.data.result[] | select(.metric.level == "error" or .metric.level == "warning") | "\(.metric.mqtt_node)\t\(.metric.level)\t\(.value[1])"' | sort)
  if [ -z "$rows" ]; then
    echo "- $label: no error/warning lines in $WINDOW"
  else
    echo "- $label (error/warning, $WINDOW):"
    echo "$rows" | awk -F'\t' '{printf "  - %s %s=%s\n", $1, $2, $3}'
    # top distinct messages per level, ANSI stripped and digits normalised
    for lvl in error warning; do
      loki_lines "$url" "{$SEL, level=\"$lvl\"}" |
        sed -E 's/\x1b\[[0-9;]*m//g; s/[0-9]+/N/g' | sort | uniq -c | sort -rn | head -n "$TOP_N" |
        sed -E "s/^ *([0-9]+) /  - top $lvl: \1× /" | cut -c1-160
    done
  fi
  # nodes seen in 7d but absent in 24h (cheap "went quiet" hint)
  nodes24=$(echo "$counts" | jq -r '.data.result[].metric.mqtt_node' | sort -u)
  nodes7d=$(loki_query "$url" "sum by (mqtt_node) (count_over_time({$SEL}[7d]))" |
    jq -r '.data.result[]?.metric.mqtt_node' 2>/dev/null | grep -E '^esp' | sort -u || true)
  local quiet
  quiet=$(comm -13 <(echo "$nodes24") <(echo "$nodes7d") | tr '\n' ' ')
  [ -n "${quiet// /}" ] && echo "  - quiet in $WINDOW (seen in 7d): $quiet"
  return 0
}

echo "## ESP logs ($WINDOW, both sites)"
if ! command -v jq >/dev/null 2>&1; then
  echo "_(jq not installed — skipped)_"
else
  site_report nie "$LOKI_NIE" || true
  site_report nam "$LOKI_NAM" || true
fi
echo

echo "## ESPHome version"
if [ -x ./check_esphome_version.sh ]; then
  ver=$(./check_esphome_version.sh --check-only 2>&1 || true)
  inst=$(echo "$ver" | sed -nE 's/^Installed ESPHome version: *([0-9.]+).*/\1/p' | head -1)
  latest=$(echo "$ver" | sed -nE 's/^Latest ESPHome version: *([0-9.]+).*/\1/p' | head -1)
  if [ -z "$inst" ] || [ -z "$latest" ]; then
    echo "_(version check failed)_"
  elif [ "$inst" = "$latest" ]; then
    echo "- ESPHome $inst — up to date"
  else
    # YYYY.M = release line; third number = patch. Different YYYY.M => new full release.
    if [ "${inst%.*}" = "${latest%.*}" ]; then kind="patch of the current release (${inst%.*})"; else kind="NEW full release (${inst%.*} -> ${latest%.*})"; fi
    echo "- ESPHome $inst installed, $latest available — $kind"
    echo "  (info only: Pawelo decides on upgrade; no release-notes research unless asked)"
  fi
else
  echo "_(check_esphome_version.sh not found)_"
fi
echo
