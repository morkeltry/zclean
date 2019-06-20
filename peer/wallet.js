'use strict'

const _ = require('lodash')

const prompt = require('async-prompt')
const chalk = require('chalk')
const clear = require('clear')
const Buslane = require('buslane')

const CONFIG = require('./config.json')

const peerId = parseInt(process.argv[2])
const config = CONFIG[peerId]

config.buslane = {
  name: `wallet${peerId}`,
  shared_api_key: 'Very Secret Indeed',
  map: []
}

const { inspect } = require('util')

console.inspect = function (...argv) {
  console.log(chalk.red('>>> Inspecting'))
  argv.forEach((arg, i) => {
    process.stdout.write(`${i}: `)
    console.log(inspect(arg, { colors: true, depth: null }))
  })
  console.log(chalk.red('<<< end'))
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

console.inspect(buslane)

const peer = buslane[`peer${peerId}`]

function wait(millis) {
  return new Promise(a => {
    setTimeout(a, millis)
  })
}

function printHelp(msg) {
  if (msg) {
    console.log(chalk.red('unrecognized command'))
  }
  console.log('usage transfer, explore, balance')
}

async function main() {
  async function loop() {
    const cmd = await prompt(`peer${peerId}>`)

    try {
      switch(cmd) {
        case 'help': printHelp;break;
        case 'status': console.log(`peer is ${await peer.wallet.status()}`);break;
        case 'transfer':
          // ask peer to make a transfer, check it's not self transfering
          await peer.wallet.transfer(i)
          break;

        default: printHelp('Unrecognized Command');break;
      }

      await wait(1000)
    } catch (err) {
      console.log(err)
    }
  }


  while (true) {
    await clear()
    await loop()
  }
}

process.on('uncaughtException', function (err) {})

main().then(console.log).catch(console.error)
