'use strict'

const asyncRedis = require('async-redis')

const hashObject = require('object-hash')

const utils = require('./utils')

const ns = {
  secrets: 'secrets',
  blocks: 'blocks',
}

const storage = (config) => {
  const redis = asyncRedis.createClient(config.redisPort);

  // STORAGE
  return {
    // secret: necesseraty information to spend cm, its object made of
    //   secretKey: private key to the cm
    //   flag: bit , clean or not
    //   value: note value
    //   path to the cm on the mktree
    getSecret: async () => {
      try {
        const lastSecretIndex = (await redis.llen(ns.secrets)) - 1
        if (lastSecretIndex < 0) {
          // throw new Error('No note to spend')

          // TODO: fix that
          return {
            label: 'THIS IS A NOTE',
            secretKey: 'this is a key',
            flag: utils.getRandomBit(),
            value: 1,
            position: utils.getRandomHash(4)
          }
        }

        return JSON.parse(await redis.lindex(ns.secrets, lastSecretIndex))
      } catch (err) {
        console.inspect({ label: 'storage:error', err })
        throw new Error('storage: Failed to get secret note')
      }
    },

    addSecret: async (newSecret) => {
      return await redis.rpush(ns.secrets, JSON.stringify(newSecret))
    },

    insertGenesis: async () => {
      if ((await redis.llen(ns.blocks)) === 0) {
        // BLOCK 0
        const blockZero = {
          id: 0,
          parentId: -1,
          parentHash: undefined,
          root: "TODO: FIRST ROOT??",
          nullifier: undefined,
          cm: undefined,
          nfProof: undefined,
          cmProof: undefined,
          bitProof: undefined
        }

        blockZero.blockHash = hashObject(blockZero)

        await redis.rpush(ns.blocks, JSON.stringify(blockZero))
      } else {
        console.log('already bootstraped')
      }
    },

    // Return block 0 or last block
    getLastBlock: async () => {
      try {
        const lastBlockIndex = (await redis.llen(ns.blocks)) - 1

        return JSON.parse(await redis.lindex(ns.blocks, lastBlockIndex))
      } catch (err) {
        console.error(err)
        throw new Error('Failed to get last block')
      }
    },

    getBlockchainLength: async () => {
      return redis.llen(ns.blocks)
    },

    addBlock: async (block) => {
      await redis.rpush(ns.blocks, JSON.stringify(block))
    },

    getBlock: async (id) => {
      return JSON.parse(await redis.lindex(ns.blocks, id))
    },

    addCm: async (cm) => {
      return await redis.rpush(ns.secrets, JSON.stringify(cm))
    }
  }
}

module.exports = storage
