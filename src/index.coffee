(require 'q').longStackSupport = yes
argv = (require 'yargs').argv

log = require './log'

log.level = argv.log ? 'info'
log "Using log level #{argv.log ? 'info'}"

process.on 'uncaughtException', (err) ->
	log.error 'Uncaught exception:', err.stack
	(require 'q').delay(100).then -> process.exit 1

game = require './game'

game.initialize require './io/tty'
game.main()