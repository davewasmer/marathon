(function() {
  var p, socket, updateScroll, updateStatus, _fn, _i, _len, _ref;

  socket = io.connect('http://localhost');

  updateScroll = function($log) {
    return $log.parent().scrollTop($log.outerHeight());
  };

  updateStatus = function(name, status) {
    var $project, $status, symbol;
    $project = $(".project[data-name='" + name + "']");
    $status = $project.find(".status");
    $status.removeClass("success warning error busy");
    switch (status) {
      case "starting":
      case "stopping":
        $status.addClass("warning");
        symbol = "refresh";
        break;
      case "started":
        $status.addClass("success");
        symbol = "ok";
        break;
      case "stopped":
        $status.addClass("error");
        symbol = "off";
        break;
      default:
        symbol = "remove";
    }
    return $status.html("<i class='icon icon-white icon-" + symbol + "'></i> <span class='text'>" + status + "</span>");
  };

  $(".project").on('click', function(e) {
    var $log;
    if (!$(e.target).closest('.control').length > 0) {
      if ($(e.currentTarget).is('.active')) {
        return $(this).removeClass('active').find(".console").slideUp('fast');
      } else {
        $(this).addClass('active');
        $log = $(this).find(".console").slideDown('fast').find(".log");
        return updateScroll($log);
      }
    }
  });

  _ref = window.projects;
  _fn = function(p) {
    $.get("/" + p + "/log", function(result) {
      result = result.replace(new RegExp('\n', 'g'), '<br>');
      return $(".project[data-name='" + p + "']").next().find(".log").html(result);
    });
    return $.get("/" + p + "/status", function(result) {
      return updateStatus(p, result);
    });
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    p = _ref[_i];
    _fn(p);
  }

  $(".restart").click(function() {
    var name;
    name = $(this).closest(".project").data('name');
    return socket.emit('restart', {
      name: name
    });
  });

  $(".edit").click(function() {
    var name;
    name = $(this).closest(".project").data('name');
    return socket.emit('edit', {
      name: name
    });
  });

  $(".browse").click(function() {
    var name;
    name = $(this).closest(".project").data('name');
    return socket.emit('browse', {
      name: name
    });
  });

  $(".view").click(function() {
    var name;
    name = $(this).closest(".project").data('name');
    return socket.emit('view', {
      name: name
    });
  });

  socket.on('stopping', function(d) {
    console.log("stopping");
    return updateStatus(d.project, 'stopping');
  });

  socket.on('starting', function(d) {
    console.log("starting");
    return updateStatus(d.project, 'starting');
  });

  socket.on('started', function(d) {
    console.log("started");
    return updateStatus(d.project, 'started');
  });

  socket.on('stopped', function(d) {
    console.log("stopped");
    return updateStatus(d.project, 'stopped');
  });

  socket.on('dead', function(d) {
    console.log("dead");
    return updateStatus(d.project, 'dead');
  });

  socket.on('log', function(d) {
    var $log, $project, span;
    $project = $(".project[data-name='" + d.project + "']");
    d.message = d.message.replace(new RegExp('\n', 'g'), '<br>');
    span = "<span class='" + (d.type || 'info') + "'>" + d.message + "</span>";
    $log = $project.find('.console .log');
    $log.append(span);
    return updateScroll($log);
  });

  socket.on('project:added', function(d) {
    return window.location = window.location;
  });

  socket.on('project:removed', function(d) {
    return window.location = window.location;
  });

}).call(this);
