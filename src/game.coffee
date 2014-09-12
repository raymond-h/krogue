async = require 'async'
{EventEmitter2} = require 'eventemitter2'
MersenneTwister = require 'mersennetwister'
Q = require 'q'
_ = require 'lodash'

log = require './log'

{arrayRemove} = require './util'

class Game extends EventEmitter2
	constructor: ->
		super
			wildcard: yes
			newListener: no

		@state = 'main-menu'

		@onAny (a...) ->
			log "Event: '#{@event}'; ", a

		(require './key-handling')(this)

		@logs = []

		@mapIdCounter = 0
		@maps = {}

	generateMapId: ->
		"map-#{@mapIdCounter++}"

	initialize: (@io) ->
		log '*** Starting game...'

		@io.initialize @
		@io.initialized = yes
		@renderer = new @io.Renderer @

		(require './messages')(@)

		@on 'key.c', (ch, key) =>
			@quit() if key.ctrl

		.on 'log.add', (str) ->
			log "<GAME> #{str}"

		.on 'state.enter.game', =>
			@initGame()

	initGame: ->
		log "Init game"

		Player = require './player'
		{GenerationManager} = require './generation/manager'
		TimeManager = require './time-manager'
		Camera = require './camera'
		Random = require './random'

		@random = new Random(new MersenneTwister)
		@timeManager = new TimeManager
		@camera = new Camera { w: 80, h: 21 }, { x: 30, y: 9 }
		@generationManager = new GenerationManager

		creature = @createPlayerCreature()
		@player = new Player creature
		@timeManager.add creature
		@camera.target = creature

		@goTo 'main-1', 'entrance'

	createPlayerCreature: ->
		{Creature} = require './entities'
		{Human} = require './definitions/creature-species'

		creature = new Creature null, 0, 0, new Human

		gun = (require './generation/items').generateStartingGun()

		creature.equipment['right hand'] = gun

		items = require './definitions/items'
		creature.inventory = for i in [1..5]
			new items.PokeBall @random.sample ['normal', 'great', 'ultra', 'master']

		creature

	quit: ->
		@io.deinitialize @ if @io.initialized

		Q.delay(100).then -> process.exit 0

	goTo: (mapId, position) ->
		map = @maps[mapId] ?
			@generationManager.generateMap mapId

		@transitionToMap map, position

	transitionToMap: (map, x, y) ->
		if @currentMap?
			@currentMap.removeEntity @player.creature
			@timeManager.remove @currentMap.entities...

		map.id ?= @generateMapId()
		@maps[map.id] = map

		@currentMap = map
		@camera.bounds map

		@timeManager.add map.entities...
		map.addEntity @player.creature

		if _.isString x
			{x, y} = map.positions[x]

		if x? and y?
			@player.creature.setPos x, y
			
		else
			@camera.update()

		@renderer.invalidate()

	save: (filename) ->
		@renderer.saveData.save @, filename

	load: (filename) ->
		@renderer.saveData.load @, filename

	goState: (state) ->
		@emit "state.exit.#{@state}", 'exit', @state
		@state = state
		@emit "state.enter.#{@state}", 'enter', @state

		@renderer.invalidate()

	message: (str) ->
		@logs.push str
		@logs.shift() while @logs.length > 20

		@emit 'log.add', str

	main: ->
		async.whilst (-> true),
			(next) =>
				switch @state
					when 'main-menu'
						@once 'key.s', =>
							@goState 'game'
							next()

					when 'game'
						@timeManager.tick next

			(err) =>
				log.error err.stack if err?
				@quit()

	loadFromJSON: (json) ->
		@generationManager[k] = v for k,v of json.generationManager

		@logs = json.logs

		@timeManager.remove @player.creature
		@camera.target = null

		@player.creature = json.player.creature

		@timeManager.add @player.creature
		@camera.target = @player.creature

		@camera.x = json.camera.x
		@camera.y = json.camera.y

		@maps = json.maps

		@transitionToMap @maps[json.currentMap]

	saveToJSON: ->
		{
			player:
				creature: @player.creature
			camera:
				x: @camera.x
				y: @camera.y
			@logs
			@generationManager
			currentMap: @currentMap.id
			@maps
		}

module.exports = new Game

module.exports.Game = Game