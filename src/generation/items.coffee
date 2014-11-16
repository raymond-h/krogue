game = require '../game'
items = require '../definitions/items'

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
			gun.weight = 1

		when 'sniper'
			gun.range = game.random.range 18, 26
			gun.damage = game.random.range 17, 20
			gun.accuracy = game.random.rangeFloat 0.9, 0.99
			gun.weight = game.random.range 12, 30

		when 'shotgun'
			gun.range = game.random.range 3, 9
			gun.damage = game.random.range 17, 22
			gun.spread = (game.random.range 15, 60) * Math.PI / 180
			gun.accuracy = game.random.rangeFloat 0.4, 0.5
			gun.weight = game.random.range 7, 20

		else gun.gunType = '_dud'

	gun

exports.generateStartingGun = ->
	type = 'handgun'

	exports.generateGun type, "trusty handgun"