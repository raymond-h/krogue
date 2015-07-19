blessed = require 'blessed'
program = blessed.program()

Renderer = require './renderer'
Effects = require './effects'
Prompts = require './prompts'

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
		@prompts = new Prompts @game
		@saveData = require './save-data'

	deinitialize: ->
		program.clear()
		program.normalBuffer()