http = require('http')
log = require('custom-logger')
File = require('oofile').File
EventEmitter = require('eventemitter2').EventEmitter2
config = require('./lib/config')
Project = require('./lib/project')


projects = []

# Start the web server
web = require './web/server'
webserver = http.createServer(web).listen config.web.port
log.info "web server listening on port #{config.web.port}"
web.startSocket webserver

# Start the DNS server
dns = require './dns/server'
dnsserver = (new dns()).listen config.dns.port
log.info "dns server listening on port #{config.dns.port}"


# Find the lowest open port based on currently running projects
# and the configuration settings
getNextAvailablePort = ->
  usedPorts = (p.port for p in projects when p.status isnt "starting" or p.status isnt "started")
  start = config.projects.lowestPort
  end = start + config.projects.max
  for i in [start ... end]
    if not (i in usedPorts)
      return i

# Check the watch directory for project changes
# Shut down removed projects, and spin up added ones
update = ->
  updatedProjects = config.projects.path.ls()

  # Spin down removed servers and drop them from the list
  for p, index in projects
    if not (p.name in updatedProjects)
      p.destroy()
      web.emit "project:removed", p: p.name
      projects[index] = null

  # Remove destroyed servers from the list
  projects = projects.filter (p) -> p isnt null

  ## Spin up servers for new projects
  projectNames = (p.name for p in projects)
  projectNames.push 'logs'
  for name in updatedProjects

    # if there is a new project not on the list,
    # create one, pipe it's events, and add it to
    # the list
    if not (name in projectNames)
      newbie = new Project name: name
      do (newbie) ->
        newbie.start(port: getNextAvailablePort())
        newbie.onAny (data = {})->
          data.project = newbie.name
          web.emit this.event, data
        projects.push newbie
        web.emit "project:added", project: newbie.name

  web.projects = projects


# On a SIGINT, after all the projects clean themselves up,
# exit the process
exitAfterCleanup = (count = 0)->
  done = true
  for p in projects
    if p.status isnt "dead"
      done = false
      # p.destroy()
      break
  if done
    process.exit()
  else if count > 10
    console.log 'Tried to stop servers for too long. Exiting anyways.'
    process.exit()
  else
    setTimeout ()->
      exitAfterCleanup(++count)
    , 200

process.on 'SIGINT', exitAfterCleanup


# If there is an error in marathon itself, clean up child processes
# before crashing
process.on 'uncaughtException', (err) ->
  log.error err.toString()
  console.trace("Uncaught Exception!")
  p.destroy() for p in projects
  exitAfterCleanup()


# Start watching for project changes
update()
setInterval update, 1000

