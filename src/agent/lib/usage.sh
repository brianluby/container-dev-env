#!/usr/bin/env bash
# usage.sh — Token usage aggregation and cost estimation
# Version: 1.0.0
# Dependencies: jq

set -euo pipefail

# Model pricing (per 1M tokens, USD) — approximate as of 2026
declare -A MODEL_INPUT_PRICING=(
  ["claude-sonnet-4-20250514"]=3.00
  ["claude-opus-4-5-20251101"]=15.00
  ["gpt-4o"]=2.50
  ["gpt-4o-mini"]=0.15
  ["gemini-2.0-flash"]=0.10
)

declare -A MODEL_OUTPUT_PRICING=(
  ["claude-sonnet-4-20250514"]=15.00
  ["claude-opus-4-5-20251101"]=75.00
  ["gpt-4o"]=10.00
  ["gpt-4o-mini"]=0.60
  ["gemini-2.0-flash"]=0.40
)

# compute_cost <model> <input_tokens> <output_tokens>
# Computes estimated cost in USD
compute_cost() {
  local model="$1"
  local input_tokens="$2"
  local output_tokens="$3"

  local input_price="${MODEL_INPUT_PRICING[${model}]:-5.00}"
  local output_price="${MODEL_OUTPUT_PRICING[${model}]:-15.00}"

  # Cost = (tokens / 1_000_000) * price_per_million
  local cost
  cost=$(echo "scale=4; (${input_tokens} * ${input_price} / 1000000) + (${output_tokens} * ${output_price} / 1000000)" | bc 2>/dev/null || echo "0.0000")

  echo "${cost}"
}

# update_session_usage <session_id> <input_tokens> <output_tokens> <model> <provider>
# Updates the token usage in session metadata
update_session_usage() {
  local session_id="$1"
  local input_tokens="$2"
  local output_tokens="$3"
  local model="${4:-unknown}"
  local provider="${5:-unknown}"

  local state_dir="${AGENT_STATE_DIR:-${HOME}/.local/share/agent}"
  local session_path="${state_dir}/sessions/${session_id}.json"

  if [[ ! -f "${session_path}" ]]; then
    echo "Error: Session '${session_id}' not found" >&2
    return 1
  fi

  local total_tokens=$((input_tokens + output_tokens))
  local cost
  cost=$(compute_cost "${model}" "${input_tokens}" "${output_tokens}")

  local tmp="${session_path}.tmp"
  jq --argjson input "${input_tokens}" \
     --argjson output "${output_tokens}" \
     --argjson total "${total_tokens}" \
     --arg cost "${cost}" \
     --arg model "${model}" \
     --arg provider "${provider}" \
     '.token_usage.input_tokens += $input |
      .token_usage.output_tokens += $output |
      .token_usage.total_tokens += $total |
      .token_usage.estimated_cost_usd = (.token_usage.estimated_cost_usd + ($cost | tonumber)) |
      .token_usage.model = $model |
      .token_usage.provider = $provider' \
     "${session_path}" > "${tmp}"
  mv "${tmp}" "${session_path}"
}

# get_session_usage <session_id> [format]
# Returns usage metrics for a session
get_session_usage() {
  local session_id="$1"
  local format="${2:-text}"
  local state_dir="${AGENT_STATE_DIR:-${HOME}/.local/share/agent}"
  local session_path="${state_dir}/sessions/${session_id}.json"

  if [[ ! -f "${session_path}" ]]; then
    echo "Error: Session '${session_id}' not found" >&2
    return 1
  fi

  local usage
  usage=$(jq '.token_usage' "${session_path}")

  if [[ "${format}" == "json" ]]; then
    echo "${usage}"
  else
    local input output total cost model provider
    input=$(echo "${usage}" | jq -r '.input_tokens')
    output=$(echo "${usage}" | jq -r '.output_tokens')
    total=$(echo "${usage}" | jq -r '.total_tokens')
    cost=$(echo "${usage}" | jq -r '.estimated_cost_usd')
    model=$(echo "${usage}" | jq -r '.model // "—"')
    provider=$(echo "${usage}" | jq -r '.provider // "—"')

    echo "Token Usage:"
    echo "  Input tokens:  ${input}"
    echo "  Output tokens: ${output}"
    echo "  Total tokens:  ${total}"
    echo "  Est. cost:     \$${cost} USD"
    echo "  Model:         ${model}"
    echo "  Provider:      ${provider}"
  fi
}
