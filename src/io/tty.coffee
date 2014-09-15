blessed = require 'blessed'
program = blessed.program()

parseAttrs = (graphic) ->
	attrs = []

	if graphic.color?
		attrs.push "#{graphic.color} fg"

	attrs

wordwrap = require 'wordwrap'
_ = require 'lodash'
Q = require 'q'

Camera = require '../camera'
graphics = require './graphics-ascii'
{whilst, bresenhamLine, arrayRemove, repeatStr: repeat} = require '../util'

log = require '../log'

initialize = (game) ->
	program.reset()
	program.alternateBuffer()

	program.on 'keypress', (ch, key) ->
		game.emit "key.#{key.name}", ch, key

deinitialize = (game) ->
	program.clear()
	program.normalBuffer()

class TtyRenderer
	@strMore = ' [more]'

	constructor: (@game) ->
		@invalidated = no

		blank = {symbol: ' '}
		@buffer =
			for i in [0...80*25]
				blank

		@invalidate() # initial render

		@logs = []
		@pendingLogs = []

		@logWidth = 80 - TtyRenderer.strMore.length

		@game
		.on 'turn.player', => @showMoreLogs()

		.on 'log.add', (str) => @pendingLogs.push str

		@wrap = wordwrap.hard @logWidth

		@effects = []
		@camera = new Camera { w: 80, h: 21 }, { x: 30, y: 9 }

		@saveData = require './tty-save-data'

	bufferPut: (x, y, graphic) ->
		if _.isString graphic
			graphic = symbol: graphic

		@buffer[y*80 + x] = graphic

	write: (x, y, str) ->
		for c,i in str
			@bufferPut x+i, y, c

	fillArea: (x, y, w, h, c) ->
		c = symbol: c

		for i in [0...w]
			for j in [0...h]
				@bufferPut x+i, y+j, c

	bufferToString: ->
		out = ''

		currentGraphic = {}
		lastAttrs = []
		for g,i in @buffer
			if currentGraphic isnt g and not _.isEqual currentGraphic, g
				currentGraphic = g

				out += program._attr lastAttrs, false
				lastAttrs = parseAttrs g
				out += program._attr lastAttrs, true

			out += g.symbol
			if (i % 80) is 79
				out += '\n'

		out

	flipBuffer: ->
		program.move 0, 0
		# program.clear()

		program.write @bufferToString()

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
		switch @game.state
			when 'game'
				@renderLog 0, 0
				@renderMap 0, 1
				@renderMenu @menu if @menu?

				@renderHealth 0, 22

			else null

		@flipBuffer()

	renderLog: (x, y) ->
		@fillArea x, y, 80, 1, ' '

		if @logs.length > 0
			str = @logs[0]

			if @hasMoreLogs()
				str += TtyRenderer.strMore

			@write x, y, str

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
			str = "|#{row}#{repeat ' ', (width - row.length - 2)}|"
			@write x, y+i, str

	renderMap: (x, y) ->
		c = @camera
		map = @game.currentMap

		c.target = @game.player.creature
		c.bounds map
		c.update()

		mapSymbols =
			'#': graphics.get 'wall'
			'.': graphics.get 'floor'

		graphicAt = (x, y) ->
			if c.target.canSee {x, y}
				t = map.data[y][x]
				mapSymbols[t]

			else ' '

		for sx in [0...c.viewport.w]
			for sy in [0...c.viewport.h]
				@bufferPut sx+x, sy+y, graphicAt c.x+sx, c.y+sy

		entityLayer =
			'creature': 3
			'item': 2
			'stairs': 1

		entities = map.entities[..].sort (a, b) ->
			entityLayer[a.type] - entityLayer[b.type]

		@renderEntities x, y, entities
		@renderEffects x, y

	renderEntities: (x, y, entities) ->
		c = @camera

		for e in entities when c.target.canSee e
			if (c.x <= e.x < c.x+c.viewport.w) and (c.y <= e.y < c.y+c.viewport.h)
				graphicId = _.result e, 'symbol'
				graphic = graphics.get graphicId

				@bufferPut (e.x - c.x + x), (e.y - c.y + y), graphic

	renderHealth: (x, y) ->
		@fillArea x, y, 40, 2, ' '
		health = @game.player.creature.health

		@renderRatio x, y, health, ' health'
		@renderBar x, y+1, 40, health

	renderRatio: (x, y, {min, current, max}, suffix = '') ->
		min ?= 0

		str =
			if min is 0
				"#{current} / #{max}#{suffix}"
			else
				"#{min} <= #{current} <= #{max}#{suffix}"

		@write x, y, str

	renderBar: (x, y, w, {min, current, max}) ->
		min ?= 0
		fullWidth = w - 2 # width excluding []s on the ends
		currentWidth = Math.floor (current - min) / (max - min) * fullWidth
		restWidth = fullWidth - currentWidth

		@write x, y, "[#{repeat '=', currentWidth}#{repeat ' ', restWidth}]"

	renderEffects: (x, y) ->
		c = @camera
		[ox, oy] = [x - c.x, y - c.y]

		for e in @effects
			if e.type is 'line'
				{x, y} = e.current
				@bufferPut x+ox, y+oy, graphics.get e.symbol

	doEffect: (data) ->
		Q @effects.push data

		.then =>
			switch data.type
				when 'line' then @doEffectLine data

		.then =>
			arrayRemove @effects, data
			@invalidate()

	doEffectLine: (data) ->
		{start, end, time, delay} = data

		points = bresenhamLine start, end
		
		if time? and not delay?
			delay = time / points.length

		whilst (-> points.length > 0),
			=>
				Q.fcall =>
					data.current = points.shift()
					@invalidate()

				.delay delay

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: TtyRenderer