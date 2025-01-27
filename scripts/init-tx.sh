#!/usr/bin/env bash

##############################################################
# You must do these steps first before running this script
##############################################################
#
# Step 1.   Confirm you have 2 UTXO at admin address (5 Ada for Collateral, and anything greater than 5 Ada)
# Step 2.   Update src/deploy.js with that UTXO (and admin pkh) 
# Step 3.   deno run --allow-read --allow-write src/deploy.js
# Step 4.   Copy deploy/* scripts/[devnet|testnet|mainnet]/data
##############################################################


# Unofficial bash strict mode.
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -e
set -o pipefail

# enabled debug flag for bash shell
set -x

# check if command line argument is empty or not present
if [ -z $1 ]; 
then
    echo "init-tx.sh:  Invalid script arguments"
    echo "Usage: init-tx.sh [devnet|testnet|mainnet]"
    exit 1
fi
ENV=$1

# Pull in global export variables
MY_DIR=$(dirname $(readlink -f $0))
source $MY_DIR/$ENV/global-export-variables.sh

if [ "$ENV" == "mainnet" ];
then
    network="--mainnet"
else
    network="--testnet-magic $TESTNET_MAGIC"
fi

echo "Socket path: $CARDANO_NODE_SOCKET_PATH"

ls -al "$CARDANO_NODE_SOCKET_PATH"

mkdir -p $WORK
mkdir -p $WORK-backup
rm -f $WORK/*
rm -f $WORK-backup/*

# generate values from cardano-cli tool
$CARDANO_CLI query protocol-parameters $network --out-file $WORK/pparms.json

# load in local variable values
thread_token_script="$BASE/scripts/$ENV/data/tt-minting-policy.plutus"
thread_token_mph=$(cat $BASE/scripts/$ENV/data/tt-minting-policy.hash)
thread_token_name=$(cat $BASE/scripts/$ENV/data/tt-token-name.json | jq -r '.bytes')
threat_token_redeemer_file_path="$BASE/scripts/$ENV/data/tt-redeemer-init.json"
lc_validator_script="$BASE/scripts/$ENV/data/lc-validator.plutus"
lc_validator_script_addr=$($CARDANO_CLI address build --payment-script-file "$lc_validator_script" $network)
lc_mint_script="$BASE/scripts/$ENV/data/lc-minting-policy.plutus"
lc_mint_script_addr=$($CARDANO_CLI address build --payment-script-file "$lc_mint_script" $network)
lc_token_name=$(cat $BASE/scripts/$ENV/data/lc-token-name.json | jq -r '.bytes')
lc_redeemer_file_path="$BASE/scripts/$ENV/data/lc-redeemer-init.json"

echo "starting littercoin init-tx.sh"

echo $lc_validator_script_addr > $BASE/scripts/$ENV/data/lc-validator.addr
echo $lc_mint_script_addr > $BASE/scripts/$ENV/data/lc-minting-policy.addr


################################################################
# Mint the threadtoken and littercoins and lock it
# to the littercoin smart contract
################################################################

# Step 1: Get UTXOs from admin
# There needs to be at least 2 utxos that can be consumed; one for spending of the token
# and one uxto for collateral

admin_utxo_addr=$($CARDANO_CLI address build $network --payment-verification-key-file "$ADMIN_VKEY")
$CARDANO_CLI query utxo --address "$admin_utxo_addr" --cardano-mode $network --out-file $WORK/admin-utxo.json

cat $WORK/admin-utxo.json | jq -r 'to_entries[] | select(.value.value.lovelace > '$COLLATERAL_ADA' ) | .key' > $WORK/admin-utxo-valid.json
readarray admin_utxo_valid_array < $WORK/admin-utxo-valid.json
admin_utxo_in=$(echo $admin_utxo_valid_array | tr -d '\n')

cat $WORK/admin-utxo.json | jq -r 'to_entries[] | select(.value.value.lovelace == '$COLLATERAL_ADA' ) | .key' > $WORK/admin-utxo-collateral-valid.json
readarray admin_utxo_valid_array < $WORK/admin-utxo-collateral-valid.json
admin_utxo_collateral_in=$(echo $admin_utxo_valid_array | tr -d '\n')

# Update the littercoin datum accordingly
cat $BASE/scripts/$ENV/data/lc-datum-init.json | \
jq -c '
  .list[0].int   |= '$MIN_ADA_OUTPUT_TX'' > $WORK/lc-datum-out.json


# Step 2: Build and submit the transaction
$CARDANO_CLI transaction build \
  --babbage-era \
  --cardano-mode \
  $network \
  --change-address "$admin_utxo_addr" \
  --tx-in-collateral "$admin_utxo_collateral_in" \
  --tx-in "$admin_utxo_in" \
  --mint "1 $thread_token_mph.$thread_token_name + $LC_SUPPLY $thread_token_mph.$lc_token_name" \
  --mint-script-file "$thread_token_script" \
  --mint-redeemer-file "$threat_token_redeemer_file_path" \
  --tx-out "$lc_validator_script_addr+$MIN_ADA_OUTPUT_TX + 1 $thread_token_mph.$thread_token_name + $LC_SUPPLY $thread_token_mph.$lc_token_name" \
  --tx-out-inline-datum-file "$WORK/lc-datum-out.json" \
  --tx-out "$lc_validator_script_addr+$MIN_ADA_OUTPUT_TX_REF" \
  --tx-out-reference-script-file "$lc_validator_script" \
  --protocol-params-file "$WORK/pparms.json" \
  --out-file $WORK/init-tx-alonzo.body


echo "tx has been built"

$CARDANO_CLI transaction sign \
  --tx-body-file $WORK/init-tx-alonzo.body \
  $network \
  --signing-key-file "${ADMIN_SKEY}" \
  --out-file $WORK/init-tx-alonzo.tx

echo "tx has been signed"

echo "Submit the tx with plutus script and wait 5 seconds..."
$CARDANO_CLI transaction submit --tx-file $WORK/init-tx-alonzo.tx $network



