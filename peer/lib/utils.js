'use strict'

const _ = require('lodash')

const utils = {
  getRandomBit: () => {
    return Math.random() > 0.5 ? 0 : 1
  },

  getRandomHash: (size) => {
    return _.times(size).reduce((acc) => {
      return acc + utils.getRandomBit()
    }, '')
  }
}

module.exports = utils

