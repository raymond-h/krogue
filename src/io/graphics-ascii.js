var _, graphics, log;

_ = require('lodash');

log = require('../log');

exports.graphics = graphics = {
  wall: {
    symbol: '#',
    color: '#00ff00'
  },
  floor: {
    symbol: '.',
    color: '#00cd00'
  },
  stairsDown: '>',
  stairsUp: '<',
  strangeGoo: 'g',
  human: '@',
  tinyAlien: 'i',
  spaceAnemone: 'm',
  violentDonkey: 'h',
  corpse: '%',
  gun: '/',
  peculiarObject: 'O',
  pokeBall: '*',
  honeycombWall: {
    symbol: '#',
    color: 'yellow'
  },
  honeycombFloor: {
    symbol: '.',
    color: 'yellow'
  },
  spaceBee: 'd',
  spaceBeeMonarch: 'Q',
  bullet: '*',
  _default: {
    symbol: '§',
    color: 'red'
  }
};

exports.transform = function(graphic) {
  if (_.isString(graphic)) {
    return {
      symbol: graphic,
      color: null
    };
  } else {
    return graphic;
  }
};

exports.get = function(id) {
  var ref;
  if (id == null) {
    id = '_default';
  }
  return exports.transform((ref = graphics[id]) != null ? ref : graphics._default);
};
