exports.patchApp = (app) ->
  app.mount = (name) ->
    routes = require "../routes/#{name}"
    routes.mount(app)
  app