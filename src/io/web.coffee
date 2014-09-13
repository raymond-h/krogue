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
		viewport.fillRect(0, 0, 80*8, 21*8)

		switch @game.state
			when 'game'
				# @renderLog 0, 0
				@renderMap 0, 0
				# @renderMenu @menu if @menu?

				# @renderHealth 0, 22

			else null

	renderMap: (x, y) ->
		c = @game.camera
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
				viewport.fillStyle = 'white'
				viewport.fillText map.data[cy][cx],
					x + (cx) * 8,
					y + (cy + 1) * 8

		log 'Done rendering!!'

module.exports =
	initialize: initialize
	deinitialize: deinitialize

	Renderer: WebRenderer