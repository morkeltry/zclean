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

### Prover file content:
Prover file `transfer_secrets` takes a line of unlabelled values (some are tuples):

*  *r* - our secret with which to spend this commitment
*  *v* - the value of the spent commitment (1)
*  *flag* - the 'clean' flags of the spent commitment, eg 1 or 1155 ( =3*5*7*11 )
*  *l1_sibling* - a tuple of the field value of the sibling of the ancestor on the first level of the Merkel tree, along with the direction in the tree of this value (true/false), eg 34567890098765434567,false
*  *l2_sibling* - " " second level below root
*  *l3_sibling* - " " third level below root, ie the sibling of our commitment
*  *r'* - secret to attach to new commitment
*  *v'* - the value of the new commitment (1)
*  *flag'* - the 'clean' flags of the new commitment, should be same as old one, eg 1 or 1155 ( =3*5*7*11 )

Something like:
```
998
1
0
4567,0
7385,1
2372,0
999
1
0
```

## Running the code

`snarky_cli generate-keys create-coin-commitment.zk --curve Bn128`

#### NB:
on first run, `snarky_cli generate-keys create-coin-commitment.zk --curve Bn128` gives error:
```
File "create-coin-commitment_gen.ml", line 4, characters 24-53:
Error: Signature mismatch:
       ...
       In module R1CS_constraint_system:
       Values do not match:
         val digest : t -> Core.Md5.t
       is not included in
         val digest : t -> Core_kernel.Md5.t
       File "src/backend_intf.ml", line 91, characters 4-27:
         Expected declaration
       File "src/libsnark.ml", line 945, characters 4-27: Actual declaration
```
Don't worry - run it again.

### Requirements:

* Docker(to run the blockchain datastore)
* Snarky installed (good luck with that)
* node.js to run the client

### Starting a demo env

* `docker-compose up` to start the redis instances
* open 6 term windows
* in 3 of them, run `./startPeer.sh 0, 1 and 2`
* in 3 of them, run `./startWallet.sh 0, 1 and 2`

...
