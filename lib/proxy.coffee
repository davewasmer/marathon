httpProxy = require 'http-proxy'
log = require 'custom-logger'

proxy = new httpProxy.RoutingProxy()

module.exports = (getProjectNamed) ->
  (req, res, next) ->

    log.info "request inbound"

    # find the matching project from the host header
    domain = req.headers.host.split('.')
    domain.pop()
    domain = domain.join('.')
    project = getProjectNamed domain

    log.info "requesting #{domain} project"

    if project?
      if project.status == 'started'
        log.info "project exists!"
        buffer = httpProxy.buffer req
        proxy.proxyRequest req, res,
          host: 'localhost'
          port: project.port
          buffer: buffer
      else if project.status == 'starting'
        res.send 'Server Starting...'

      else
        res.send 'Server off'

    else

      next()