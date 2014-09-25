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

	deinitialize: ->

# module.exports =
# 	initialize: initialize
# 	deinitialize: deinitialize

# 	Renderer: WebRenderer