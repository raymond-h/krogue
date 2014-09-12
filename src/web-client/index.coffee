log = require '../log'

logLevel = 'silly'
log.initialize logLevel, require '../io/web-log'

log "Using log level #{logLevel}"

document.addEventListener 'DOMContentLoaded', ->
	game = require '../game'

	game.initialize require '../io/web'
	game.main()