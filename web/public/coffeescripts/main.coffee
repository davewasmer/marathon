socket = io.connect 'http://localhost'

$(".restart").click ->
  name = $(@).data 'name'
  socket.emit 'restart', name: name

$(".project").click ->
  name = $(@).data 'name'
  socket.emit 'open', name: name