'use strict'

const _ = require('lodash')
const asyncRedis = require('async-redis')
const Buslane = require('buslane')
const chalk = require('chalk')
const crypto = require('crypto')

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

// console.inspect(config)

const buslane = new Buslane(config.buslane)

const peers = Object.keys(buslane).filter(s => s.startsWith('peer')).map(peerName => buslane[peerName])

const p2p = {
  ping: () => 'PONG',
  receiveTransfer: async (blockPrecursor) => {
    console.inspect({ label: 'entering receive transfer', blockPrecursor })

    // create new cm
    const potentialSecret = await mktree.makeSecret(blockPrecursor)

    console.log({ label: 'receipt', potentialSecret })

    const nullifier = await mktree.makeNullifier(blockPrecursor)

    console.log({ label: 'receiveTransfer', potentialSecret, nullifier })

    // make everything(snarky: verify proof, blockexplore: nullifier absent)
    const proof = await snarky.generateProof(blockPrecursor, potentialSecret, nullifier)

    console.inspect({ label: 'receiveTransfer:generateProof', proof })

    // write block
    const newBlock = await blockCooker.makeBlock(blockPrecursor, newCm)

    // propose the block
    let success = true
    for (let i = 0; i < peers.length; i++) {
      try {
        peers[i].p2p.receiveBlock()

      } catch (err) {
        console.log(chalk.red(`peer ${i} refused the block`))
        success = false
      }
    }

    // if all accept
    if (success) {
      // add the block
      await storage.addBlock(newBlock)
      // update the mktree
      await mktree.addCm(newCm)
      // store the secret values(to spend the new note)
      await storage.addSecretKey(sn)
    }


  },
  receiveBlock: async (block) => {

    return 'Accepted'
    // check the block(snarky verify proof)
    // if all good
    // add the block
    // update the mktree(ocaml mktree)
  }
}


const blockCooker = {
  makeBlock: async () => {
    return { label: 'Im a block' }
  },

  makeBlockPrecursor: async ({ secret, currentRoot }) => {
    // console.log('makeBlockPrecursor')
    const path = await mktree.getPath(currentRoot, secret.position)
    // console.log('succesMaking block prec')
    return { secret, currentRoot, path }
  }
}

function getRandomBit() {
  return Math.random() > 0.5 ? 0 : 1
}

function getRandomHash(size) {
  return _.times(size).reduce((acc) => {
    return acc + getRandomBit()
  }, '')
}


const storage = {
  ns: {
    secrets: 'SECRETS',
    blocks: 'BLOCKS',
  },
  // secret: necesseraty information to spend cm, its object made of
  //   secretKey: private key to the cm
  //   flag: bit , clean or not
  //   value: note value
  //   path to the cm on the mktree

  getSecret: async () => {
    try {
      const lastSecretIndex = (await redis.llen(storage.ns.secrets)) - 1
      if (lastSecretIndex < 0) {
        // throw new Error('No note to spend')

        // TODO: fix that
        return {
          label: 'THIS IS A NOTE',
          secretKey: 'this is a key',
          flag: getRandomBit(),
          value: 1,
          position: getRandomHash(4)
        }
      }

      return await redis.lindex(storage.ns.secrets, lastSecretIndex)
    } catch (err) {
      console.error(err)
      throw new Error('Failed to get secret note')
    }
  },

  addBlock: async (block) => {
    return await redis.lpush(storage.ns.blocks, block)
  },

  addCm: async (cm) => {
    return await redis.lpush(storage.ns.secrets, block)
  }
}

const mktree = {
  getCurrentRoot: () => {
    return 'THIS IS A ROOT'
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

    console.inspect({label: 'makeSecret', blockPrecursor})

    const result = {
      secretKey,
      cm,
      value: blockPrecursor.value,
      flag: blockPrecursor.flag,
    }

    return result
  },

  makeNullifier: async (blockPrecursor) => {
    // cli call makeNulifier value, flag, blockPrecursor.secretKey => hash(hash(secretKey, flagValue), secretKey)

    const nullifier = 'This is a perdesen hashed Nullifer'

    return nullifier
  }
}

const snarky = {
  makeProof: async (currentRoot, secret) => {
    // cli call currentRoot, secret => proof
    const proof = 'this is a proof'
    return proof
  },

  generateProof: (blockPrecursor, potentialSecret, nullifier) => {
    // cli call snarky_cli TBD
    //   bp { secret, currentRoot, path }
    //   potentialSecret
    //   nullifer
    //      => Proof
    const string = 'THE PROOF: this is a sliceable bit string, maybe a file, depends on snarky'

    return proof
  },

  verifyProof: async (/* ???? */) => {

  }
}

const wallet = {
  status: async () => {
    return 'OK'
  },
  transfer: async (targetPeer) => {
    console.log(1)
    // get secret values
    const secret = await storage.getSecret()
    console.log(2)
    // mktree get old root and old path of the to be spent cm
    const currentRoot = await mktree.getCurrentRoot()
    console.log(3)
    // snarky make the proofs
    const proof = await snarky.makeProof(currentRoot, secret)

    console.log(4)

    const blockPrecursor = await blockCooker.makeBlockPrecursor({ secret, currentRoot })
    // console.log({blockPrecursor})

    // console.inspect({ secretKey, currentRoot, blockPrecursor })
    // pass it to targetPeer
    console.log(5)
    console.log({ targeted: peers[targetPeer] })
    const res = await peers[targetPeer].p2p.receiveTransfer(blockPrecursor)

    return 'DONE'
  }
}

buslane.registerIngress('p2p', p2p)
buslane.registerIngress('wallet', wallet)

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



process.on('uncaughtException', function (err) {
  console.inspect(err)
})
