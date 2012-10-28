express = require 'express'
http = require 'http'
path = require 'path'
request = require 'request'
log = require 'custom-logger'
less = require 'less-middleware'
coffeescript = require 'connect-coffee-script'
nunjucks =  require 'nunjucks'
filters = require './lib/filters'
utils = require './lib/utils'
config = require '../lib/config'
cp = require 'child_process'

log.warn process.cwd()

app = utils.patchApp express()

getProjectNamed = (name) ->
  app.projects.filter((p) -> p.name is name)[0]

app.configure ->
  app.use express.errorHandler()
  app.use less
    src: path.join(__dirname, 'public')
    force: true
  app.use coffeescript
    src: 'coffeescripts'
    dest: 'javascripts'
    baseDir: 'web/public'
    bare: false

  # check inbound requests, and proxy to project server if one is available
  app.use (req, res, next) ->
    domain = req.headers.host.split('.')
    domain.pop()
    domain = domain.join('.')
    project = getProjectNamed domain

    if project?
      request("http://localhost:#{project.port}/#{req.path}").pipe(res)
    else
      if domain is 'marathon'
        next()
      else
        res.render 'project-not-found.html', name: domain

  # setup templating
  env = new nunjucks.Environment(new nunjucks.FileSystemLoader('web/views'))
  env.express(app)
  filters.registerFilters(env)

  # usual express / connect middleware
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.static(__dirname + '/public')
  app.use express.bodyParser()
  app.use express.methodOverride()

  # marathon admin pages
  app.use app.router



## Routes
## ---------------------------
app.get '/', (req, res) ->
  res.render 'home.html', projects: app.projects

app.get '/status', (req, res) ->
  res.send 'ok!'

app.get '/:name/favicon', (req, res) ->
  project = getProjectNamed req.params.name
  log.info project.favicon
  res.sendfile project.favicon

app.get '/:name/log', (req, res) ->
  project = getProjectNamed req.params.name
  project.tail (l) -> res.send l

app.get '/:name/status', (req, res) ->
  project = getProjectNamed req.params.name
  res.send project.status

app.on 'restart', (data) ->
  console.log "web server got request to restart #{data.name}"
  project = getProjectNamed(data.name)
  project.restart()

app.on 'browse', (data) ->
  console.log "web server got request to browse #{data.name}"
  project = getProjectNamed(data.name)
  cp.exec "open #{project.path}"

app.on 'edit', (data) ->
  project = getProjectNamed(data.name)
  console.log "web server got request to browse #{data.name}"
  cp.exec "#{config.actions.editcmd} #{project.path}"



module.exports = app
