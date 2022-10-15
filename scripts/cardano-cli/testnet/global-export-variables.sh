#!/usr/bin/env bash

# Unofficial bash strict mode.
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -e
set -o pipefail


# Define export variables

export BASE=/home/lawrence/src/littercoin
export WORK=$BASE/work
export CARDANO_CLI=/home/lawrence/.local/bin/cardano-cli
export CARDANO_NODE_SOCKET_PATH=$BASE/node.socket
export TESTNET_MAGIC=2
export ADMIN_VKEY=/home/lawrence/.local/keys/testnet/admin/key.vkey
export ADMIN_SKEY=/home/lawrence/.local/keys/testnet/admin/key.skey
export ADMIN_PKH=/home/lawrence/.local/keys/testnet/admin/key.hash
export MERCHANT_SKEY=/home/lawrence/.local/keys/testnet/merchant/key.skey
export MIN_ADA_OUTPUT_TX=2000000
export MIN_ADA_OUTPUT_TX_REF=20000000
export COLLATERAL_ADA=11000000
export ADMIN_UTXO=cb1a293c1203b87eb7ab65fdbcb722b6c7cdb3abb4544b949ab47cc9fb47383a#0
export ADMIN_COLLATERAL=037d222048842877d575b3f93b0ba20b64b20c5398ace6b3bfb343ad9be749fb#0
export ADMIN_CHANGE_ADDR=addr_test1vzu6hnmgvageu2qyypy25yfqwg222tndt5eg3d6j68p8dqspgdxn7
export MERCHANT_ADDR=addr_test1vq7k907l7e59t52skm8e0ezsnmmc7h4xy30kg2klwc5n8rqug2pds
export MERCHANT_UTXO_NFT_TOKEN=5b2fd4c1c21d00500f4b299c9d1eeeef7a8e0e22ea3f88b9e2128ca225d9d909#1
export MERCHANT_UTXO_LC_TOKEN=ee864c7522201d1b86c711c985acd7d5f19fdb9509aa63a4db0a98484584d213#1
export MERCHANT_UTXO=e70f8a3d2195d22d474bcc0775ac2d7f239cedebf708789ab266bc581c6eccd7#0
export MERCHANT_COLLATERAL=dbc3d08f752d876281c1c02c6813316f4bb39e15e3e4fd644799822b327686cb#1
export USER_ADDR=addr_test1vq5s7k4kwqz4rrfe8mm9jz9tpm7c5u93yfwwsaw708yxs5sm70qjg
export LC_VAL_REF_SCRIPT=20a6c33162e21420d671f64a983023855fe2444cb0e8bb988718eb2d9d833aa4#2
export LC_MINT_REF_SCRIPT=20a6c33162e21420d671f64a983023855fe2444cb0e8bb988718eb2d9d833aa4#3
export NFT_MINT_REF_SCRIPT=20a6c33162e21420d671f64a983023855fe2444cb0e8bb988718eb2d9d833aa4#4


