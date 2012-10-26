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
  for project, index in projects
    if not project.name in updatedProjects
      project.destroy()
      projects[index] = null
  # Remove destroyed servers from the list
  projects = projects.filter (p) -> p is null

  # Spin up servers for new projects
  projectNames = (p.name for p in projects)
  for name in updatedProjects
    if not name in projectNames
      newbie = new Project name: name, events:
      newbie.start()
      newbie.on '*', ->
        messenger.emit this.event,
          args: arguments.slice(0),
          project: newbie
      projects.push newbie


# Start watching for project changes
projects = []
messenger = new EventEmitter()
update()
setInterval update, 1000

# Start the web server
web = http.createServer(require './web/server').listen config.web.port
web.listenOn messenger

# Start the DNS server
dns = (new require './dns/server').listen config.dns.port

