socketio = require 'socket.io'

buffer = []

exports.patchApp = (app) ->

  # convenience function for mounting express routes
  app.mount = (name) ->
    routes = require "../routes/#{name}"
    routes.mount(app)

  # take the supplied event emitter, and pipe the events
  # to the socket io connection
  app.listenTo = (m) ->
    app.projectMessenger = m

  # start the socketio server, and run buffered emits on
  # connection
  app.startSocket = (server) ->
    io = socketio.listen server
    io.set 'log level', 1
    io.sockets.on 'connection', (s) ->
      socket = s
      fn() for fn in buffer

  # if no connection is ready yet, buffer the listener
  # otherwise, shortcut to add a socket listener
  app.on = () ->
    if app.socket?
      app.socket.on.apply app.socket, arguments
    else
      args = arguments
      buffer.push () ->
        app.socket.on.apply app.socket, args

  # if no connection is ready yet, buffer the message
  # otherwise, shortcut to emit a socket message
  app.emit = () ->
    if app.socket?
      app.socket.emit.apply app.socket, arguments
    else
      args = arguments
      buffer.push () ->
        app.socket.emit.apply app.socket, args

  app