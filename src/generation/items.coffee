game = require '../game'
items = require '../definitions/items'

{MapItem} = require '../entities'

exports.asMapItem = (x, y, item) ->
	new MapItem null, x, y, item

exports.generatePeculiarObject = ->
	new items.PeculiarObject

exports.generateGun = (type, name) ->
	type ?= game.random.sample ['handgun', 'shotgun', 'sniper']
	name ?= type

	gun = new items.Gun
	gun.name = name
	gun.gunType = type

	switch type
		when 'handgun'
			gun.range = game.random.range 5, 12
			gun.damage = game.random.range 9, 12
			gun.accuracy = game.random.rangeFloat 0.4, 0.7

		when 'sniper'
			gun.range = game.random.range 18, 26
			gun.damage = game.random.range 12, 15
			gun.accuracy = game.random.rangeFloat 0.9, 0.99

		when 'shotgun'
			gun.range = game.random.range 3, 9
			gun.damage = game.random.range 17, 22
			gun.spread = (game.random.range 15, 60) * Math.PI / 180
			gun.accuracy = game.random.rangeFloat 0.4, 0.5

		else gun.gunType = '_dud'

	gun

exports.generateStartingGun = ->
	type = 'handgun'

	exports.generateGun type, "trusty handgun"