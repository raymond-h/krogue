random = require '../random'
items = require '../definitions/items'

exports.generatePeculiarObject = ->
	new items.PeculiarObject

exports.generateGun = (type, name) ->
	type ?= random.sample ['handgun', 'shotgun', 'sniper']
	name ?= type

	gun = new items.Gun
	gun.name = name
	gun.gunType = type

	switch type
		when 'handgun'
			gun.range = random.range 5, 12
			gun.damage = random.range 9, 12
			gun.accuracy = random.rangeFloat 0.4, 0.7
			gun.weight = 1

		when 'sniper'
			gun.range = random.range 18, 26
			gun.damage = random.range 17, 20
			gun.accuracy = random.rangeFloat 0.9, 0.99
			gun.weight = random.range 12, 30

		when 'shotgun'
			gun.range = random.range 3, 9
			gun.damage = random.range 17, 22
			gun.spread = (random.range 15, 60) * Math.PI / 180
			gun.accuracy = random.rangeFloat 0.4, 0.5
			gun.weight = random.range 7, 20

		else gun.gunType = '_dud'

	gun

exports.generateStartingGun = ->
	type = 'handgun'

	exports.generateGun type, "trusty handgun"
