Species = class exports.Species
	equipSlots: []

class exports.StrangeGoo extends Species
	name: 'strange goo'
	symbol: 'g'

	modifyStat: (stat, statName) ->
		stat / 3 if statName is 'agility'

class exports.Human extends Species
	name: 'human'
	symbol: '@'
	equipSlots: [
		'head'
		'right hand', 'left hand'
	]

	# modifyStat: (stat, statName) ->
	# 	stat * 100 if statName is 'strength'

class exports.ViolentDonkey extends Species
	name: 'violent donkey'
	symbol: 'h'

class exports.TinyAlien extends Species
	name: 'tiny alien'
	symbol: 'i'
	equipSlots: [
		'head'
		'right hand', 'left hand'
	]

class exports.SpaceAnemone extends Species
	name: 'space anemone'
	symbol: 'm'

	modifyStat: (creature, val, stat) ->
		switch stat
			when 'strength' then val * 4.5

			when 'agility' then val / 2.0

			else val