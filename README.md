# ZClean

Ref papers:

* [ZeroCash paper](http://zerocash-project.org/media/pdf/zerocash-oakland2014.pdf)

## Concept

### Goal

Making a very rough reimplementation of zero-cash like, adding a feature that coins are tainted (with a bit), and that while transferring in zero-knowledge we also prove that the taint is preserved. We only do shielded transactions, and everything has value 1.
The state of the blockchain is a merkle tree containing commitements and a list of nullifier. 

### Components to the blockchain peer + wallet:
* JSON API
* MT server
* Snarky Circuit
* the blockchain, on a Redis list
* a wallet with the secrets necessary for the peer to spend the notes
* a config with the port list

### Adding a block(transferring something):

* I want to transfer a note, I ask my peer to spend it by giving him the neccessary witness informations (aka I use my client, similar to using a full bitcoin node as a wallet) and he creates his own committement.
* it generates the necessary ZKproofs
* sends that to the receiver peer
* the receiver verify all proofs and
  * if successful broadcast it to the network
  * else do nothing/reject
* if it's accepted, the blockchain is now one block larger

### Rules
* start with a mktree, containing commitement of the type H(r,b).
* utxo with 1 in 1 out, no values(or v = 1)
* to transfer, share a zk with the person you are transferring  proving that you know the preimage
* the nulifier is stored in a dead drop style(file, for now, could be anything, as long as it has the potential to be replaced by an anonymous system)

### Block Content:
* root
* nullifier
* new cm
* proof1: nf is computed correctly
* proof2: old cm existed in the tree corresponding to root
* proof3: the flag is consistent (b_old = b_new)

## Running the code

### Requirements:

* Docker(to run the blockchain datastore. redis ATM)
* Ocaml via opam, switched to 4.07.1
* Snarky installed (good luck with that :D)
* node.js 12 to run the client and the peer

### Starting a demo env

* run `./install.sh`
* `docker-compose up` to start the redis instances
* open 6 term windows
* in 3 of them, run `./startPeer.sh 0, 1 and 2`
* in 3 of them, run `./startWallet.sh 0, 1 and 2`

...






