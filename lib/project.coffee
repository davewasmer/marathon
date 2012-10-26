log = require('custom-logger')
EventEmitter = require('eventemitter2').EventEmitter2
File = require('oofile').File
uuid = require('node-uuid').v4
config = require('./config')

module.exports = class Project extends EventEmitter

  status: "off"

  constructor: (options) ->
    @id = uuid()
    @name = options.name
    @path = config.projects.path(@name)
    @favicon = @findFavicon()
    @package = @path('package.json').contents()

  findFavicon: ->
    favicon = @path.find('**/favicon.*')[0]
    if favicon?
      return favicon.toString()
    else
      return config.web.path "public/images/default-favicon.png"

  start: (options) ->
    if @status is "on" or @status is "starting"
      @emit "warning", message: "Already running!"
    else
      @emit "starting"
      @status = "starting"

      command = @package.scripts.start.split ' '
      env = @getEnv port: options.port

      @process = cp.spawn command.shift(), cmd, cwd: @path.toString(), env: env
      @process.stdout.on 'data', (d) =>
        if @status is "starting"
          @status = "on"
          @emit "started"
        @emit 'out:data', d
      @process.stderr.on 'data', (d) => @emit 'err:data', d
      @process.on 'exit', (code, signal) =>
        @emit 'exit', code: code, signal: signal

  getEnv: (options) ->
    @port = options.port if options.port?
    env = {}
    env[key] = value for key, value of process.env
    env[key.toUpperCase()] = value for key, value of options
    return env
