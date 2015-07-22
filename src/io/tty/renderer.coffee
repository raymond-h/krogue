blessed = require 'blessed'
program = blessed.program.global

wordwrap = require 'wordwrap'
_ = require 'lodash'
LineMan = require '../line-man'

log = require '../../log'
entityClasses = require '../../entities'

Camera = require '../../camera'
graphics = require '../graphics-ascii'
Effects = require './effects'

parseAttrs = (graphic) ->
	attrs = []

	if graphic.color?
		attrs.push "#{graphic.color} fg"

	attrs

module.exports = class TtyRenderer
	@strMore = ' [more]'

	constructor: (@io, @game) ->
		@invalidated = no

		blank = {symbol: ' '}
		@buffer =
			for i in [0...80*25]
				blank

		@invalidate() # initial render

		logWidth = 80 - TtyRenderer.strMore.length

		@lineMan = new LineMan @logWidth

		@game
		.on 'turn.player.start', => @invalidate()
		.on 'log.add', (str) => @lineMan.add str

		@lineMan
		.on 'update', => @invalidate()

		@effects = new Effects @
		@camera = new Camera { w: 80, h: 21 }, { x: 30, y: 9 }

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
		@lineMan.lines.length > 1

	showMoreLogs: ->
		@lineMan.lines.shift()
		@invalidate()

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextTick =>
				@invalidated = no

				@render()

	setPromptMessage: (promptMessage) ->
		if promptMessage?
			@lineMan.add '\n' + promptMessage
			@showMoreLogs()

	showList: (@menu) ->
		@invalidate()

	setCursorPos: (x, y) ->
		program.cursorPos x, y

	render: ->
		switch @game.state
			when 'game'
				@renderLog 0, 0
				@renderMap 0, 1
				@renderMenu @menu if @menu?

				@renderHealth 0, 22

			when 'death'
				@renderDeath()

			else null

		@flipBuffer()

		if @game.player?
			x = @game.player.lookPos.x - @camera.x
			y = @game.player.lookPos.y - @camera.y + 1

			@setCursorPos y, x

	renderDeath: ->
		@fillArea 0, 0, 80, 25, ' '

		@write 0, 0, "Well well, #{@game.player.creature}, you have died..."
		@write 4, 1, "See you around..."
		@write 4, 2, "(Ctrl-C to exit.)"

	renderLog: (x, y) ->
		@fillArea x, y, 80, 1, ' '

		if @lineMan.lines.length > 0
			str = @lineMan.lines[0]

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

		delimiter = (_.repeat '-', width-2)
		rows = [delimiter, menu.header, delimiter, menu.items..., delimiter]

		height = menu.height ? rows.length

		for row, i in rows
			str = "|#{row}#{_.repeat ' ', (width - row.length - 2)}|"
			@write x, y+i, str

	renderMap: (x, y) ->
		c = @camera
		map = @game.currentMap

		c.target = @game.player.lookPos
		c.bounds map
		c.update()

		graphicAt = (x, y) =>
			if @game.player.creature.canSee {x, y}
				@getGraphic map.data[y][x]

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

		for e in entities when @game.player.creature.canSee e
			if (c.x <= e.x < c.x+c.viewport.w) and (c.y <= e.y < c.y+c.viewport.h)
				graphic = @getGraphic e

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

		@write x, y, "[#{_.repeat '=', currentWidth}#{_.repeat ' ', restWidth}]"

	renderEffects: (ox, oy) ->
		@io.effects.renderEffects ox, oy

	getGraphic: (input) ->
		id = @getGraphicId input
		graphics.get id

	getGraphicId: (input) ->
		if _.isString input
			input

		else if _.isObject input
			if _.isPlainObject input
				input.symbol ? input.type

			else if input instanceof entityClasses.Creature
				@getGraphicId input.species

			else if input instanceof entityClasses.MapItem
				@getGraphicId input.item

			else if input instanceof entityClasses.Stairs
				if input.down then 'stairsDown' else 'stairsUp'

			else
				_.camelCase input.constructor.name
