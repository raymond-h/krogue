_ = require 'lodash'

skills = require './skills'

Species = class exports.Species
	equipSlotNum:
		head: 1
		hand: 0
		body: 1
		foot: 0

	skills: -> [] # by default, species have no skills at all

	loadFromJSON: (json) -> # do nothing, not even default load

	# return empty object, we don't want to save data on species objects
	toJSON: -> {}

equipSlotNum = (Clazz, slots) ->
	Clazz::equipSlotNum = _.assign {}, (Species::equipSlotNum), slots

exports._equipSlots = ['head', 'hand', 'body', 'foot']

humanoidSlots =
	hand: 2
	foot: 2

quadrupedSlots =
	hand: 0
	foot: 4

exports.classes = classes = {}

class classes.StrangeGoo extends Species
	name: 'strange goo'

	modifyStat: (creature, stat, name) ->
		stat / 3 if name is 'agility'

class classes.Human extends Species
	name: 'human'
	weight: 60 # kg

	equipSlotNum @, humanoidSlots

	skills: -> [
		super...
		new skills.SenseLasagna
		new skills.TentacleWhip
		new skills.Blink
	]

	modifyStat: (creature, stat, name) ->
		if name in ['agility', 'strength', 'endurance']
			stat * 20

		else stat

class classes.ViolentDonkey extends Species
	name: 'violent donkey'
	weight: 120

	equipSlotNum @, quadrupedSlots

class classes.TinyAlien extends Species
	name: 'tiny alien'
	weight: 20

	equipSlotNum @, humanoidSlots

class classes.SpaceAnemone extends Species
	name: 'space anemone'
	weight: 300

	equipSlotNum @,
		head: 0
		hand: 55

	modifyStat: (creature, stat, name) ->
		switch name
			when 'strength' then stat * 4.5

			when 'agility' then stat / 2.0

			else stat

class classes.SpaceBee extends Species
	name: 'space bee'
	weight: 1 / 10000

	equipSlotNum @,
		hand: 0
		foot: 6

	modifyStat: (creature, stat, name) ->
		switch name
			when 'strength' then stat * 0.01

			when 'agility' then stat * 4

			when 'endurance' then stat * 0.01

			else stat

class classes.SpaceBeeMonarch extends classes.SpaceBee
	name: 'space bee monarch'
	weight: 2 / 10000

class classes.Haithera extends Species
	name: 'haithera'
	weight: 400

makeName = (className) ->
	className[0].toLowerCase() + className[1..]

for className, Clazz of classes
	exports[makeName className] = new Clazz