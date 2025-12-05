#!/usr/bin/env bash

OUTPUT=cointypes.go

# Track seen constant names to ensure uniqueness
# Uses a temp file instead of associative array for POSIX compatibility
SEEN_FILE=$(mktemp)
trap "rm -f $SEEN_FILE" EXIT

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
    # Start with the coin name as the constant name
    CONST_NAME="${COIN}"
    
    # If this constant name is already used, try adding the symbol
    if grep -qx "${CONST_NAME}" "$SEEN_FILE"; then
      if [[ -n "$SYMBOL" ]]; then
        CONST_NAME="${COIN}_${SYMBOL}"
      fi
    fi
    
    # If still duplicate, add the ID to make it unique
    if grep -qx "${CONST_NAME}" "$SEEN_FILE"; then
      CONST_NAME="${COIN}_${ID}"
    fi
    
    # Mark this constant name as used
    echo "${CONST_NAME}" >> "$SEEN_FILE"
    
    echo "${CONST_NAME} = uint32(${ID})" >>${OUTPUT}
  fi
done < <(wget -q -O - https://raw.githubusercontent.com/satoshilabs/slips/master/slip-0044.md)

cat >>${OUTPUT} <<EOEND
)
EOEND

gofmt -w ${OUTPUT}
