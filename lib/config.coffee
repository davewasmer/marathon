config = require('config-chain')(path.join(__dirname, 'config.json'))

fileize = (obj)
  for key, value of obj
    if key is "path"
      obj[key] = new File value
    else if value.toString() is '[object Object]'
      fileize(value)

fileize config

module.exports = config