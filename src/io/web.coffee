_ = require 'lodash'

log = require '../log'

viewport = null

mapKey = (event) ->
	keyIdent = event.key ? event.keyIdentifier
	key = null

	log keyIdent
	if keyIdent? and not /U+\d{4}/.test keyIdent
		key =
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

	key ?= String.fromCharCode event.keyCode

	key

initialize = (game) ->
	canvas = document.getElementById 'viewport'
	viewport = canvas.getContext '2d'

	document.addEventListener 'keydown', (event) ->
		log "Keydown:", event

		key =
			ch: (event.char ? String.fromCharCode event.which).toLowerCase()
			ctrl: event.ctrlKey
			shift: event.shiftKey
			alt: event.altKey
			meta: event.metaKey

		key.name =
			mapKey event
			.toLowerCase()

		key.full =
			(if key.ctrl then 'C-' else '') +
			(if key.meta then 'M-' else '') +
			(if key.shift then 'S-' else '') +
			(key.name ? key.ch)

		game.emit "key.#{key.name}", key.ch, key

deinitialize = (game) ->
	viewport = null

class WebRenderer
	constructor: (@game) ->
		@invalidated = no

		@invalidate() # initial render

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
		# c = @game.camera
		map = @game.currentMap

		# for cy in [0...c.viewport.h]
		# 	sy = c.y + cy
		# 	row = map.data[sy]
			
			# to only get the part that's on-screen
			# we slice from left to right edge of viewport
			# row = row[c.x ... c.x+c.viewport.w]
			# row = for t, tx in row[c.x ... c.x+c.viewport.w]
			# 	if c.target.canSee {x: (c.x + tx), y: (c.y + cy)}
			# 		t
			# 	else ' '

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
		c = @game.camera

		for e in entities
			@renderSymbolAtSlot e.x, e.y, (_.result e, 'symbol')

	renderSymbolAtSlot: (x, y, symbol, color) ->
		c = @game.camera

		@renderSymbol(
			(x * 12 - c.x), (y * 12 - c.y),
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