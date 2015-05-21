Promise = require 'bluebird'
Promise.longStackTraces()

argv = (require 'yargs').argv

log = require './log'

process.on 'uncaughtException', (err) ->
	log.error 'Uncaught exception:', err.stack

	setTimeout (->
		process.exit 1
	), 1000

logLevel = argv.log ? 'info'

Tty = require './io/tty'
game = require './game'

tty = new Tty game

tty.initializeLog logLevel
log "Using log level #{logLevel}"

game.initialize tty
game.main()