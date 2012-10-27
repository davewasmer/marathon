socket = io.connect 'http://localhost'

updateScroll = ($log) ->
  $log.parent().scrollTop $log.outerHeight()

updateStatus = (name, status) ->
  $project = $(".project[data-name=#{name}]")
  $status = $project.find(".status")
  $status.removeClass("success warning error busy")
  switch status
    when "starting", "stopping"
      $status.addClass("warning")
      symbol = "refresh"
    when "started"
      $status.addClass("success")
      symbol = "ok"
    when "stopped"
      $status.addClass("error")
      symbol = "off"
    else
      symbol = "remove"
  $status.html "<i class='icon icon-white icon-#{symbol}'></i> <span class='text'>#{status}</span>"

$(".project").on 'click', (e) ->
  if not $(e.target).closest('.control').length > 0
    if $(e.currentTarget).is('.active')
      $(@).removeClass('active').next().slideUp('fast')
    else
      $(@).addClass('active')
      $log = $(@).next().slideDown('fast').find(".log")
      updateScroll $log

for p in window.projects
  do (p) ->
    $.get "/#{p}/log", (result) ->
      result = result.replace(new RegExp('\n', 'g'), '<br>')
      $(".project[data-name=#{p}]").next().find(".log").html result
    $.get "/#{p}/status", (result) ->
      updateStatus p, result


$(".restart").click ->
  name = $(@).closest(".project").data 'name'
  socket.emit 'restart', name: name

$(".edit").click ->
  name = $(@).closest(".project").data 'name'
  socket.emit 'edit', name: name

$(".browse").click ->
  name = $(@).closest(".project").data 'name'
  socket.emit 'browse', name: name

socket.on 'stopping', (d) ->
  console.log "stopping"
  updateStatus d.project, 'stopping'

socket.on 'starting', (d) ->
  console.log "starting"
  updateStatus d.project, 'starting'

socket.on 'started', (d) ->
  console.log "started"
  updateStatus d.project, 'started'

socket.on 'stopped', (d) ->
  console.log "stopped"
  updateStatus d.project, 'stopped'

socket.on 'dead', (d) ->
  console.log "dead"
  updateStatus d.project, 'dead'

socket.on 'log', (d) ->
  $project = $(".project[data-name=#{d.project}]")
  d.message = d.message.replace(new RegExp('\n', 'g'), '<br>')
  span = "<span class='#{d.type or 'info'}'>#{d.message}</span>"
  $log = $project.next().find('.log')
  $log.append span
  updateScroll $log


socket.on 'project:added', (d) ->
  window.location = window.location

socket.on 'project:removed', (d) ->
  window.location = window.location