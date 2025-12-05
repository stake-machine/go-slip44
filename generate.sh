#!/bin/bash

OUTPUT=cointypes.go

# Track seen entries to handle duplicates properly
# SEEN_KEY: stores "COIN:SYMBOL" combinations to detect exact duplicates
# SEEN_NAME: stores coin names to detect when we need symbol suffix
declare -A SEEN_KEY
declare -A SEEN_NAME

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

while read line
do
  # Ensure this is a real table row line (starts with | followed by a number)
  # Format: | Coin type | Path component | Symbol | Coin |
  echo "$line" | grep -qE '^\| *[0-9]+ *\|'
  if [[ $? -ne 0 ]]; then
    continue
  fi

  # Fetch the required items (field 2 = ID, field 4 = Symbol, field 5 = Coin name)
  # Fields are: empty | ID | Path | Symbol | Coin | empty
  ID=$(echo "${line}" | awk -F'|' '{print $2}' | sed -e 's/^ *//' -e 's/ *$//')
  SYMBOL=$(echo "${line}" | awk -F'|' '{print $4}' | sed -e 's/^ *//' -e 's/ *$//')
  COIN=$(echo "${line}" | awk -F'|' '{print $5}' | sed -e 's/^ *//' -e 's/ *$//')

  # Tidy up the ID
  ID=$(echo "$ID" | sed -e 's/[^0-9]//g')
  # Tidy up the symbol
  SYMBOL=$(echo "$SYMBOL" | sed -e 's/[^A-Za-z0-9]//g' | tr '[:lower:]' '[:upper:]')
  # Tidy up the coin
  COIN=$(echo "$COIN" | sed -e 's/\].*//' -e 's/^\[//' -e 's/ /_/g' -e 's/-/_/g' | tr '[:lower:]' '[:upper:]')
  # Should only have digits, upper-case letters and _ at this point
  if [[ ! "${COIN}" =~ ^[0-9A-Z_]+$ ]]; then
    continue
  fi

  # Valid variables must start with A-Z...
  if [[ "${COIN}" =~ ^[A-Z] ]]; then
    # Create a unique key combining coin name and symbol
    KEY="${COIN}__${SYMBOL}"
    
    # Skip if we've already seen this exact coin name + symbol combination
    if [[ -n "${SEEN_KEY[$KEY]}" ]]; then
      continue
    fi
    SEEN_KEY[$KEY]=1
    
    # Check if we've already used this coin name (with a different symbol)
    # If so, append the symbol to make the constant name unique
    if [[ -n "${SEEN_NAME[$COIN]}" ]]; then
      # Use coin name with symbol suffix to differentiate
      if [[ -n "$SYMBOL" ]]; then
        CONST_NAME="${COIN}_${SYMBOL}"
      else
        # No symbol, use ID as suffix
        CONST_NAME="${COIN}_${ID}"
      fi
    else
      CONST_NAME="${COIN}"
      SEEN_NAME[$COIN]=1
    fi
    
    echo "${CONST_NAME} = uint32(${ID})" >>${OUTPUT}
  fi
done < <(wget -q -O - https://raw.githubusercontent.com/satoshilabs/slips/master/slip-0044.md)

cat >>${OUTPUT} <<EOEND
)
EOEND

gofmt -w ${OUTPUT}
