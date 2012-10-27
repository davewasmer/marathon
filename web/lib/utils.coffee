socketio = require 'socket.io'
EventEmitter = require('eventemitter2').EventEmitter2

msg = new EventEmitter()
eventsToListenFor = []

exports.patchApp = (app) ->

  # convenience function for mounting express routes
  app.mount = (name) ->
    routes = require "../routes/#{name}"
    routes.mount(app)

  app.sockets = {}

  app.startSocket = (server) ->
    io = socketio.listen server
    io.set 'log level', 0
    io.sockets.on 'connection', (s) ->
      app.sockets[s.id] = s
      count = 0
      count += 1 for key, value of app.sockets
      console.log count
      s.on 'disconnect', ->
        s.removeAllListeners()
        delete app.sockets[s.id]
      for event in eventsToListenFor
        do (event) ->
          s.on event, (data) ->
            msg.emit event, data

  app.on = (event, callback) ->
    eventsToListenFor.push event
    msg.on event, callback

  # if no connection is ready yet, buffer the message
  # otherwise, shortcut to emit a socket message
  app.emit = (event, data) ->
    for id, s of app.sockets
      s.emit event, data

  app