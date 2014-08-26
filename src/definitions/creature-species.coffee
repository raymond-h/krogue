{Species} = require '../creature-species'

class exports.StrangeGoo extends Species
	name: 'strange goo'
	symbol: 'g'

class exports.Human extends Species
	name: 'human'
	symbol: '@'
	equipSlots: [
		'head'
		'right hand', 'left hand'
	]

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