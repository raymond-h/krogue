exports.fromJSON = (json) ->
	new exports[json.type](json)

class exports.SizeAltered
	name: ->
		if @factor < 1 then 'shrunken x' + (1/@factor)
		else 'enlarged x' + @factor

	constructor: ({@factor}) ->

	modifyStat: (creature, stat, name) ->
		if name in ['strength', 'agility', 'endurance', 'weight']
			Math.max 1, stat * @factor // 1
