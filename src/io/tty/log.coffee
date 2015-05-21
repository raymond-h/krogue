winston = require 'winston'
util = require 'util'

winston
	.remove winston.transports.Console
	.add winston.transports.File,
		level: 'silly'
		filename: 'output.log'
		json: no

exports.log = (level, params...) ->
	if params[0] instanceof Error
		winston.log level, params[0], params[1..]...

	else winston.log level, (params.map util.inspect)...