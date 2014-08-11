blessed = require 'blessed'
program = blessed.program()

# winston = require 'winston'

program.fillArea = (x, y, w, h, c) ->
	str = (new Array w+1).join c
	program.move x, y
	(program.write str; program.down()) while h-- > 0

initialize = (game) ->
	program.reset()
	program.alternateBuffer()

	program.on 'keypress', (ch, key) ->
		game.events.emit "key.#{key.name}", ch, key

deinitialize = (game) ->
	program.clear()
	program.normalBuffer()

class TtyRenderer
	@strMore = ' [enter]'

	constructor: (@game) ->
		@invalidated = no

		@invalidate() # initial render

		@logs = []
		@pendingLogs = []
		@logWidth = 60 - TtyRenderer.strMore.length

		@game.events
		.on 'turn.player', => @showMoreLogs()
		.on 'log.add', (str) => @pendingLogs.push str

	hasMoreLogs: ->
		@pendingLogs.length > 0

	showMoreLogs: ->
		@logs = []

		screenFull = =>
			len = @pendingLogs[0].length
			(len += l.length + 1) for l in @logs
			len >= @logWidth

		while @hasMoreLogs() and not screenFull()
			@logs.push @pendingLogs.shift()
			@invalidate()

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextTick =>
				@invalidated = no

				@render()

	render: ->
		# program.clear()

		switch @game.state
			when 'game'
				@renderLog 0, 0
				@renderMap 0, 1

			else null

	renderLog: (x, y) ->
		program.fillArea x, y, 60, 1, ' '

		if @logs.length > 0
			program.move x, y
			program.write @logs.join ' '

			if @pendingLogs.length > 0
				program.write TtyRenderer.strMore

	renderMap: (x, y) ->
		c = @game.camera
		map = @game.currentMap

		program.move x, y

		for cy in [0...c.viewport.h]
			sy = c.y + cy
			row = map.data[sy]
			
			# to only get the part that's on-screen
			# we slice from left to right edge of viewport
			row = row[c.x ... c.x+c.viewport.w]

			program.write row.join ''
			program.feed()

		@renderEntities x, y

	renderEntities: (x, y) ->
		c = @game.camera

		for e in @game.currentMap.entities
			if (c.x <= e.x < c.x+c.viewport.w) and (c.y <= e.y < c.y+c.viewport.h)
				program.pos (e.y - c.y + y), (e.x - c.x + x)
				program.write e.symbol

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: TtyRenderer