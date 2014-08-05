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

		for row, y in @game.currentMap.data
			program.write row.join ''
			program.feed()

		for e in @game.entities
			program.pos e.y, e.x
			program.write e.symbol