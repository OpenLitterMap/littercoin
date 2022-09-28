{-# LANGUAGE NoImplicitPrelude      #-}
{-# LANGUAGE OverloadedStrings      #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE TypeApplications       #-}

module Littercoin.Deploy
    ( main
    ) where

import           Cardano.Api                          (PlutusScript,
                                                       PlutusScriptV2,
                                                       writeFileTextEnvelope)
import           Cardano.Api.Shelley                  (PlutusScript (..),
                                                       ScriptDataJsonSchema (ScriptDataJsonDetailedSchema),
                                                       fromPlutusData,
                                                       scriptDataToJson)
import           Codec.Serialise                      (serialise)
import           Data.Aeson                           (encode)
import qualified Data.ByteString.Char8                as B
import qualified Data.ByteString.Base16               as B16
import qualified Data.ByteString.Lazy                 as LBS
import qualified Data.ByteString.Short                as SBS
import           Data.Functor                         (void)
import qualified Ledger.Typed.Scripts                 as Scripts
import qualified Ledger.Address                       as Address
import           Ledger.Value                         as Value
import           Littercoin.Types
import           Littercoin.OnChain
import qualified Plutus.Script.Utils.V2.Typed.Scripts as PSU.V2
import qualified Plutus.V2.Ledger.Api                 as PlutusV2
import qualified Plutus.V2.Ledger.Contexts            as Contexts
import qualified Plutus.V2.Ledger.Tx                  as TxV2
import qualified PlutusTx
import           PlutusTx.Prelude                     as P hiding
                                                           (Semigroup (..),
                                                            unless, (.))
import           Prelude                              (IO, FilePath, Semigroup (..),
                                                       Show (..), print, (.),
                                                       String)




-------------------------------------------------------------------------------------
-- START - Littercoin Token Metadata - A value entry has a max 64 UTF-8 Byte Limit
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Please note that changes the following token metadata requires this 
-- file to be compiled again and deployed with the updated values.
-------------------------------------------------------------------------------------
{-

-- **** REQUIRED METADATA FIELDS ***

requiredMetadata :: RequiredMetadata
requiredMetadata = RequiredMetadata
    {
        address = "123 Street"
    ,   lat =  4560436487
    ,   long = -7737826809
    ,   category = "Efficiency"
    ,   method = "Solar"                        
    ,   cO2Qty = 50                             
    ,   reg_serial = "123-456-789-10101010"     
    }


-- **** OPTIONAL METADATA FIELDS ***

optionalMetadata :: OptionalMetadata
optionalMetadata = OptionalMetadata
    {
        name = "Solar Pannels"
    ,   image = "ipfs/QmT3rYtkkw4wFBP5SfxENAfDY9NuYoZAz2HVng4cQqnVZe"
    ,   mediaType = "image/png"
    ,   description = "Carbon credit offset in metric tons"
    ,   files = [fileData]
    }


fileData :: FileData
fileData = FileData
    {
         file_name = "Carbon Credit"
    ,    file_mediaType = "image/png"
    ,    src = "ipfs://QmT3rYtkkw4wFBP5SfxENAfDY9NuYoZAz2HVng4cQqnVZe" 
    }

-}

-------------------------------------------------------------------------------------
-- END - Littercoin Metadata
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-- START - Littercoin Minting Policy Parameters 
-------------------------------------------------------------------------------------
-- These are dummy values and need to be replaced with real values for
-- the appropriate enviornment (eg devnet, testnet or mainnet)
-------------------------------------------------------------------------------------

-- Admin spending UTXO
txIdBS :: B.ByteString
txIdBS = "eb60c323585934b66e5dbbf7a1fac4652c17902e4bc0e8768f70cd7ca8c4fd63"

-- Admin spending UTXO index
txIdIdxInt :: Integer
txIdIdxInt = 0

-- Admin public key payment hash
adminPubKeyHashBS :: B.ByteString
adminPubKeyHashBS = "a766096168c31739f1b52ee287d5b27ad0f68ba76462301565406419"

lcTokName :: PlutusV2.TokenName
lcTokName = "Littercoin"

nftTokName :: PlutusV2.TokenName
nftTokName = "Littercoin Approved Merchant"

lcDatum :: LCDatum
lcDatum = LCDatum 
    {   adaAmount = 0                                         
    ,   lcAmount = 0
    }

-------------------------------------------------------------------------------------
-- END - Littercoin Minting Policy Parameters 
-------------------------------------------------------------------------------------
    
   


-------------------------------------------------------------------------------------
-- START - Derived values
-------------------------------------------------------------------------------------

adminPaymentPkh :: Address.PaymentPubKeyHash
adminPaymentPkh = Address.PaymentPubKeyHash (PlutusV2.PubKeyHash $ decodeHex adminPubKeyHashBS)


txOutRef' :: TxV2.TxOutRef
txOutRef' = TxV2.TxOutRef
        {
            TxV2.txOutRefId = TxV2.TxId
            {
                TxV2.getTxId = decodeHex txIdBS
            } 
        ,   TxV2.txOutRefIdx = txIdIdxInt
        }


ttTokName :: Value.TokenName
ttTokName = Value.TokenName $ sha2_256 txBS
    where
        txBS = (TxV2.getTxId(TxV2.txOutRefId txOutRef')) <> 
                intToBBS(TxV2.txOutRefIdx txOutRef')  


ttTokValue :: Value.Value
ttTokValue = ttVal
  where
    (_, ttVal) = Value.split(threadTokenValue threadTokenCurSymbol ttTokName)



nftMintParams :: NFTMintPolicyParams
nftMintParams = NFTMintPolicyParams 
    {
        nftTokenName = nftTokName
    ,   nftAdminPkh = adminPaymentPkh
    }

nftTokValue :: Value.Value
nftTokValue = nftTokVal
  where
    (_, nftTokVal) = Value.split(nftTokenValue (nftCurSymbol nftMintParams) nftTokName)



lcParams :: LCValidatorParams
lcParams = LCValidatorParams
    {   lcvAdminPkh         = adminPaymentPkh
    ,   lcvNFTTokenValue    = nftTokValue
    ,   lcvLCTokenName      = lcTokName
    ,   lcvThreadTokenValue = ttTokValue
    }




{-

mph :: MintingPolicyHash
mph = Scripts.mintingPolicyHash $ policy mintParams


-- Following the Cardano NFT metadatata standard https://cips.cardano.org/cips/cip25/
tokenMetadata :: Data.Aeson.Value
tokenMetadata = object
    [   "721" .= object
        [decodeUtf8 (B.pack (show mph)) .= object
                    [decodeUtf8(B.pack (replace "0x" "" (show tokenName))) .= object 
                            [   "name" .= (decodeUtf8 $ name optionalMetadata),
                                "image" .= (decodeUtf8 $ image optionalMetadata),
                                "mediaType" .= (decodeUtf8 $ mediaType optionalMetadata),
                                "description" .= (decodeUtf8 $ description optionalMetadata),
                                "files" .= [object
                                    [
                                        "name" .= (decodeUtf8 $ file_name ((files optionalMetadata)!!0)),
                                        "mediaType" .= (decodeUtf8 $ file_mediaType ((files optionalMetadata)!!0)),
                                        "src" .= (decodeUtf8 $ src ((files optionalMetadata)!!0))
                                    ] ],
                                "required" .= object
                                    [
                                        "address" .= (decodeUtf8 $ address requiredMetadata),
                                        "lat" .= (lat requiredMetadata),
                                        "long" .= (long requiredMetadata),
                                        "category" .= (decodeUtf8 $ category requiredMetadata),
                                        "method" .= (decodeUtf8 $ method requiredMetadata),
                                        "cO2Qty" .= (cO2Qty requiredMetadata),
                                        "registrarSerialNo" .= (decodeUtf8 $ reg_serial requiredMetadata)
                                    ]
                            ]
                    ]
        , "version" .= ("1.0" :: Haskell.String)
        ]
    ]

-}
-------------------------------------------------------------------------------------
-- END - Derived values 
-------------------------------------------------------------------------------------
 

main::IO ()
main = do

    -- Generate plutus scripts and hashes
    --_ <- writeTTMintingPolicy
    writeTTMintingPolicy
    --writeMintingPolicyHash

    -- Generate token name and metadata
    --writeTokenName
    --writeTokenMetadata
    
    -- Generate redeemers
    writeRedeemerInit
    --writeRedeemerMint
    --writeRedeemerBurn
    
    return ()
{-
dataToScriptData :: PlutusTx.Data -> ScriptData
dataToScriptData (Constr n xs) = ScriptDataConstructor n $ dataToScriptData <$> xs
dataToScriptData (Map xs)      = ScriptDataMap [(dataToScriptData x', dataToScriptData y) | (x', y) <- xs]
dataToScriptData (List xs)     = ScriptDataList $ dataToScriptData <$> xs
dataToScriptData (I n)         = ScriptDataNumber n
dataToScriptData (B bs)        = ScriptDataBytes bs
-}

--writeJSON :: PlutusTx.ToData a => FilePath -> a -> IO ()
--writeJSON file = LBS.writeFile file . encode . scriptDataToJson ScriptDataJsonDetailedSchema . dataToScriptData . PlutusTx.toData
--writeJSON file red = LBS.writeFile file encode (scriptDataToJson ScriptDataJsonDetailedSchema $ fromPlutusData $ PlutusV2.toData red)

writeRedeemerInit :: IO ()
writeRedeemerInit = 
    let red = PlutusV2.Redeemer $ PlutusTx.toBuiltinData $ ThreadTokenRedeemer txOutRef'
    in
        --writeJSON "deploy/redeemer-thread-token-mint.json" red
        LBS.writeFile "deploy/redeemer-thread-token-mint.json" $ encode (scriptDataToJson ScriptDataJsonDetailedSchema $ fromPlutusData $ PlutusV2.toData red)


writeTTMintingPolicy :: IO ()
writeTTMintingPolicy = void $ writeFileTextEnvelope "deploy/thread-token-minting-policy.plutus" Nothing serialisedScript
  where
    script :: PlutusV2.Script
    script = PlutusV2.unMintingPolicyScript threadTokenPolicy 

    scriptSBS :: SBS.ShortByteString
    scriptSBS = SBS.toShort . LBS.toStrict $ serialise script

    serialisedScript :: PlutusScript PlutusScriptV2
    serialisedScript = PlutusScriptSerialised scriptSBS

{-
 
-- | Conversion functions from Plutus Builtin datatypes to plutus script data types that are 
--   run on the cardano blockchain 
dataToScriptData :: Data -> ScriptData
dataToScriptData (Constr n xs) = ScriptDataConstructor n $ dataToScriptData <$> xs
dataToScriptData (Map xs)      = ScriptDataMap [(dataToScriptData x', dataToScriptData y) | (x', y) <- xs]
dataToScriptData (List xs)     = ScriptDataList $ dataToScriptData <$> xs
dataToScriptData (I n)         = ScriptDataNumber n
dataToScriptData (B bs)        = ScriptDataBytes bs


writeJSON :: ToData a => FilePath -> a -> IO ()
writeJSON file = LBS.writeFile file . encode . scriptDataToJson ScriptDataJsonDetailedSchema . dataToScriptData . PlutusTx.toData


writeValidator :: FilePath -> Ledger.Validator -> IO (Either (FileError ()) ())
writeValidator file = writeFileTextEnvelope @(PlutusScript PlutusScriptV1) file Nothing . PlutusScriptSerialised . SBS.toShort . LBS.toStrict . serialise . Ledger.unValidatorScript 


writeRedeemerMint :: IO ()
writeRedeemerMint = 

    let red = Scripts.Redeemer $ PlutusTx.toBuiltinData $ MintPolicyRedeemer 
                     {
                        mpPolarity = True  -- mint token
                     }
    in
        writeJSON "deploy/redeemer-token-mint.json" red


writeRedeemerBurn :: IO ()
writeRedeemerBurn = 

    let red = Scripts.Redeemer $ PlutusTx.toBuiltinData $ MintPolicyRedeemer 
                     {
                        mpPolarity = False  -- burn token
                     }
    in
        writeJSON "deploy/redeemer-token-burn.json" red


writeTokenName :: IO ()
writeTokenName = writeJSON "deploy/token-name.json" tokenName


writeTokenMetadata :: IO ()
writeTokenMetadata = 
    
    let file = "deploy/token-metadata.json"
    in LBS.writeFile file $ encode tokenMetadata
    
writeMintingPolicyHash :: IO ()
writeMintingPolicyHash = writeJSON "deploy/minting-policy.hash" $ PlutusTx.toBuiltinData $ Scripts.mintingPolicyHash $ policy mintParams

-- Pull out a validator from a minting policy
mintValidator :: Ledger.MintingPolicy -> Ledger.Validator
mintValidator pol = Ledger.Validator $ unMintingPolicyScript pol

writeMintingPolicy :: IO (Either (FileError ()) ())
writeMintingPolicy = writeValidator "deploy/minting-policy.plutus" $ mintValidator $ policy mintParams

  

-}

-- | Decode from hex base 16 to a base 10 bytestring is needed because
--   that is how it is stored in the ledger onchain
decodeHex :: B.ByteString -> P.BuiltinByteString
decodeHex hexBS =    
         case getTx of
            Right decHex -> do
                --putStrLn $ "Tx name: " ++ show t
                P.toBuiltin(decHex)  
            Left _ -> do
                --putStrLn $ "No Token name: " ++ show e
                P.emptyByteString 
                
        where        
            getTx :: Either String B.ByteString = B16.decode hexBS

