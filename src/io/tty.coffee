blessed = require 'blessed'
program = blessed.program()

program.fillArea = (x, y, w, h, c) ->
	str = repeat c, w
	program.move x, y
	(program.write str; program.down()) while h-- > 0

wordwrap = require 'wordwrap'
_ = require 'lodash'
Q = require 'q'

graphics = require './graphics-ascii'
{whilst, bresenhamLine, arrayRemove, repeat} = require '../util'

# Initialize log
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

		@invalidate() # initial render

		@logs = []
		@pendingLogs = []

		@logWidth = 80 - TtyRenderer.strMore.length

		@game
		.on 'turn.player', => @showMoreLogs()

		.on 'log.add', (str) => @pendingLogs.push str

		@wrap = wordwrap.hard @logWidth

		@effects = []

		@saveData = require './tty-save-data'

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
		program.fillArea x, y, 80, 1, ' '

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
			# row = row[c.x ... c.x+c.viewport.w]
			row = for t, tx in row[c.x ... c.x+c.viewport.w]
				if c.target.canSee {x: (c.x + tx), y: (c.y + cy)}
					t
				else ' '

			program.write row.join ''

		entityLayer =
			'creature': 3
			'item': 2
			'stairs': 1

		entities = map.entities[..].sort (a, b) ->
			entityLayer[a.type] - entityLayer[b.type]

		@renderEntities x, y, entities
		@renderEffects x, y

	renderEntities: (x, y, entities) ->
		c = @game.camera

		for e in entities when c.target.canSee e
			if (c.x <= e.x < c.x+c.viewport.w) and (c.y <= e.y < c.y+c.viewport.h)
				graphicId = _.result e, 'symbol'
				graphic = graphics.get graphicId

				attrs = []
				if graphic.color?
					attrs.push "#{graphic.color} fg"

				program.pos (e.y - c.y + y), (e.x - c.x + x)
				program.write program.text graphic.symbol, attrs.join ', '

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

	renderEffects: (x, y) ->
		c = @game.camera
		[ox, oy] = [x - c.x, y - c.y]

		for e in @effects
			if e.type is 'line'
				{x, y} = e.current
				program.move x+ox, y+oy
				program.write e.symbol

	effectLine: (start, end, {time, delay, symbol}) ->
		@effects.push data = {
			start, end
			time, delay, symbol
			type: 'line'
		}
		@doEffect data

	doEffects: ->
		Q.all (@effects.map (e) => @doEffect e)

	doEffect: (data) ->
		switch data.type
			when 'line' then @doEffectLine data

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

		.then =>
			arrayRemove @effects, data
			@invalidate()

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: TtyRenderer