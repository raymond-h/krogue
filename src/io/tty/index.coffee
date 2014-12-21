blessed = require 'blessed'
program = blessed.program()

Renderer = require './renderer'
Effects = require './effects'

module.exports = class Tty
	constructor: (@game) ->

	initializeLog: (logLevel) ->
		(require '../../log').initialize logLevel, require './log'

	initialize: ->
		program.reset()
		program.alternateBuffer()

		program.on 'keypress', (ch, key) =>
			@game.emit "key.#{key.name}", ch, key

		@renderer = new Renderer @, @game
		@effects = new Effects @
		@prompts = require './prompts'

	deinitialize: ->
		program.clear()
		program.normalBuffer()