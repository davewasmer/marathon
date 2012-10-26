log = require('custom-logger')
EventEmitter = require('eventemitter2').EventEmitter2
File = require('oofile').File
uuid = require('node-uuid').v4
config = require('./config')

module.exports = class Project extends EventEmitter

  status: "stopped"

  constructor: (options) ->
    @id = uuid()
    @name = options.name
    @path = config.projects.path(@name)
    @favicon = @findFavicon()
    @package = @path('package.json').contents()
    process.on 'SIGINT', @stop

  findFavicon: ->
    favicon = @path.find('**/favicon.*')[0]
    if favicon?
      return favicon.toString()
    else
      return config.web.path "public/images/default-favicon.png"

  start: (options) ->
    if @status is "started" or @status is "starting"
      @emit "warning", message: "Already running!"
    else
      # begin startup
      @emit "starting"
      @status = "starting"

      # get the startup command and configure the env
      command = @package.scripts.start.split ' '
      env = @getEnv port: options.port

      # spawn the process
      @process = cp.spawn command.shift(), cmd, cwd: @path.toString(), env: env

      # pipe data events
      @process.stdout.on 'data', (d) =>
        if @status is "starting"
          @status = "on"
          @emit "started"
        @emit 'out:data', d
      @process.stderr.on 'data', (d) => @emit 'err:data', d

      # on exit, update status and pipe the event
      @process.on 'exit', (code, signal) =>
        @status = "stopped"
        @emit 'stopped', code: code, signal: signal

  # shut down the server
  stop: =>
    @emit 'stopping'
    @process.kill()

  # restart the server
  restart: =>
    @emit 'restarting'
    @process.on 'exit', => @start port: @port
    @stop()

  # shut down the server and clean up event listeners to destroy
  # the reference to this project
  destroy: =>
    @stop()
    process.removeListener 'SIGINT', @stop

  # merge the current process env to the child process, plus any additional
  # options; also, update the port property
  getEnv: (options) ->
    @port = options.port if options.port?
    env = {}
    env[key] = value for key, value of process.env
    env[key.toUpperCase()] = value for key, value of options
    return env
