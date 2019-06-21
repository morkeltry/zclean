'use strict'

const crypto = require('crypto')

const { getRandomHash } = require('./utils')

const mktree = (config) => {
  return {
    addCm: async () => {
      // mktree server cli cm: addCm cm

      return true
    },

    getCurrentRoot: async () => {
      return 'THIS IS THE CURRENT ROOT: "18174068908456306120150473174156806072743489183763912502460320123526599482158"'
    },
    // @return hashes of the mktree necessary for a fold-left(calculate the root with min info)
    getPath: (currentRoot, position) => {
      // cli console.log({label: 'getPath', currentRoot, position })

      return [
        getRandomHash(4),
        getRandomHash(4),
        getRandomHash(4),
      ]
    },
    makeSecret: async (blockPrecursor) => {
      const secretKey = crypto.randomBytes(16)

      // cli call makeCm  value, flag, randomness(128bit) => hash(randomness, flag, value )
      const cm = 'THIS IS A CM Pedersen HASH'

      // console.inspect({
      //   label: 'mktree:makeSecret', blockPrecursor: {
      //     blockPrecursor,
      //     value: blockPrecursor.value
      //   }
      // })

      const result = {
        secretKey,
        cm,
        value: blockPrecursor.secret.value,
        flag: blockPrecursor.secret.flag,
      }

      return result
    },

    updateRoot: async () => {
      // mktree cli

      return true
    },

    makeNullifier: async (blockPrecursor) => {
      // cli call makeNulifier value, flag, blockPrecursor.secretKey => hash(hash(secretKey, flagValue), secretKey)

      const nullifier = 'This is a perdesen hashed Nullifer'

      return nullifier
    }
  }
}

module.exports = mktree
