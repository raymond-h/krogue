blessed = require 'blessed'
program = blessed.program()

log = require '../log'

initialize = (game) ->
	program.reset()
	program.alternateBuffer()

	program.on 'keypress', (ch, key) ->
		game.emit "key.#{key.name}", ch, key

deinitialize = (game) ->
	program.clear()
	program.normalBuffer()

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: require './tty-renderer'