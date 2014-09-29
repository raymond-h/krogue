_ = require 'lodash'

log = require '../log'

vectorMath = require '../vector-math'

tileGraphics = require './graphics-tiles'
graphics = require './graphics-ascii'

Effects = require './web-effects'

module.exports = class WebRenderer
	constructor: (@game) ->
		@invalidated = no

		@invalidate() # initial render

		@camera =
			x: 0
			y: 0

		@tileSize = 32

		@logBox = document.getElementById 'log'

		@game
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

			@game.renderer.invalidate()

		, 300

		@updateSize()

		@asciiCanvas = $('<canvas>')[0]
		[@asciiCanvas.width, @asciiCanvas.height] = [@tileSize*4, @tileSize*8]
		@asciiCtx = @asciiCanvas.getContext '2d'

		@tilesImg = document.getElementById 'tiles'

		@graphics = @preRenderAscii()
		log @graphics

		@effects = new Effects @

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

	hasMoreLogs: -> no

	showMoreLogs: ->

	showList: (@menu) ->
		if @menu?
			$('#menu').show().html "
				<h1 class=\"menu-title\">
					#{@menu.header}
				</h1>
				<ul>
					#{("<li>#{i}</li>" for i in @menu.items).join ''}
				</ul>
			"

		else
			$('#menu').hide().html ''

		@invalidate()

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
		@viewport.fillStyle = '#000000'
		@viewport.fillRect 0, 0, @viewport.canvas.width, @viewport.canvas.height

		# @viewport.drawImage @asciiCanvas, 0, 0

		switch @game.state
			when 'game'
				# @renderLog 0, 0
				@renderMap 0, 0
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

	renderMap: (x, y) ->
		canvasSize = {x: @viewport.canvas.width, y: @viewport.canvas.height}
		playerScreenPos = vectorMath.mult @game.player.creature, @tileSize

		map = @game.currentMap
		center = vectorMath.add playerScreenPos, {x: @tileSize/2, y: @tileSize/2}
		@camera = vectorMath.sub center, vectorMath.div canvasSize, 2
		@camera.target = @game.player.creature

		@camera.x //= 1
		@camera.y //= 1

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
		@renderEffects x, y

	renderEntities: (x, y, entities) ->
		for e in entities when @camera.target.canSee e
			
			# graphic = graphics.get _.result e, 'symbol'
			@renderGraphicAtSlot e.x, e.y, _.result e, 'symbol'

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

	renderSymbolAtSlot: (ctx, x, y, symbol, color) ->
		@renderSymbol(
			ctx,
			x * @tileSize, y * @tileSize,
			symbol, color
		)

	renderSymbol: (ctx, x, y, symbol, color = 'white') ->
		ctx.fillStyle = 'black'
		ctx.fillRect x, y, @tileSize, @tileSize

		ctx.font = "#{@tileSize}px consolas"
		ctx.fillStyle = color
		ctx.textAlign = 'center'
		ctx.textBaseline = 'bottom'
		ctx.fillText symbol, x + @tileSize/2, y + @tileSize

	renderEffects: (ox, oy) ->
		@effects.renderEffects ox, oy

	doEffect: (data) ->
		@effects.doEffect data