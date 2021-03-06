_ = require 'lodash'

log = require '../../log'

vectorMath = require '../../vector-math'
message = require '../../message'
entityClasses = require '../../entities'

tileGraphics = require '../graphics-tiles'
graphics = require '../graphics-ascii'

Effects = require './effects'

module.exports = class WebRenderer
	constructor: (@io, @game) ->
		@invalidated = no

		@invalidate() # initial render

		@camera =
			x: 0
			y: 0

		@promptMessage = null

		@tileSize = 32

		@cursor = null

		@logBox = document.getElementById 'log'

		@game
		.on 'turn.player.start', =>
			@invalidate()

		.on 'log.add', (str) =>
			$(@logBox).append "<p>#{str}</p>"

			@logBox.scrollTop = @logBox.scrollHeight

		canvas = $('#viewport')[0]
		@viewport = canvas.getContext '2d'

		window.onerror = (errMsg, url, lineNumber) =>
			@viewport.fillStyle = '#000000'
			@viewport.fillRect 0, 0, @viewport.canvas.width, @viewport.canvas.height

			@viewport.font = '30pt monospace'
			@viewport.fillStyle = 'red'
			@viewport.fillText "Craaaash!", 5, 5+30

			@viewport.font = '20pt monospace'
			@viewport.fillStyle = 'red'
			@viewport.fillText errMsg, 5, 5+30+20+7

			@viewport.font = '15pt monospace'
			@viewport.fillStyle = 'red'
			@viewport.fillText "...at #{url}, line ##{lineNumber}", 5, 5+30+20+7+15+7

			false

		window.onresize = _.debounce =>
			@updateSize()

			@invalidate()

		, 300

		@updateSize()

		@asciiCanvas = $('<canvas>')[0]
		[@asciiCanvas.width, @asciiCanvas.height] = [@tileSize*4, @tileSize*8]
		@asciiCtx = @asciiCanvas.getContext '2d'

		@tilesImg = document.getElementById 'tiles'

		@graphics = preRenderAscii @asciiCtx, graphics, @tileSize

		@useTiles = no # ascii by default

		$('#menu').hide().html ''

	updateSize: ->
		@viewport.canvas.width = window.innerWidth
		@viewport.canvas.height = window.innerHeight

		@viewport.webkitImageSmoothingEnabled = false
		@viewport.mozImageSmoothingEnabled = false
		@viewport.oImageSmoothingEnabled = false
		@viewport.msImageSmoothingEnabled = false
		@viewport.imageSmoothingEnabled = false

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextTick =>
				@invalidated = no

				@render()

	setPromptMessage: (@promptMessage) ->
		@message @promptMessage if @promptMessage?

	hasMoreLogs: -> no

	showMoreLogs: ->

	hideMenu: ->
		$('#menu').off()
		$('#menu').hide().html ''

	showSingleChoiceMenu: (header, items, opts) ->
		$('#menu').show().html "
			<h1 class=\"menu-title\">#{header}</h1>
			<ul class=\"single-choice items\">
				#{("<li>#{i}</li>" for i in items).join ''}
			</ul>
			<div class=\"actions\">
				<a id=\"cancel\" class=\"action cancel\" href=\"#\">Cancel</a>
			</div>
		"

		$('#menu .items').on 'click', 'li', ->
			i = $(this).index()

			opts?.onChoice i, items[i]

		$('#menu #cancel').click ->
			opts?.onCancel?()

	showMultiChoiceMenu: (header, items, opts) ->
		$('#menu').show().html "
			<h1 class=\"menu-title\">#{header}</h1>
			<ul class=\"multi-choice items\">
				#{("<li>#{i}</li>" for i in items).join ''}
			</ul>
			<div class=\"actions\">
				<a id=\"cancel\" class=\"action cancel\" href=\"#\">Cancel</a>
				<a id=\"done\" class=\"action done\" href=\"#\">Done</a>
			</div>
		"

		updateChecked = (i) ->
			$('#menu .items > li').eq(i).toggleClass 'checked'

			opts?.onChecked? i, items[i], ($(this).hasClass 'checked')

		done = ->
			indices = []

			$('#menu .items .checked').each -> indices.push $(this).index()

			opts?.onDone? indices

		$('#menu .items').on 'click', 'li', ->
			console.log "Clicked #{$(this).index()}", this
			updateChecked $(this).index()

		$('#menu #cancel').click ->
			opts?.onCancel?()

		$('#menu #done').click ->
			done()

		[updateChecked, done]

	onClick: (callback) ->
		handler = (e) =>
			worldPos =
				x: (e.pageX + @camera.x) // @tileSize
				y: (e.pageY + @camera.y) // @tileSize

			eventData =
				original: e
				x: e.pageX + @camera.x
				y: e.pageY + @camera.y
				world: worldPos

			callback eventData

		canvas = $(@viewport.canvas)

		canvas.bind 'click', handler

		return (-> canvas.unbind 'click', handler)

	render: ->
		@viewport.fillStyle = '#000000'
		@viewport.fillRect 0, 0, @viewport.canvas.width, @viewport.canvas.height

		# @viewport.drawImage @asciiCanvas, 0, 0

		switch @game.state
			when 'game'
				# @renderLog 0, 0
				@renderMap 0, 0
				@renderCursor() if @cursor?
				# @renderMenu @menu if @menu?

				# @renderHealth 0, 22

			when 'death'
				@renderDeath()

			else null

	renderDeath: ->
		@viewport.font = '30pt monospace'
		@viewport.textAlign = 'center'
		@viewport.textBaseline = 'middle'
		@viewport.fillStyle = 'red'
		@viewport.fillText "You have died, #{@game.player.creature}!",
			@viewport.canvas.width/2, @viewport.canvas.height/2

	renderCursor: ->
		{x, y} = @cursor

		x = x*@tileSize - @camera.x
		y = y*@tileSize - @camera.y

		@viewport.fillStyle = 'rgba(255,0,0, 0.2)'
		@viewport.fillRect x, y, @tileSize, @tileSize

	renderMap: (x, y) ->
		canvasSize = {x: @viewport.canvas.width, y: @viewport.canvas.height}
		playerScreenPos = vectorMath.mult @game.player.lookPos, @tileSize

		map = @game.currentMap
		center = vectorMath.add playerScreenPos, {x: @tileSize/2, y: @tileSize/2}
		@camera = vectorMath.sub center, vectorMath.div canvasSize, 2
		@camera.target = @game.player.creature

		@camera.x //= 1
		@camera.y //= 1

		graphicAt = (x, y) =>
			if @camera.target.canSee {x, y}
				@getGraphicId map.data[y][x]

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
		@renderEffects x, y

	renderEntities: (x, y, entities) ->
		for e in entities when @camera.target.canSee e

			# graphic = graphics.get _.result e, 'symbol'
			@renderGraphicAtSlot e.x, e.y, @getGraphicId e

	renderGraphicAtSlot: (x, y, graphicId) ->
		c = @camera

		if @useTiles
			{x: sourceX, y: sourceY} = tileGraphics.get graphicId
			@viewport.drawImage(
				@tilesImg,
				sourceX, sourceY, 16, 16,
				x*@tileSize - c.x, y*@tileSize - c.y, @tileSize, @tileSize
			)

		else
			{x: sourceX, y: sourceY} = (@graphics[graphicId] ? @graphics._default)
			@viewport.drawImage(
				@asciiCanvas,
				sourceX*@tileSize, sourceY*@tileSize, @tileSize, @tileSize,
				x*@tileSize - c.x, y*@tileSize - c.y, @tileSize, @tileSize
			)

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

	renderEffects: (ox, oy) ->
		@io.effects.renderEffects ox, oy



preRenderAscii = (ctx, graphics, tileSize, dim) ->
	renderSymbolAtSlot = (x, y, symbol, color) ->
		renderSymbol(
			x * tileSize, y * tileSize,
			symbol, color
		)

	renderSymbol = (x, y, symbol, color = 'white') ->
		ctx.fillStyle = 'black'
		ctx.fillRect x, y, tileSize, tileSize

		ctx.font = "#{tileSize}px consolas"
		ctx.fillStyle = color
		ctx.textAlign = 'center'
		ctx.textBaseline = 'bottom'
		ctx.fillText symbol, x + tileSize/2, y + tileSize

	dim ?=
		x: 4
		y: 8

	i = 0

	_.zipObject (
		for name of graphics.graphics
			g = graphics.get name
			[x, y] = [i % dim.x, i // dim.x]
			i++
			# render to ctx
			renderSymbolAtSlot x, y, g.symbol, g.color
			# assemble [name, {x, y}]
			[name, {x, y, graphics: g}]
	)
