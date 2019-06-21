'use strict'

const hashObject = require('object-hash')

const blockcooker = (mktree, storage) => {
  return {
    makeBlock: async (blockPrecursor, potentialSecret, proof, nullifier) => {
      const currentTail = await storage.getLastBlock()

      const [nfProof, cmProof, bitProof] = proof.split(':')

      console.inspect({ label: 'blockCooker:makeBlock', currentTail })

      const newBlock = {
        id: currentTail.id + 1,
        parentId: currentTail.id,
        blockHash: null,
        parentHash: currentTail.blockHash,
        root: await mktree.getCurrentRoot(),
        nullifier,
        cm: potentialSecret.cm,
        nfProof,
        cmProof,
        bitProof
      }

      newBlock.blockHash = hashObject(newBlock)

      return newBlock
    },

    makeBlockPrecursor: async ({ secret, currentRoot }) => {
      // console.log('makeBlockPrecursor')
      const path = await mktree.getPath(currentRoot, secret.position)
      // console.log('succesMaking block prec')
      return { secret, currentRoot, path }
    }
  }
}

module.exports = blockcooker
