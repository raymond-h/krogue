log = require '../log'

viewport = null

initialize = (game) ->
	canvas = document.getElementById 'viewport'
	viewport = canvas.getContext '2d'

deinitialize = (game) ->
	viewport = null

class WebRenderer
	constructor: (@game) ->
		@invalidated = no

		@invalidate() # initial render

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextTick =>
				@invalidated = no

				@render()

	render: ->
		viewport.fillStyle = '#000000'
		viewport.fillRect(0, 0, 80*8, 25*8)

		switch @game.state
			when 'game'
				# @renderLog 0, 0
				@renderMap 0, 0
				# @renderMenu @menu if @menu?

				# @renderHealth 0, 22

			else null

	renderMap: (x, y) ->
		c = @game.camera
		map = @game.currentMap

		# for cy in [0...c.viewport.h]
		# 	sy = c.y + cy
		# 	row = map.data[sy]
			
			# to only get the part that's on-screen
			# we slice from left to right edge of viewport
			# row = row[c.x ... c.x+c.viewport.w]
			# row = for t, tx in row[c.x ... c.x+c.viewport.w]
			# 	if c.target.canSee {x: (c.x + tx), y: (c.y + cy)}
			# 		t
			# 	else ' '

		log 'Hello world! Render time!'

		for cx in [0...map.w]
			for cy in [0...map.h]
				viewport.fillStyle = '#ff0000'
				viewport.fillRect x + cx * 8, y + cy * 8, 8, 8
		log 'Done rendering!!'

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: WebRenderer