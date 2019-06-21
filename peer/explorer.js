'use strict'

const chalk = require('chalk')
const { inspect } = require('util')

const storage = require('./lib/storage')({ redisPort: 4001 })

console.inspect = function (...argv) {
  console.log(chalk.red(`--${(new Date()).getTime()}--`))
  argv.forEach((arg, i) => {
    process.stdout.write(`${i}: `)
    console.log(inspect(arg, { colors: true, depth: null }))
  })
  console.log(chalk.red('---'))
}

let lastTail = {
  id: null
}

async function main() {
  const tailBlock = await storage.getLastBlock()

  if (tailBlock) {
    lastTail = tailBlock

    for (let i = 0; i < await storage.getBlockchainLength(); i++) {
      console.log('block ' + i)
      console.inspect({ id: i, block: await storage.getBlock(i) })
    }
  }


  setInterval(async () => {
    const tailBlock = await storage.getLastBlock()

    // if (tailBlock && tailBlock.id === 0 && !genesisPrinted) {
    //   console.inspect({ blockchainLength: await storage.getBlockchainLength(), tailBlock })
    //   genesisPrinted = true
    // }

    if (lastTail && tailBlock.id !== lastTail.id) {
      console.inspect({
        block: tailBlock,
        blockchainLength: await storage.getBlockchainLength(),
      })
    }

    lastTail = tailBlock
  }, 500)

}

main()
