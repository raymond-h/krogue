Species = class exports.Species
	equipSlots: []

class exports.StrangeGoo extends Species
	name: 'strange goo'
	symbol: 'g'

	modifyStat: (creature, stat, name) ->
		stat / 3 if name is 'agility'

class exports.Human extends Species
	name: 'human'
	symbol: '@'
	weight: 60 # kg

	equipSlots: [
		'head'
		'right hand', 'left hand'
	]

	# modifyStat: (stat, name) ->
	# 	stat * 100 if name is 'strength'

class exports.ViolentDonkey extends Species
	name: 'violent donkey'
	symbol: 'h'
	weight: 120

class exports.TinyAlien extends Species
	name: 'tiny alien'
	symbol: 'i'
	weight: 20

	equipSlots: [
		'head'
		'right hand', 'left hand'
	]

class exports.SpaceAnemone extends Species
	name: 'space anemone'
	symbol: 'm'
	weight: 300

	modifyStat: (creature, stat, name) ->
		switch name
			when 'strength' then stat * 4.5

			when 'agility' then stat / 2.0

			else stat