Q = require 'q'
argv = (require 'yargs').argv

log = require './log'

Q.longStackSupport = yes

process.on 'uncaughtException', (err) ->
	log.error 'Uncaught exception:', err.stack

	Q.delay(1000).then ->
		process.exit 1

logLevel = argv.log ? 'info'

Tty = require './io/tty'
game = require './game'

tty = new Tty game

tty.initializeLog logLevel
log "Using log level #{logLevel}"

game.initialize tty
game.main()