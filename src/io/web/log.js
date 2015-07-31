var error, log,
  slice = [].slice;

log = function() {
  var params;
  params = 1 <= arguments.length ? slice.call(arguments, 0) : [];
  return console.log.apply(console, params);
};

error = function() {
  var params;
  params = 1 <= arguments.length ? slice.call(arguments, 0) : [];
  return console.error.apply(console, params);
};

exports.log = function() {
  var level, llog, params;
  level = arguments[0], params = 2 <= arguments.length ? slice.call(arguments, 1) : [];
  llog = level === 'error' ? error : log;
  return llog.apply(null, [level + ":"].concat(slice.call(params)));
};
