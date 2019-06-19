# Welcome to the Zclean wiki!

Useful papers:

http://zerocash-project.org/media/pdf/zerocash-oakland2014.pdf

component list:

snarky circuit
blockchain in node
client in nodejs

Components to the blockchain peer + wallet:
* JSON API
* MT server
* Snarky Circuit
* the blockchain, on a Redis list
* a wallet with the secrets necessary for the peer to spend the notes
* a config with the port list

Adding a block(transferring something):
* I want to spend a note, I ask my peer to spend it(aka I use my client, similar to using a full bitcoin node as a wallet)
* it generates the necessary ZKproofs, including one that I know the nullifier
* sends that to the receiver peer
* the receiver verify all proofs and
  * if successful broadcast it to the network
  * else do nothing/reject
* if it's accepted, the blockchain is now one block larger

Rules:
* start with a full mktree
* utxo with 1 in 1 out, no values(or v = 1)
* to transfer, share a zk with the person you are transferring  proving  that you know the preimage
* the nulifier is stored in a dead drop style(file, for now, could be anything, as long as it has the potential to be replaced by an anonymous system)

Block Content:
* root
* nullifier
* new cm 
* proof1: nf is computed correctly
* proof2: new CM is well-formed
* proof3: the flag is consistent AKA clean




