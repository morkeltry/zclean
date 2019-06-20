'use strict'
const _ = require('lodash')
const asyncRedis = require('async-redis')
const Buslane = require('buslane')
const chalk = require('chalk')

const CONFIG = require('./config.json')

const peerId = parseInt(process.argv[2])

console.log({ peerId, args: process.argv })

const config = CONFIG[peerId]

const { inspect } = require('util')

console.inspect = function (...argv) {
  console.log(chalk.red('>>> Inspecting'))
  argv.forEach((arg, i) => {
    process.stdout.write(`${i}: `)
    console.log(inspect(arg, { colors: true, depth: null }))
  })
  console.log(chalk.red('<<< end'))
}

if (!config) {
  throw new Error(`Invalid peer id: ${peerId}`)
}

console.log('Starting peer with config', { config })

const redis = asyncRedis.createClient(config.redisPort);


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

console.inspect(config)

const buslane = new Buslane(config.buslane)

const p2p = {
  ping: () => 'PONG',
  receiveTransfer: (blockPrecursor) => {
    // check everything(snarky: verify proof, blockexplore: nullifier absent)
    // create new cm
    // write block
    // propose the block
    // if all accept
    // add the block
    // update the mktree
    // store the secret values(to spend the new note)
  },
  validateBlock: (block) => {
    // check the block(snarky verify proof)
    // if all good
    // add the block
    // update the mktree(ocaml mktree)
  }
}

const wallet = {
  status: () => { console.log('status checked'); return 'OK'; },
  transfer: (targetPeer) => {
    // get secret values
    // mktree get old root and old path of the to be spent cm
    // snarky make the proofs
    // pass it to targetPeer
    peers[targetPeer].receiveTransfer(blockPrecursor)
  }
}

buslane.registerIngress('p2p', p2p)
buslane.registerIngress('wallet', wallet)

const peers = Object.keys(buslane).filter(s => s.startsWith('peer')).map(peerName => buslane[peerName])

// heartbeat
setInterval(async () => {
  for (let i = 0; i < peers.length; i++) {
    try {
      console.log(`${(new Date()).getTime()}: peer ${i} says ${await peers[i].p2p.ping()}`)
    } catch (err) {
      console.log(chalk.red(`could not get heartbeat from peer ${i}`))
    }
  }

}, 2000)

process.on('uncaughtException', function (err) { })
