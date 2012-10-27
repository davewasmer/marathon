path = require 'path'
File = require('oofile').File
config = require('config-chain')(path.join(__dirname, '..', 'config.json'))

config = config.store

fileize = (obj) ->
  for key, value of obj
    if key is "path"
      obj[key] = new File value
    else if toString.call(value) is '[object Object]'
      fileize(value)

fileize config

module.exports = config