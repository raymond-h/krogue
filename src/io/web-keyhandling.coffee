log = require '../log'

events = []

handleEvent = (game, event) ->
	events.push event

	if events.length is 1
		process.nextTick ->
			processEvents game, events
			events = []

processEvents = (game, events) ->
	[downEvent, pressEvent] = events
	log.silly 'Key events:', events

	ch = undefined
	name = mapKey downEvent.which

	if pressEvent?
		ch = pressEvent.char ? String.fromCharCode pressEvent.charCode
		name ?= ch.toLowerCase()

	key =
		ch: ch
		name: name

		ctrl: downEvent.ctrlKey
		shift: downEvent.shiftKey
		alt: downEvent.altKey
		meta: downEvent.metaKey

	key.full =
		(if key.ctrl then 'C-' else '') +
		(if key.meta then 'M-' else '') +
		(if key.shift then 'S-' else '') +
		(key.name ? key.ch)

	game.emit "key.#{key.name}", key.ch, key

mapKey = (which) -> keys[which]

keys =
	13: 'enter'
	27: 'escape'
	37: 'left'
	38: 'up'
	39: 'right'
	40: 'down'

module.exports = {
	handleEvent, processEvents, mapKey
}