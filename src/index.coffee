(require 'q').longStackSupport = yes
argv = (require 'yargs').argv

winston = require 'winston'

winston
	.remove winston.transports.Console
	.add winston.transports.File,
		level: argv.log ? 'info'
		filename: 'output.log'
		json: no

process.on 'uncaughtException', (err) ->
	winston.error 'Uncaught exception:', err.stack
	(require 'q').delay(100).then -> process.exit 1

winston.info "Using log level #{argv.log ? 'info'}"

game = require './game'

game.initialize require './io/tty'
game.main()