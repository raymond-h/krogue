winston = require 'winston'
util = require 'util'

winston
	.remove winston.transports.Console
	.add winston.transports.File,
		level: 'silly'
		filename: 'output.log'
		json: no

exports.log = (level, params...) ->
	winston.log level, params...