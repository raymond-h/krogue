Q = require 'q'
Q.longStackTraces = yes

log = require '../log'

logLevel = 'info'

$ ->
	Web = require '../io/web'
	game = require '../game'

	web = new Web game

	web.initializeLog logLevel
	log "Using log level #{logLevel}"

	game.initialize web
	game.main()