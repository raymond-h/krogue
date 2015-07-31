var exports, fn, initialize, levels, logImpl, logLevel, name,
  slice = [].slice;

logImpl = null;

logLevel = null;

levels = {
  silly: -Infinity,
  verbose: 0,
  info: 1,
  error: Infinity
};

initialize = function(level, logModule) {
  logLevel = level;
  return logImpl = logModule;
};

module.exports = exports = function() {
  var out;
  out = 1 <= arguments.length ? slice.call(arguments, 0) : [];
  return exports.level.apply(exports, ['info'].concat(slice.call(out)));
};

fn = function(name) {
  return exports[name[0]] = exports[name] = function() {
    var out;
    out = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return exports.level.apply(exports, [name].concat(slice.call(out)));
  };
};
for (name in levels) {
  fn(name);
}

exports.level = function() {
  var level, out;
  level = arguments[0], out = 2 <= arguments.length ? slice.call(arguments, 1) : [];
  if (levels[level != null ? level : 'error'] >= levels[logLevel]) {
    return logImpl.log.apply(logImpl, [level].concat(slice.call(out)));
  }
};

exports.initialize = initialize;

exports.levels = levels;
