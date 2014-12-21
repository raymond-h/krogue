keyHandling = require './keyhandling'
Renderer = require './renderer'
Effects = require './effects'

module.exports = class Web
	constructor: (@game) ->

	initializeLog: (logLevel) ->
		(require '../../log').initialize logLevel, require './log'

	initialize: ->
		handle = (a...) =>
			keyHandling.handleEvent @game, a...

		$(document).keypress handle
		$(document).keydown handle

		@renderer = new Renderer @, @game
		@effects = new Effects @
		@prompts = require './prompts'

		@game.on 'action.toggle-graphics', =>
			@renderer.useTiles = not @renderer.useTiles
			@renderer.invalidate()

	deinitialize: ->