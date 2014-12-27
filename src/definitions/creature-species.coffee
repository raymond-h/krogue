_ = require 'lodash'

skills = require './skills'

Species = class exports.Species
	equipSlotNum:
		head: 1
		hand: 0
		body: 1
		foot: 0

	skills: -> [] # by default, species have no skills at all

equipSlotNum = (Clazz, slots) ->
	Clazz::equipSlotNum = _.assign {}, (Species::equipSlotNum), slots

exports._equipSlots = ['head', 'hand', 'body', 'foot']

humanoidSlots =
	hand: 2
	foot: 2

quadrupedSlots =
	hand: 0
	foot: 4

class exports.StrangeGoo extends Species
	name: 'strange goo'
	symbol: 'strangeGoo'

	modifyStat: (creature, stat, name) ->
		stat / 3 if name is 'agility'

class exports.Human extends Species
	name: 'human'
	symbol: 'human'
	weight: 60 # kg

	equipSlotNum @, humanoidSlots

	skills: -> [
		super...
		new skills.SenseLasagna
		new skills.TentacleWhip
	]

	# modifyStat: (creature, stat, name) ->
	# 	if name in ['agility', 'strength', 'endurance']
	# 		stat * 10

	# 	else stat

class exports.ViolentDonkey extends Species
	name: 'violent donkey'
	symbol: 'violentDonkey'
	weight: 120

	equipSlotNum @, quadrupedSlots

class exports.TinyAlien extends Species
	name: 'tiny alien'
	symbol: 'tinyAlien'
	weight: 20

	equipSlotNum @, humanoidSlots

class exports.SpaceAnemone extends Species
	name: 'space anemone'
	symbol: 'spaceAnemone'
	weight: 300

	equipSlotNum @,
		head: 0
		hand: 55

	modifyStat: (creature, stat, name) ->
		switch name
			when 'strength' then stat * 4.5

			when 'agility' then stat / 2.0

			else stat

class exports.SpaceBee extends Species
	name: 'space bee'
	symbol: 'spaceBee'
	weight: 1 / 10000

	constructor: (@monarch = no, @group = null) ->
		if @monarch
			@name = 'space bee monarch'
			@symbol = 'spaceBeeMonarch'
			@weight = 2 / 10000

	equipSlotNum @,
		hand: 0
		foot: 6

	modifyStat: (creature, stat, name) ->
		switch name
			when 'strength' then stat * 0.01

			when 'agility' then stat * 4

			when 'endurance' then stat * 0.01

			else stat