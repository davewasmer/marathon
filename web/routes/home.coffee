
home = (req, res) ->
  res.render 'home.html'


exports.mount = (app) ->

  app.get '/', home