blessed = require 'blessed'
program = blessed.program()

wordwrap = require 'wordwrap'
_ = require 'lodash'

winston = require 'winston'

program.fillArea = (x, y, w, h, c) ->
	str = (new Array w+1).join c
	program.move x, y
	(program.write str; program.down()) while h-- > 0

initialize = (game) ->
	program.reset()
	program.alternateBuffer()

	program.on 'keypress', (ch, key) ->
		game.emit "key.#{key.name}", ch, key

deinitialize = (game) ->
	program.clear()
	program.normalBuffer()

repeat = (str, n) -> (new Array n+1).join str

class TtyRenderer
	@strMore = ' [more]'

	constructor: (@game) ->
		@invalidated = no

		@invalidate() # initial render

		@logs = []
		@pendingLogs = []

		@logWidth = 60 - TtyRenderer.strMore.length

		@game
		.on 'turn.player', => @showMoreLogs()

		.on 'log.add', (str) => @pendingLogs.push str

		@wrap = wordwrap.hard @logWidth

	hasMoreLogs: ->
		@logs.length > 1

	showMoreLogs: ->
		if @hasMoreLogs() then @logs.shift()

		else
			@logs = @wrap(@pendingLogs.join ' ').split /(?:\r?\n|\r)/
			@pendingLogs = []
		
		@invalidate()

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextTick =>
				@invalidated = no

				@render()

	showList: (@menu) ->
		@invalidate()

	render: ->
		# program.clear()

		switch @game.state
			when 'game'
				@renderLog 0, 0
				@renderMap 0, 1
				@renderMenu @menu if @menu?

				@renderHealth 0, 22

			else null

	renderLog: (x, y) ->
		program.fillArea x, y, 60, 1, ' '

		if @logs.length > 0
			program.move x, y
			program.write @logs[0]

			if @hasMoreLogs()
				program.write TtyRenderer.strMore

	renderMenu: (menu) ->
		x = menu.x ? 0
		y = menu.y ? 1
		width = menu.width
		if not width?
			width = Math.max (i.length for i in menu.items)...
			width = Math.max menu.header.length, width
			width += 2

		delimiter = (repeat '-', width-2)
		rows = [delimiter, menu.header, delimiter, menu.items..., delimiter]

		height = menu.height ? rows.length

		for row, i in rows
			program.move x, y+i
			program.write '|'
			program.write row
			program.write repeat ' ', (width - row.length - 2)
			program.write '|'

	renderMap: (x, y) ->
		c = @game.camera
		map = @game.currentMap

		for cy in [0...c.viewport.h]
			program.move x, y+cy
			sy = c.y + cy
			row = map.data[sy]
			
			# to only get the part that's on-screen
			# we slice from left to right edge of viewport
			row = row[c.x ... c.x+c.viewport.w]

			program.write row.join ''

		entityLayer =
			'creature': 3
			'item': 2
			'stairs': 1

		entities = map.entities[..].sort (a, b) ->
			entityLayer[a.type] - entityLayer[b.type]

		@renderEntities x, y, entities

	renderEntities: (x, y, entities) ->
		c = @game.camera

		for e in entities
			if (c.x <= e.x < c.x+c.viewport.w) and (c.y <= e.y < c.y+c.viewport.h)
				program.pos (e.y - c.y + y), (e.x - c.x + x)
				program.write _.result e, 'symbol'

	renderHealth: (x, y) ->
		program.fillArea x, y, 40, 2, ' '
		health = @game.player.creature.health

		@renderRatio x, y, health, ' health'
		@renderBar x, y+1, 40, health

	renderRatio: (x, y, {min, current, max}, suffix = '') ->
		min ?= 0

		program.move x, y
		if min is 0
			program.write "#{current} / #{max}#{suffix}"
		else
			program.write "#{min} <= #{current} <= #{max}#{suffix}"

	renderBar: (x, y, w, {min, current, max}) ->
		min ?= 0
		fullWidth = w - 2 # width excluding []s on the ends
		currentWidth = Math.floor (current - min) / (max - min) * fullWidth
		restWidth = fullWidth - currentWidth

		program.move x, y
		program.write '['
		program.write repeat '=', currentWidth
		program.write repeat ' ', restWidth
		program.write ']'

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: TtyRenderer