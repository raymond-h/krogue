winston = require 'winston'

winston
	.remove winston.transports.Console
	.add winston.transports.File,
		level: argv.log ? 'info'
		filename: 'output.log'
		json: no

exports.log = (level, params...) ->
	winston.log level, params...

exports.error = (params...) ->
	winston.error params...