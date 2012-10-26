express = require 'express'
http = require 'http'
path = require 'path'
less = require 'less-middleware'
coffeescript = require 'connect-coffee-script'
nunjucks =  require 'nunjucks'
filters = require './lib/filters'
utils = require './lib/utils'

app = utils.patchApp express()

app.configure 'development', ->
  app.use express.errorHandler()
  app.use less
    src: path.join(__dirname, 'public')
    force: true
  app.use coffeescript
    src: 'coffeescripts'
    dest: 'javascripts'
    baseDir: 'public'
    bare: false
    force: true

app.configure ->
  env = new nunjucks.Environment(new nunjucks.FileSystemLoader('views'))
  env.express(app)
  filters.registerFilters(env)

  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.static(__dirname + '/public')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router


app.mount 'home'


http.createServer(app).listen process.env.PORT or 3000

console.log "server running - #{new Date()}"
