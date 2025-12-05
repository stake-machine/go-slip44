#!/bin/bash

OUTPUT=cointypes.go

# Track seen coin names to avoid duplicates
declare -A SEEN_COINS

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

  # Fetch the required items (field 2 = ID, field 5 = Coin name)
  # Fields are: empty | ID | Path | Symbol | Coin | empty
  ID=$(echo "${line}" | awk -F'|' '{print $2}' | sed -e 's/^ *//' -e 's/ *$//')
  COIN=$(echo "${line}" | awk -F'|' '{print $5}' | sed -e 's/^ *//' -e 's/ *$//')

  # Tidy up the ID
  ID=$(echo "$ID" | sed -e 's/[^0-9]//g')
  # Tidy up the coin
  COIN=$(echo "$COIN" | sed -e 's/\].*//' -e 's/^\[//' -e 's/ /_/g' -e 's/-/_/g' | tr '[:lower:]' '[:upper:]')
  # Should only have digits, upper-case letters and _ at this point
  if [[ ! "${COIN}" =~ ^[0-9A-Z_]+$ ]]; then
    continue
  fi

  # Valid variables must start with A-Z...
  if [[ "${COIN}" =~ ^[A-Z] ]]; then
    # Skip if we've already seen this coin name (avoid duplicates)
    if [[ -n "${SEEN_COINS[$COIN]}" ]]; then
      continue
    fi
    SEEN_COINS[$COIN]=1
    echo "${COIN} = uint32(${ID})" >>${OUTPUT}
  fi
done < <(wget -q -O - https://raw.githubusercontent.com/satoshilabs/slips/master/slip-0044.md)

cat >>${OUTPUT} <<EOEND
)
EOEND

gofmt -w ${OUTPUT}
