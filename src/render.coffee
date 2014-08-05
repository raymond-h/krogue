blessed = require 'blessed'
program = blessed.program()

class exports.Renderer
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
		program.clear()

		for column, x in @game.currentMap.data
			for tile, y in column
				program.pos y, x
				program.write tile

		for e in @game.entities
			program.pos e.y, e.x
			program.write e.symbol