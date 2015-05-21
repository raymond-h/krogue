Promise = require 'bluebird'
Promise.longStackTraces()

argv = (require 'yargs').argv

log = require './log'

errorHandler = (err) ->
	log.error 'Uncaught exception:', err.stack

	setTimeout (->
		process.exit 1
	), 1000

process.on 'uncaughtException', errorHandler
process.on 'unhandledRejection', errorHandler

logLevel = argv.log ? 'info'

Tty = require './io/tty'
game = require './game'

tty = new Tty game

tty.initializeLog logLevel
log "Using log level #{logLevel}"

game.initialize tty
game.main()