blessed = require 'blessed'
program = blessed.program()

program.reset = ->
	program._write '\x1bc'

initialize = (game) ->
	program.reset()
	program.alternateBuffer()

	program.on 'keypress', (ch, key) ->
		game.events.emit "key.#{key.name}", ch, key

deinitialize = (game) ->
	program.clear()
	program.normalBuffer()

class TtyRenderer
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

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: TtyRenderer