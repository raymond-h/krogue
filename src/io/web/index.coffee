log = require '../log'

keyHandling = require './keyhandling'

module.exports = class Web
	constructor: (@game) ->

	initialize: ->
		handle = (a...) =>
			keyHandling.handleEvent @game, a...

		$(document).keypress handle
		$(document).keydown handle

		Renderer = require './renderer'
		@renderer = new Renderer @game

		@prompts = require './prompts'

		@game.on 'action.toggle-graphics', =>
			@renderer.useTiles = not @renderer.useTiles
			@renderer.invalidate()

	deinitialize: ->