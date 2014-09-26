log = require '../log'

keyHandling = require './web-keyhandling'

module.exports = class Web
	constructor: (@game) ->

	initialize: ->
		handle = (a...) =>
			keyHandling.handleEvent @game, a...

		document.addEventListener 'keypress', handle
		document.addEventListener 'keydown', handle

		Renderer = require './web-renderer'
		@renderer = new Renderer @game

		@game.on 'action.toggle-graphics', =>
			@renderer.useTiles = not @renderer.useTiles
			@renderer.invalidate()

	deinitialize: ->