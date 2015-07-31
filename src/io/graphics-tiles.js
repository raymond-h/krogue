var _, graphics;

_ = require('lodash');

exports.graphics = graphics = require('../../public/res/tiles-def.json');

exports.get = function(id) {
  var ref;
  if (id == null) {
    id = '_default';
  }
  return (ref = graphics[id]) != null ? ref : graphics._default;
};
