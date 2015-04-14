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
proxy = require '../lib/proxy'
cp = require 'child_process'


app = utils.patchApp express()

getProjectNamed = (name) ->
  app.projects.filter((p) -> p.name is name)[0]

app.configure ->

  # check inbound requests, and proxy to project server if one is available
  app.use proxy(getProjectNamed)

  app.use (req, res, next) ->
    # render the marathon UI page
    if req.host is "marathon.#{config.tld}" or req.host == 'localhost'
      next()
    # render project 404
    else
      res.render 'project-not-found.html', name: req.host

  app.use express.errorHandler()
  app.use less
    src: path.join(__dirname, 'public')
    force: true
  app.use coffeescript
    src: 'coffeescripts'
    dest: 'javascripts'
    baseDir: 'web/public'
    bare: false

  # setup templating
  env = new nunjucks.Environment(new nunjucks.FileSystemLoader('web/views'))
  env.express(app)
  filters.registerFilters(env)

  # usual express / connect middleware
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.static(__dirname + '/public')
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
  log.info "restarting #{data.name}"
  project = getProjectNamed(data.name)
  project.restart()

app.on 'stop', (data) ->
  log.info "stopping #{data.name}"
  project = getProjectNamed(data.name)
  project.stop()

app.on 'start', (data) ->
  log.info "starting #{data.name}"
  project = getProjectNamed(data.name)
  project.start()

app.on 'browse', (data) ->
  log.info "browsing #{data.name}"
  project = getProjectNamed(data.name)
  cp.exec "open #{project.path}"

app.on 'view', (data) ->
  log.info "viewing #{data.name}"
  project = getProjectNamed(data.name)
  cp.exec "open http://#{data.name}.#{config.tld}"

app.on 'edit', (data) ->
  project = getProjectNamed(data.name)
  log.info "editing #{data.name}"
  cp.exec "#{config.actions.editcmd} #{project.path}"



module.exports = app
