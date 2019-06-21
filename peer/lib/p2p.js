'use strict'

const chalk = require('chalk')

const p2p = (peers, mktree, snarky, blockCooker, storage) => {
  return {
    ping: () => 'PONG',

    lastBlock: async () => await storage.getLastBlock(),

    receiveTransfer: async (blockPrecursor) => {
      try {
        console.inspect({ label: 'entering receive transfer', receivedBlockPrecursor: blockPrecursor })

        // create new cm
        const potentialSecret = await mktree.makeSecret(blockPrecursor)

        console.inspect({ label: 'receiveTransfer:potentialSecret', potentialSecret })

        const nullifier = await mktree.makeNullifier(blockPrecursor)

        console.inspect({ label: 'receiveTransfer:nullifier', nullifier })

        // make everything(snarky: verify proof, blockexplore: nullifier absent)
        const proof = await snarky.generateProof(blockPrecursor, potentialSecret, nullifier)

        console.inspect({ label: 'receiveTransfer:generateProof', proof })

        // write block
        const newBlock = await blockCooker.makeBlock(blockPrecursor, potentialSecret, proof, nullifier)

        console.inspect({ label: 'receiveTransfer:proposingBlock', newBlock })

        // propose the block
        let success = true
        for (let i = 0; i < peers.length; i++) {
          try {
            await peers[i].p2p.receiveBlock(newBlock)
          } catch (err) {
            console.log(chalk.red(`peer ${i} refused the block`))
            success = false
          }
        }

        // publish nullifier

        // if all accept
        if (success) {
          // Evolving
          const newSecret = potentialSecret

          // add the block
          await storage.addBlock(newBlock)

          // update the mktree
          await mktree.addCm(newSecret.cm)

          // store the secret values(to spend the new note)
          await storage.addSecret(newSecret)

          return 'Block accepted by network'
        }

        return 'Block refused by network'
      } catch (err) {
        console.inspect({ label: 'receiveTransfer:error', err })
      }
    },
    receiveBlock: async (proposedBlock) => {
      try {
        console.inspect({ label: 'receiveBlock', proposedBlock })

        // verify block
        const currentTail = await storage.getLastBlock()

        // console.inspect({ label: 'receiveBlock:checkThatTailMatches', proposedBlock, currentTail })

        if (proposedBlock.parentHash !== currentTail.blockHash) {
          throw new Error('proposed block does not math local tail')
        } else {
          console.inspect({ label: 'receiveBlock:checktail', message: 'tail matched' })
        }

        // check the block(snarky verify proof)
        const success = await snarky.verifyProofs(proposedBlock)

        console.inspect({ label: 'receiveBlock:checkedTail', message: success })

        // if all good
        if (success) {
          const newBlock = proposedBlock

          // add the block
          await storage.addBlock(newBlock)
          // update the mktree(ocaml mktree)
          await mktree.updateRoot(newBlock)

          console.log(chalk.grey(`added block wiht hash  `) + newBlock.blockHash)
        }

        return 'OK'
      } catch (err) {
        console.inspect({ label: 'receiveBlock:error', err })
      }
    }
  }
}

module.exports = p2p
