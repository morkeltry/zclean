'use strict'

const _ = require('lodash')

const Buslane = require('buslane')
const chalk = require('chalk')
const { inspect } = require('util')

const CONFIG = require('./config.json')

const peerId = parseInt(process.argv[2])

console.log(`Starting Peer with ID ${peerId}`)

const config = CONFIG[peerId]


console.inspect = function (...argv) {
  // console.log(chalk.red(`---${(new Date()).getTime()}---`))
  // argv.forEach((arg, i) => {
  //   process.stdout.write(`${i}: `)
  //   console.log(inspect(arg, { colors: true, depth: null }))
  // })
  // console.log(chalk.red('---'))
}


if (!config) {
  throw new Error(`Invalid peer id: ${peerId}`)
}

// console.log('Starting peer with config', { config })

config.buslane = {
  name: `peer${peerId}`,
  shared_api_key: 'Very Secret Indeed',
  map: []
}

_.times(CONFIG.length).forEach(key => {
  config.buslane.map[key] = {
    name: `peer${key}`,
    port: 4000 + (key * 1000),
    ingresses: ['p2p', 'wallet'],
    // Using default buslane certs for now, very secure :/
    // ssl_key_path: './ssl/host.key',
    // ssl_cert_path: './ssl/host.cert'
  }
})

const buslane = new Buslane(config.buslane)

const peers = Object.keys(buslane).filter(s => s.startsWith('peer')).map(peerName => buslane[peerName])

const mktree = require('./lib/mktree')(config)
const snarky = require('./lib/snarky')(config)
const storage = require('./lib/storage')(config)
const blockCooker = require('./lib/blockcooker')(mktree, storage)
const p2p = (require('./lib/p2p'))(peers, mktree, snarky, blockCooker, storage)

// WALLET
const wallet = {
  status: async () => {
    return 'PEER OK'
  },
  balance: async () => {
    // TODO
    return 'Infinity'
  },
  transfer: async (targetPeer) => {
    try {
      // get secret values
      const secret = await storage.getSecret()

      // mktree get old root and old path of the to be spent cm
      const currentRoot = await mktree.getCurrentRoot()

      // TODO  ?? snarky make the proofs
      const proof = await snarky.makeProof(currentRoot, secret)

      const blockPrecursor = await blockCooker.makeBlockPrecursor({ secret, currentRoot })
      // console.log({blockPrecursor})

      // console.inspect({ secretKey, currentRoot, blockPrecursor })
      // pass it to targetPeer
      const res = await peers[targetPeer].p2p.receiveTransfer(blockPrecursor)

      return res
    } catch (err) {
      console.inspect({ label: 'transfer:error', err })
    }
  }
}

buslane.registerIngress('p2p', p2p)
buslane.registerIngress('wallet', wallet)

storage.insertGenesis().then(
  () => {

    // heartbeat
    setInterval(async () => {
      const blocks = [await storage.getLastBlock()]
      for (let i = 0; i < peers.length; i++) {
        try {
          blocks.push(await peers[i].p2p.lastBlock())
        } catch (err) {
          console.log(chalk.red(`could not get heartbeat from peer ${i}`))
        }
      }

      let concensus = true
      let tailHash = blocks[0].blockHash
      blocks.forEach((block) => {
        // console.log(tailHash, block.blockHash)
        if (tailHash !== block.blockHash) {
          concensus = false
        }
      })

      if (!concensus) {
        console.log(chalk.red('warning, network in discord'))
      } else {
        console.log(chalk.green(`${(new Date().getTime())} - network in concensus`))
      }

    }, 1000)
  }
).catch(err => {
  console.inspect({ label: 'bootstrapFailed', err })
})

process.on('uncaughtException', function (err) {
  console.inspect(err)
})
