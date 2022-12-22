# Littercoin Open Source Repository
## Problem Statement
Litter and plastic pollution are global problems. Crowdsourcing data can help fix this, but data collection tools, visualisations and incentives remain significantly underdeveloped
## The Solution
Littercoin is the first token rewarded for doing citizen science by simply walking around with a smart phone and start collecting information about your local environmental surroundings.
## Getting Started
To setup your own incentized token economy, you can follow the steps below and use this as  a template.
#### Nami Wallet Setup
You will need to use a Cardano wallet and using the Nami wallet is a good wallet for new and experienced users alike.   Nami wallet is a Chrome browser extension wallet and can be found on the Chrome extension page here: 

https://chrome.google.com/webstore/detail/nami/lpfcbjknijpeeillifnkikgncikgfhdo

For testing, it is recommended to setup 2 users.

Follow the instructions to create a new wallet and a seed phase for the 1st user we will call the Admin.   Select the profile image to get to the account detail view, and from there you can create another account called User.

You will need some Cardano, so you can go to the preprod test faucet page here:  

https://docs.cardano.org/cardano-testnet/tools/faucet

Select Receive on the Nami wallet to get and address to send the funds to.   Use that address in the test faucet page and make sure you select preprod network.

Once you have some funds in the Admin account, you can proceed.

#### Demeter Setup
#### Determine your PKH & UTXO
#### Compile Smart Contract Code and Deploy 
#### Threadtoken and Littercoin Initialization
#### Update Environment variables and Start Next.js
## The Application
#### Application Design

![Littercoin User Journey](/images/littercoin_user_journey.png)

![Littercoin High Level Design](/images/littercoin_design.png)

##### Adding Ada
##### Minting Littercoin
##### Burning Littercoin
## Why Helios
#### Performance Benchmarks





## The Littercoin Smart Contract 

The Littercoin smart contract can be tested directly on the hosted site [here](https://littercoin-smart-contract.vercel.app/)
or it can be downloaded and follow setup steps below.


## Clone the repository
```
git clone https://github.com/lley154/littercoin.git
```

## Setting up to test the littercoin smart contracts
```
export NEXT_PUBLIC_BLOCKFROST_API_KEY=>>>Your API Key Here <<<
sudo npm install --global yarn
cd littercoin/app
[littercoin/app]$ npm install
[littercoin/app]$ yarn dev
yarn run v1.22.19
$ next dev
ready - started server on 0.0.0.0:3000, url: http://localhost:3000
event - compiled client and server successfully in 1702 ms (173 modules)
```

Now you can access the preview testnet interfaces and testing the smart contracts by
going to the URL http://localhost:3000



## Setting up to re-build the plutus scripts

### Cabal+Nix build

Use the Cabal+Nix build if you want to develop with incremental builds, but also have it automatically download all dependencies.

Set up your machine to build things with `Nix`, following the [Plutus README](https://github.com/input-output-hk/plutus/blob/master/README.adoc) (make sure to set up the binary cache!).

To enter a development environment, simply open a terminal on the project's root and use `nix-shell` to get a bash shell:

```
$ nix-shell
```

and you'll have a working development environment for now and the future whenever you enter this directory.

The build should not take too long if you correctly set up the binary cache. If it starts building GHC, stop and setup the binary cache.

Afterwards, the command `cabal build` from the terminal should work (if `cabal` couldn't resolve the dependencies, run `cabal update` and then `cabal build`).

Also included in the environment is a working [Haskell Language Server](https://github.com/haskell/haskell-language-server) you can integrate with your editor.
See [here](https://github.com/haskell/haskell-language-server#configuring-your-editor) for instructions.

### Run cabal repl to generate the plutus scripts

```
[nix-shell:~/src/littercoin]$ cabal repl
...
[1 of 3] Compiling Littercoin.Types ( src/Littercoin/Types.hs, /home/lawrence/src/littercoin/dist-newstyle/build/x86_64-linux/ghc-8.10.7/littercoin-0.1.0.0/build/Littercoin/Types.o )
[2 of 3] Compiling Littercoin.OnChain ( src/Littercoin/OnChain.hs, /home/lawrence/src/littercoin/dist-newstyle/build/x86_64-linux/ghc-8.10.7/littercoin-0.1.0.0/build/Littercoin/OnChain.o )
[3 of 3] Compiling Littercoin.Deploy ( src/Littercoin/Deploy.hs, /home/lawrence/src/littercoin/dist-newstyle/build/x86_64-linux/ghc-8.10.7/littercoin-0.1.0.0/build/Littercoin/Deploy.o )
Ok, three modules loaded.
Prelude Littercoin.Deploy> main
Prelude Littercoin.Deploy> :q
Leaving GHCi.
```
The new plutus scripts will be created in the littercoin/deploy directory

```
[nix-shell:~/src/littercoin]$ ls -l deploy/*.plutus
-rw-rw-r-- 1 lawrence lawrence 6767 Oct 16 20:32 deploy/lc-minting-policy.plutus
-rw-rw-r-- 1 lawrence lawrence 8539 Oct 16 20:32 deploy/lc-validator.plutus
-rw-rw-r-- 1 lawrence lawrence 5073 Oct 16 20:32 deploy/nft-minting-policy.plutus
-rw-rw-r-- 1 lawrence lawrence 5499 Oct 16 20:32 deploy/thread-token-minting-policy.plutus
```


## Support/Issues/Community

[Slack](https://join.slack.com/t/openlittermap/shared_invite/zt-fdctasud-mu~OBQKReRdC9Ai9KgGROw) is our main medium of communication and collaboration. Power-users, newcomers, developers, a community of over 400 members - we're all there. 
