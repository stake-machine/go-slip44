#!/usr/bin/env bash

OUTPUT=cointypes.go

# Track seen constant names to ensure uniqueness
declare -A SEEN_CONST

cat >${OUTPUT} <<EOSTART
// Copyright © 2019 Weald Technology Trading
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package slip44

const (
EOSTART

# Process SLIP-0044 data using awk for efficiency
while IFS='|' read -r ID SYMBOL COIN; do
  CONST_NAME="${COIN}"
  
  # If this constant name is already used, try adding the symbol
  if [[ -n "${SEEN_CONST[$CONST_NAME]}" ]]; then
    if [[ -n "$SYMBOL" ]]; then
      CONST_NAME="${COIN}_${SYMBOL}"
    fi
  fi
  
  # If still duplicate, add the ID to make it unique
  if [[ -n "${SEEN_CONST[$CONST_NAME]}" ]]; then
    CONST_NAME="${COIN}_${ID}"
  fi
  
  # Mark this constant name as used
  SEEN_CONST[$CONST_NAME]=1
  
  echo "${CONST_NAME} = uint32(${ID})" >>${OUTPUT}
done < <(wget -q -O - https://raw.githubusercontent.com/satoshilabs/slips/master/slip-0044.md | \
awk -F'|' '/^\| *[0-9]+ *\|/ {
  # Extract and trim fields
  id = $2; gsub(/[^0-9]/, "", id)
  symbol = $4; gsub(/^ +| +$/, "", symbol); gsub(/[^A-Za-z0-9]/, "", symbol); symbol = toupper(symbol)
  coin = $5; gsub(/^ +| +$/, "", coin); gsub(/\].*/, "", coin); gsub(/^\[/, "", coin); gsub(/[ -]/, "_", coin); coin = toupper(coin)
  # Skip if coin has invalid characters
  if (coin !~ /^[0-9A-Z_]+$/) next
  # Skip if coin does not start with A-Z
  if (coin !~ /^[A-Z]/) next
  print id "|" symbol "|" coin
}')

cat >>${OUTPUT} <<EOEND
)
EOEND

gofmt -w ${OUTPUT}
