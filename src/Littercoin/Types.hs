{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE DeriveAnyClass             #-} 
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE NoImplicitPrelude          #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TemplateHaskell            #-}

module Littercoin.Types 
(
     MintPolicyRedeemer(..)
   , LCMintPolicyParams(..)
   , LCRedeemer(..)
   , LCValidatorParams(..)
   , NFTMintPolicyParams(..)
   , ThreadTokenRedeemer(..)   
   , TokenParams(..)  
)where

import              Data.Aeson                          (FromJSON, ToJSON)  
import              GHC.Generics                        (Generic)
import qualified    Ledger.Address as Address           (PaymentPubKeyHash(..))
import qualified    Ledger.Value as Value               (TokenName(..), Value)
import qualified    Plutus.V2.Ledger.Tx as Tx           (TxOutRef(..))
import              Playground.Contract as Playground   (ToSchema)
import qualified    PlutusTx                            (makeIsDataIndexed, makeLift)
import              PlutusTx.Prelude                    (Bool(..), BuiltinByteString, Integer)
import qualified    Prelude as Haskell                  (Show)


-- | The mint policy reeemder indicates if the token is to be minted or burned
data MintPolicyRedeemer = MintPolicyRedeemer
    { 
      mpPolarity                  :: !Bool  -- True = Mint, False = Burn
    , mpWithdrawAmount            :: !Integer -- The amount of Ada to withdraw from the Littercoin contract
                                              -- only used during burning for Littercoin minting policy
    } deriving Haskell.Show

PlutusTx.makeIsDataIndexed ''MintPolicyRedeemer [('MintPolicyRedeemer,0)] 
PlutusTx.makeLift ''MintPolicyRedeemer


-- | The Littercoin mintint policy params passes the Littercoin token name, AdminPkh and NFT Token value 
--   as a parameter into the minting poicy which will make the Littercoin minting policy unique
data LCMintPolicyParams = LCMintPolicyParams
    { 
      lcTokenName                 :: !Value.TokenName
    , lcAdminPkh                  :: !Address.PaymentPubKeyHash
    , lcNFTTokenValue             :: !Value.Value  
    } deriving (Haskell.Show, Generic, FromJSON, ToJSON, Playground.ToSchema)

PlutusTx.makeIsDataIndexed ''LCMintPolicyParams [('LCMintPolicyParams,0)] 
PlutusTx.makeLift ''LCMintPolicyParams


-- | TokenParams are parameters that are passed to the endpoints
data TokenParams = TokenParams
    { 
      tpLCTokenName         :: !BuiltinByteString
    , tpNFTTokenName        :: !BuiltinByteString  
    , tpQty                 :: !Integer
    , tpAdminPkh            :: !Address.PaymentPubKeyHash     
    } deriving (Generic, FromJSON, ToJSON, Haskell.Show, Playground.ToSchema)



-- | The merchant NFT minting policy params passes the NFT token name and adminPkh as a parameter 
--   into the minting poicy which will make the merchant NFT policy unique
data NFTMintPolicyParams = NFTMintPolicyParams
    { 
      nftTokenName                 :: !Value.TokenName
    , nftAdminPkh                  :: !Address.PaymentPubKeyHash 
    } deriving (Haskell.Show, Generic, FromJSON, ToJSON, Playground.ToSchema)

PlutusTx.makeIsDataIndexed ''NFTMintPolicyParams [('NFTMintPolicyParams,0)] 
PlutusTx.makeLift ''NFTMintPolicyParams


-- | The thread token redeemer passes a utxo from the Littercoin admin's wallet 
--   to the thread token miting policy which is used to create the a thread token.
--   A Thread token is needed to make sure we always include the correct validator
--   script as an input to a new transaction.
data ThreadTokenRedeemer = ThreadTokenRedeemer
    {   ttTxOutRef :: !Tx.TxOutRef  
    } deriving Haskell.Show

PlutusTx.makeIsDataIndexed ''ThreadTokenRedeemer [('ThreadTokenRedeemer,0)] 


-- | LCValidatorParams is used to pass the admin pkh, NFT & Littercoin token names as a parameter to the 
--   littercoin validator script
data LCValidatorParams = LCValidatorParams
    {   lcvAdminPkh                 :: !Address.PaymentPubKeyHash
    ,   lcvNFTTokenValue            :: !Value.Value
    ,   lcvLCTokenName              :: !Value.TokenName
    ,   lcvThreadTokenValue         :: !Value.Value  
    } deriving Haskell.Show

PlutusTx.makeIsDataIndexed ''LCValidatorParams [('LCValidatorParams,0)] 
PlutusTx.makeLift ''LCValidatorParams


-- | The LCRedemeer used to indicate if the action is to mint or burn littercoin or
--   to add and remove Ada from the littercoin contract.   Also specify the amount 
--   as well in the redeemer.
data LCRedeemer = 
       MintLC Integer    -- mint littercoin
     | BurnLC Integer    -- burn littercoin and retreive Ada
     | AddAda Integer    -- add Ada to the smart contract
     
    deriving Haskell.Show


PlutusTx.makeIsDataIndexed
  ''LCRedeemer
  [ ('MintLC, 0),
    ('BurnLC, 1),
    ('AddAda, 2)
  ]
PlutusTx.makeLift ''LCRedeemer




