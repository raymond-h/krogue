log = require '../log'

logLevel = 'silly'
log.initialize logLevel, require '../io/web-log'

log "Using log level #{logLevel}"

document.addEventListener 'DOMContentLoaded', ->
	Web = require '../io/web'
	game = require '../game'

	web = new Web game
	game.initialize web
	game.main()