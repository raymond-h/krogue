blessed = require 'blessed'
program = blessed.program()

# winston = require 'winston'

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

		@logs = []
		@logWidth = 60

		@game.events
		.on 'turn.player', @proceedShownLog
		.on 'log.show-more', @proceedShownLog

	proceedShownLog: =>
		@logs = []

		screenFull = =>
			len = @game.pendingLogs[0]
			len += l.length + 1 for l in @logs
			len >= @logWidth

		while @game.pendingLogs.length > 0 and not screenFull()
			@logs.push @game.pendingLogs.shift()
			@invalidate()

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextTick =>
				@invalidated = no

				@render()

	render: ->
		program.clear()

		switch @game.state
			when 'game'
				if @logs.length > 0
					program.move 0, 0
					program.write @logs.join ' '

					program.write ' --More--' if @game.pendingLogs.length > 0

				c = @game.camera

				program.move 0, 1

				for cy in [0...c.viewport.h]
					y = c.y + cy
					row = @game.currentMap.data[y]
					
					# to only get the part that's on-screen
					# we slice from left to right edge of viewport
					row = row[c.x ... c.x+c.viewport.w]

					program.write row.join ''
					program.feed()

				for e in @game.currentMap.entities
					if c.x <= e.x < c.x+c.viewport.w and
							c.y <= e.y < c.y+c.viewport.h

						program.pos e.y-c.y, e.x-c.x
						program.down 1
						program.write e.symbol

			else null

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: TtyRenderer