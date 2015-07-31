var MapGen, generateEntities, generateMap;

MapGen = require('./maps');

generateMap = function(path, level, connections) {
  var map;
  map = MapGen.generateBigRoom(path, level, connections, 80, 21);
  generateEntities(map, path, level);
  return map;
};

generateEntities = function(map, path, level) {};

module.exports = {
  generateMap: generateMap,
  generateEntities: generateEntities
};
