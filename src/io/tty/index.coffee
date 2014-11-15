blessed = require 'blessed'
program = blessed.program()

log = require '../../log'

module.exports = class Tty
	constructor: (@game) ->

	initialize: ->
		program.reset()
		program.alternateBuffer()

		program.on 'keypress', (ch, key) =>
			@game.emit "key.#{key.name}", ch, key

		Renderer = require './renderer'
		@renderer = new Renderer @game

		@prompts = require './prompts'

	deinitialize: ->
		program.clear()
		program.normalBuffer()