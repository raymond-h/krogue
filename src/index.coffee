Q = require 'q'
argv = (require 'yargs').argv

log = require './log'

Q.longStackSupport = yes

process.on 'uncaughtException', (err) ->
	log.error 'Uncaught exception:', err.stack

	Q.delay(1000).then ->
		process.exit 1

logLevel = argv.log ? 'info'
log.initialize logLevel, require './io/tty-log'

log "Using log level #{logLevel}"

game = require './game'

game.initialize require './io/tty'
game.main()