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

import "testing"

// TestKnownCoinTypes verifies that well-known coin types have the correct values
// according to the SLIP-0044 specification.
func TestKnownCoinTypes(t *testing.T) {
	tests := []struct {
		name     string
		coinType uint32
		want     uint32
	}{
		{
			name:     "Bitcoin",
			coinType: BITCOIN,
			want:     0,
		},
		{
			name:     "Litecoin",
			coinType: LITECOIN,
			want:     2,
		},
		{
			name:     "Dogecoin",
			coinType: DOGECOIN,
			want:     3,
		},
		{
			name:     "Ethereum",
			coinType: ETHER,
			want:     60,
		},
		{
			name:     "Ethereum Classic",
			coinType: ETHER_CLASSIC,
			want:     61,
		},
		{
			name:     "XRP",
			coinType: XRP,
			want:     144,
		},
		{
			name:     "Bitcoin Cash",
			coinType: BITCOIN_CASH,
			want:     145,
		},
		{
			name:     "Stellar Lumens",
			coinType: STELLAR_LUMENS,
			want:     148,
		},
		{
			name:     "Monero",
			coinType: MONERO,
			want:     128,
		},
		{
			name:     "Solana",
			coinType: SOLANA,
			want:     501,
		},
		{
			name:     "Cardano",
			coinType: CARDANO,
			want:     1815,
		},
		{
			name:     "Polkadot",
			coinType: POLKADOT,
			want:     354,
		},
		{
			name:     "Cosmos (Atom)",
			coinType: ATOM,
			want:     118,
		},
		{
			name:     "Tezos",
			coinType: TEZOS,
			want:     1729,
		},
		{
			name:     "Algorand",
			coinType: ALGORAND,
			want:     283,
		},
		{
			name:     "Binance",
			coinType: BINANCE,
			want:     714,
		},
		{
			name:     "Filecoin",
			coinType: FILECOIN,
			want:     461,
		},
		{
			name:     "Neo",
			coinType: NEO,
			want:     888,
		},
		{
			name:     "EOS",
			coinType: EOS,
			want:     194,
		},
		{
			name:     "Tron",
			coinType: TRON,
			want:     195,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.coinType != tt.want {
				t.Errorf("%s coin type = %d, want %d", tt.name, tt.coinType, tt.want)
			}
		})
	}
}

// TestCoinTypesAreUint32 verifies that coin types are properly typed as uint32.
func TestCoinTypesAreUint32(t *testing.T) {
	// This test validates that the coin types can be used as uint32
	// If this compiles, the types are correct
	var coinTypes = []uint32{
		BITCOIN,
		ETHER,
		SOLANA,
		CARDANO,
		POLKADOT,
	}

	if len(coinTypes) == 0 {
		t.Error("Expected coin types to be non-empty")
	}
}
