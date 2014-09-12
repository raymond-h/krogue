(require 'q').longStackSupport = yes
argv = (require 'yargs').argv

log = require './log'

logLevel = argv.log ? 'info'
log.initialize logLevel, require './io/tty-log'

log "Using log level #{logLevel}"

process.on 'uncaughtException', (err) ->
	log.error 'Uncaught exception:', err.stack
	(require 'q').delay(100).then -> process.exit 1

game = require './game'

game.initialize require './io/tty'
game.main()