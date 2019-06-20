'use strict'

const asyncRedis = require('async-redis')

const CONFIG = require('./config.json')
const config = CONFIG[process.argv[2]]

if (!config) {
    throw new Error(`Invalid peer number: ${process.argv[2]}`)
}

console.log('Starting peer with config', { config })

const redis = asyncRedis.createClient(config.redisPort);



