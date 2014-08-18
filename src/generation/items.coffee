items = require '../items'

exports.generateGun = (type, name) ->
	game = require '../game'

	type ?= game.random.sample ['handgun', 'shotgun']
	name ?= type

	gun = new items.Gun
	gun.name = name
	gun.gunType = type

	gun.range = game.random.range 5, 12

	if type is 'shotgun'
		angle = game.random.range 15, 60
		gun.spread = (angle / 180 * Math.PI)

	gun

exports.generateStartingGun = (type) ->
	game = require '../game'

	type ?= game.random.sample ['handgun', 'shotgun']

	exports.generateGun type, "trusty #{type}"