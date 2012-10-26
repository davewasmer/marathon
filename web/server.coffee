express = require 'express'
http = require 'http'
path = require 'path'
less = require 'less-middleware'
coffeescript = require 'connect-coffee-script'
nunjucks =  require 'nunjucks'
filters = require './lib/filters'
utils = require './lib/utils'
cp = require 'child_process'

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

getProjectNamed = (name) ->
  app.projects.filter((p) -> p.name is req.params.name)[0]

app.get '/', (req, res) ->
  res.render 'home.html'

app.get '/popup', (req, res) ->
  res.render 'popup/home.html', projects: app.projects

app.get '/favicon/:name', (req, res) ->
  project = getProjectNamed req.params.name
  res.sendfile project.favicon

app.on 'restart', (data) ->
  log.info "restart signal received for #{data.name}"
  getProjectNamed(data.name).restart()

app.on 'open', (data) ->
  cp.exec "open http://#{data.name}.dev"

module.exports = app
