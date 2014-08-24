{Species} = require '../creature-species'

class exports.StrangeGoo extends Species
	typeName: 'strange-goo'

	name: 'strange goo'
	symbol: 'g'

class exports.Human extends Species
	typeName: 'human'

	name: 'human'
	symbol: '@'
	equipSlots: [
		'head'
		'right hand', 'left hand'
	]

class exports.ViolentDonkey extends Species
	typeName: 'violent-donkey'

	name: 'violent donkey'
	symbol: 'h'