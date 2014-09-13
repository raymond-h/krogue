_ = require 'lodash'

log = require '../log'
vectorMath = require '../vector-math'

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

initialize = (game) ->
	canvas = document.getElementById 'viewport'
	viewport = canvas.getContext '2d'

	events = []

	handle = (event) ->
		events.push event

		if events.length is 1
			process.nextTick ->
				handleKey game, events
				events = []

	document.addEventListener 'keypress', handle
	document.addEventListener 'keydown', handle

deinitialize = (game) ->
	viewport = null

class WebRenderer
	constructor: (@game) ->
		@invalidated = no

		@invalidate() # initial render

		@camera =
			x: 0
			y: 0

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextTick =>
				@invalidated = no

				@render()

	hasMoreLogs: -> no

	showMoreLogs: ->

	render: ->
		viewport.fillStyle = '#000000'
		viewport.fillRect(0, 0, 80*12, 21*12)

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

		log 'Hello world! Render time!'

		for cx in [0...map.w]
			for cy in [0...map.h]
				@renderSymbolAtSlot cx, cy, map.data[cy][cx]

		entityLayer =
			'creature': 3
			'item': 2
			'stairs': 1

		entities = map.entities[..].sort (a, b) ->
			entityLayer[a.type] - entityLayer[b.type]

		@renderEntities x, y, entities

		log 'Done rendering!!'

	renderEntities: (x, y, entities) ->
		# c = @game.camera

		for e in entities
			@renderSymbolAtSlot e.x, e.y, (_.result e, 'symbol')

	renderSymbolAtSlot: (x, y, symbol, color) ->
		c = @camera

		@renderSymbol(
			x * 12 - c.x, y * 12 - c.y,
			symbol, color
		)

	renderSymbol: (x, y, symbol, color = 'white') ->
		viewport.fillStyle = 'black'
		viewport.fillRect(x, y, 12, 12)

		viewport.font = '12pt monospace'
		viewport.fillStyle = color
		viewport.fillText symbol, x, y + 12

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: WebRenderer