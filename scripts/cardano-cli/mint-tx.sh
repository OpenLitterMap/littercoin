#!/usr/bin/env bash

# Unofficial bash strict mode.
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -e
set -o pipefail

# enabled debug flag for bash shell
set -x

# check if command line argument is empty or not present
if [ -z $3 ]; 
then
    echo "mint-tx.sh:  Invalid script arguments"
    echo "Usage: mint-tx.sh [devnet|preview|preprod|mainnet] txHash txIndx"
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



# Specify the utxo at the smart contract address we want to mint
mint_utxo_in=$2
mint_utxo_in_txid=$mint_utxo_in#$3


# generate values from cardano-cli tool
$CARDANO_CLI query protocol-parameters $network --out-file $WORK/pparms.json

# load in local variable values
validator_script="$BASE/scripts/cardano-cli/$ENV/data/lc-validator.plutus"
validator_script_addr=$($CARDANO_CLI address build --payment-script-file "$validator_script" $network)
redeemer_mint_file_path="$BASE/scripts/cardano-cli/$ENV/data/redeemer-mint.json"
redeemer_val_file_path="$BASE/scripts/cardano-cli/$ENV/data/redeemer-mint-val.json"
thread_token_mph=$(cat $BASE/scripts/cardano-cli/$ENV/data/thread-token-minting-policy.hash | jq -r '.bytes')
thread_token_name=$(cat $BASE/scripts/cardano-cli/$ENV/data/thread-token-name.json | jq -r '.bytes')
lc_mint_mph=$(cat $BASE/scripts/cardano-cli/$ENV/data/lc-minting-policy.hash | jq -r '.bytes')
lc_token_name=$(cat $BASE/scripts/cardano-cli/$ENV/data/lc-token-name.json | jq -r '.bytes')
admin_pkh=$(cat $ADMIN_PKH)


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


# Step 2: Get the littercoin smart contract utxos
$CARDANO_CLI query utxo --address $validator_script_addr $network --out-file $WORK/validator-utxo.json

mint_datum_in=$(jq -r 'to_entries[] 
| select(.key == "'$mint_utxo_in_txid'") 
| .value.inlineDatum' $WORK/validator-utxo.json)

echo -n "$mint_datum_in" > $WORK/mint-datum-in.json


# Get the minting info from the datum
lc_amount=$(jq -r '.fields[1].int' $WORK/mint-datum-in.json)
dest_addr_encoded=$(jq -r '.fields[2].bytes' $WORK/mint-datum-in.json)
dest_addr=$(echo -n "$dest_addr_encoded=" | xxd -r -p)
return_addr_encoded=$(jq -r '.fields[3].bytes' $WORK/mint-datum-in.json)
return_addr=$(echo -n "$return_addr_encoded=" | xxd -r -p)


# Pull the utxo with the thread token in it
lc_validator_utxo_tx_in=$(jq -r 'to_entries[] 
| select(.value.value."'$thread_token_mph'"."'$thread_token_name'") 
| .key' $WORK/validator-utxo.json)


# Pull the datum with the thread token attached to the utxo
lc_validator_datum_in=$(jq -r 'to_entries[] 
| select(.value.value."'$thread_token_mph'"."'$thread_token_name'") 
| .value.inlineDatum' $WORK/validator-utxo.json)

# Save the inline datum to disk
echo -n "$lc_validator_datum_in" > $WORK/lc-datum-in.json


# get the current total Ada and Littercoin amount in the smart contract
total_ada=$(jq -r '.fields[0].int' $WORK/lc-datum-in.json)
total_lc=$(jq -r '.fields[1].int' $WORK/lc-datum-in.json)
new_total_lc=$(($total_lc + $lc_amount))


# Update the littercoin datum accordingly
cat $WORK/lc-datum-in.json | \
jq -c '
  .fields[1].int   |= '$new_total_lc'' > $WORK/lc-datum-out.json


# Upate the redeemer for the validator with the amount of littercoin being minted
cat $redeemer_val_file_path | \
jq -c '
  .fields[0].int          |= '$lc_amount'' > $WORK/redeemer-mint-val.json

# Update the redeemer for minting policy to indicate the amount of ada being spent
cat $redeemer_mint_file_path | \
jq -c '
  .fields[1].int          |= '$total_ada'' > $WORK/redeemer-mint.json



# Step 3: Build and submit the transaction
$CARDANO_CLI transaction build \
  --babbage-era \
  --cardano-mode \
  $network \
  --change-address "$admin_utxo_addr" \
  --tx-in-collateral "$admin_utxo_collateral_in" \
  --tx-in "$admin_utxo_in" \
  --tx-in "$mint_utxo_in_txid" \
  --tx-in "$lc_validator_utxo_tx_in" \
  --spending-tx-in-reference "$LC_VAL_REF_SCRIPT" \
  --spending-plutus-script-v2 \
  --spending-reference-tx-in-inline-datum-present \
  --spending-reference-tx-in-redeemer-file "$WORK/redeemer-mint-val.json" \
  --mint "$lc_amount $lc_mint_mph.$lc_token_name" \
  --mint-tx-in-reference "$LC_MINT_REF_SCRIPT" \
  --mint-plutus-script-v2 \
  --mint-reference-tx-in-redeemer-file "$WORK/redeemer-mint.json" \
  --policy-id "$lc_mint_mph" \
  --tx-out "$validator_script_addr+$total_ada + 1 $thread_token_mph.$thread_token_name" \
  --tx-out-inline-datum-file "$WORK/lc-datum-out.json"  \
  --tx-out "$dest_addr+$MIN_ADA_OUTPUT_TX + $lc_amount $lc_mint_mph.$lc_token_name" \
  --tx-out "$return_addr+$MIN_ADA_OUTPUT_TX + 1 $OWNER_TOKEN_MPH.$OWNER_TOKEN_NAME" \
  --required-signer-hash "$admin_pkh" \
  --protocol-params-file "$WORK/pparms.json" \
  --out-file $WORK/mint-lc-tx-alonzo.body


echo "tx has been built"

$CARDANO_CLI transaction sign \
  --tx-body-file $WORK/mint-lc-tx-alonzo.body \
  $network \
  --signing-key-file "${ADMIN_SKEY}" \
  --out-file $WORK/mint-lc-tx-alonzo.tx

echo "tx has been signed"

#echo "Submit the tx with plutus script and wait 5 seconds..."
#$CARDANO_CLI transaction submit --tx-file $WORK/mint-lc-tx-alonzo.tx $network



