_ = require 'lodash'

log = require '../log'
vectorMath = require '../vector-math'

graphics = require './graphics-ascii'

viewport = null

mapKey = (keyIdent) ->
	switch keyIdent
		when 'Up', 'ArrowUp'
			'up'

		when 'Down', 'ArrowDown'
			'down'

		when 'Left', 'ArrowLeft'
			'left'

		when 'Right', 'ArrowRight'
			'right'

		when 'Enter'
			'enter'

handleKey = (game, events) ->
	[downEvent, pressEvent] = events
	log.silly 'Key events:', events

	ch = undefined
	name = mapKey (downEvent.key ? downEvent.keyIdentifier)

	if pressEvent?
		ch = pressEvent.char ? String.fromCharCode pressEvent.charCode
		name ?= ch

	key =
		ch: ch
		name: name

		ctrl: downEvent.ctrlKey
		shift: downEvent.shiftKey
		alt: downEvent.altKey
		meta: downEvent.metaKey

	key.full =
		(if key.ctrl then 'C-' else '') +
		(if key.meta then 'M-' else '') +
		(if key.shift then 'S-' else '') +
		(key.name ? key.ch)

	game.emit "key.#{key.name}", key.ch, key

updateSize = ->
	viewport.canvas.width = window.innerWidth
	viewport.canvas.height = window.innerHeight

initialize = (game) ->
	canvas = document.getElementById 'viewport'
	viewport = canvas.getContext '2d'

	window.onerror = (errMsg, url, lineNumber) ->
		viewport.fillStyle = '#000000'
		viewport.fillRect 0, 0, viewport.canvas.width, viewport.canvas.height

		viewport.font = '30pt monospace'
		viewport.fillStyle = 'red'
		viewport.fillText "Craaaash!", 5, 5+30

		viewport.font = '20pt monospace'
		viewport.fillStyle = 'red'
		viewport.fillText errMsg, 5, 5+30+20+7

		viewport.font = '15pt monospace'
		viewport.fillStyle = 'red'
		viewport.fillText "...at #{url}, line ##{lineNumber}", 5, 5+30+20+7+15+7

		false

	events = []

	handle = (event) ->
		events.push event

		if events.length is 1
			process.nextTick ->
				handleKey game, events
				events = []

	document.addEventListener 'keypress', handle
	document.addEventListener 'keydown', handle

	window.onresize = _.debounce ->
		updateSize()
		game.renderer.invalidate()

	, 300

	updateSize()

deinitialize = (game) ->
	viewport = null

class WebRenderer
	constructor: (@game) ->
		@invalidated = no

		@invalidate() # initial render

		@camera =
			x: 0
			y: 0

		@asciiCanvas = document.createElement 'canvas'
		[@asciiCanvas.width, @asciiCanvas.height] = [12*4, 12*8]
		@asciiCtx = @asciiCanvas.getContext '2d'

		@graphics = @preRenderAscii()
		log @graphics

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextTick =>
				@invalidated = no

				@render()

	hasMoreLogs: -> no

	showMoreLogs: ->

	preRenderAscii: ->
		dim =
			x: 4
			y: 8

		i = 0

		_.zipObject (
			for name of graphics.graphics
				g = graphics.get name
				[x, y] = [i % dim.x, i // dim.x]
				i++
				# render to @asciiCtx
				@renderSymbolAtSlot @asciiCtx, x, y, g.symbol, g.color
				# assemble [name, {x, y}]
				[name, {x, y, graphics: g}]
		)

	render: ->
		viewport.fillStyle = '#000000'
		viewport.fillRect 0, 0, viewport.canvas.width, viewport.canvas.height

		# viewport.drawImage @asciiCanvas, 0, 0

		switch @game.state
			when 'game'
				# @renderLog 0, 0
				@renderMap 0, 0
				# @renderMenu @menu if @menu?

				# @renderHealth 0, 22

			else null

	renderMap: (x, y) ->
		canvasSize = {x: viewport.canvas.width, y: viewport.canvas.height}
		playerScreenPos = vectorMath.mult @game.player.creature, 12

		map = @game.currentMap
		center = vectorMath.add playerScreenPos, {x: 6, y: 6}
		@camera = vectorMath.sub center, vectorMath.div canvasSize, 2
		@camera.target = @game.player.creature

		@camera.x //= 1
		@camera.y //= 1

		log 'Hello world! Render time!'

		mapSymbols =
			'#': 'wall'
			'.': 'floor'

		graphicAt = (x, y) =>
			if @camera.target.canSee {x, y}
				t = map.data[y][x]
				mapSymbols[t]

		for cx in [0...map.w]
			for cy in [0...map.h]
				graphic = graphicAt cx, cy
				@renderGraphicAtSlot cx, cy, graphic if graphic?

		entityLayer =
			'creature': 3
			'item': 2
			'stairs': 1

		entities = map.entities[..].sort (a, b) ->
			entityLayer[a.type] - entityLayer[b.type]

		@renderEntities x, y, entities

		log 'Done rendering!!'

	renderEntities: (x, y, entities) ->
		for e in entities when @camera.target.canSee e
			
			# graphic = graphics.get _.result e, 'symbol'
			@renderGraphicAtSlot e.x, e.y, _.result e, 'symbol'

	renderGraphicAtSlot: (x, y, graphicId) ->
		c = @camera

		{x: sourceX, y: sourceY} = @graphics[graphicId]
		viewport.drawImage(
			@asciiCanvas,
			sourceX*12, sourceY*12, 12, 12,
			x*12 - c.x, y*12 - c.y, 12, 12
		)

	renderSymbolAtSlot: (ctx, x, y, symbol, color) ->
		@renderSymbol(
			ctx,
			x * 12, y * 12,
			symbol, color
		)

	renderSymbol: (ctx, x, y, symbol, color = 'white') ->
		ctx.fillStyle = 'black'
		ctx.fillRect(x, y, 12, 12)

		ctx.font = '10pt monospace'
		ctx.fillStyle = color
		ctx.textAlign = 'center'
		ctx.textBaseline = 'ideographic'
		ctx.fillText symbol, x + 5, y + 12

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: WebRenderer