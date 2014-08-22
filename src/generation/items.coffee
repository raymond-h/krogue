game = require '../game'
items = require '../items'

exports.generatePeculiarObject = ->
	new items.PeculiarObject

exports.generateGun = (type, name) ->
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
	type ?= game.random.sample ['handgun', 'shotgun']

	exports.generateGun type, "trusty #{type}"