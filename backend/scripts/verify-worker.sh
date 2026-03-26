#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://ai.gravitilabs.com}"
EMAIL="${TAI_VERIFY_EMAIL:-admin@tai.local}"
PASSWORD="${TAI_VERIFY_PASSWORD:-ChangeMe123!}"
COOKIE_JAR="$(mktemp)"
trap 'rm -f "$COOKIE_JAR"' EXIT

echo "== /api/health =="
curl -sS "$BASE_URL/api/health" | jq .

echo "== /api/auth/signin =="
curl -sS -c "$COOKIE_JAR" -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  "$BASE_URL/api/auth/signin" | jq .

echo "== /api/bootstrap =="
curl -sS -b "$COOKIE_JAR" "$BASE_URL/api/bootstrap" | jq '{user:.user.email, modelCount:(.models|length), chatCount:(.chats|length)}'

echo "== /api/models =="
MODELS_JSON="$(curl -sS -b "$COOKIE_JAR" "$BASE_URL/api/models")"
echo "$MODELS_JSON" | jq '{count:(.models|length), sample:(.models[:5] | map(.displayName))}'
MODEL_ID="$(echo "$MODELS_JSON" | jq -r '.models[0].id')"

echo "== /api/chats =="
curl -sS -b "$COOKIE_JAR" "$BASE_URL/api/chats" | jq '{count:(.chats|length), sample:(.chats[:3] | map(.title))}'

CHAT_ID="$(curl -sS -b "$COOKIE_JAR" -H "Content-Type: application/json" \
  -d "{\"title\":\"Worker Verify\",\"modelId\":\"$MODEL_ID\"}" \
  "$BASE_URL/api/chats" | jq -r '.chat.id')"

echo "== /api/chat/stream =="
curl -N -sS -b "$COOKIE_JAR" -H "Content-Type: application/json" \
  -d "{\"chatId\":\"$CHAT_ID\",\"model\":\"$MODEL_ID\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly: TAI\"}]}" \
  "$BASE_URL/api/chat/stream"
echo
