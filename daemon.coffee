log = require('custom-logger')
cc = require 'config-chain'
File = require('oofile').File
config = require('./lib/config')
EventEmitter = require('eventemitter2').EventEmitter2

# Check the watch directory for project changes
# Shut down removed projects, and spin up added ones
update = ->
  updatedProjects = config.projects.path.ls()

  # Spin down removed servers and drop them from the list
  for p, index in currentProjects
    if not p.name in updatedProjects
      p.destroy()
      messenger.emit "project:removed", p: project
      currentProjects[index] = null

  # Remove destroyed servers from the list
  currentProjects = currentProjects.filter (p) -> p is null

  ## Spin up servers for new projects
  projectNames = (p.name for p in currentProjects)
  for name in updatedProjects

    # if there is a new project not on the list,
    # create one, pipe it's events, and add it to
    # the list
    if not name in projectNames
      newbie = new Project name: name, events:
      newbie.start()
      newbie.on '*', ->
        messenger.emit this.event,
          args: arguments.slice(0),
          project: newbie
      currentProjects.push newbie
      messenger.emit "project:added", project: newbie


# Start watching for project changes
projects = []
messenger = new EventEmitter()
update()
setInterval update, 1000

# Start the web server
web = http.createServer(require './web/server').listen config.web.port
web.listenOn messenger
web.projects = projects

# Start the DNS server
dns = (new require './dns/server').listen config.dns.port

