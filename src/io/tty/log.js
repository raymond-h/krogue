var util, winston,
  slice = [].slice;

winston = require('winston');

util = require('util');

winston.remove(winston.transports.Console).add(winston.transports.File, {
  level: 'silly',
  filename: 'output.log',
  json: false
});

exports.log = function() {
  var level, params;
  level = arguments[0], params = 2 <= arguments.length ? slice.call(arguments, 1) : [];
  return winston.log.apply(winston, [level].concat(slice.call(params)));
};
