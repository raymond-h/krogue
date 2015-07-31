var CreatureGen, ItemGen, MapGen, generateEntities, generateMap;

MapGen = require('./maps');

CreatureGen = require('./creatures');

ItemGen = require('./items');

generateMap = function(path, level, connections) {
  var map;
  map = MapGen.generateCellularAutomata(path, level, connections, 100, 50);
  generateEntities(map, path, level);
  return map;
};

generateEntities = function(map, path, level) {
  var i, j, k, l, m, ref, ref1, ref2, ref3, ref4, x, y;
  for (i = j = 1; j <= 20; i = ++j) {
    ref = MapGen.generatePos(map), x = ref.x, y = ref.y;
    map.addEntity(CreatureGen.generateStrangeGoo(x, y));
  }
  for (i = k = 1; k <= 3; i = ++k) {
    ref1 = MapGen.generatePos(map), x = ref1.x, y = ref1.y;
    map.addEntity(CreatureGen.generateViolentDonkey(x, y));
  }
  for (i = l = 1; l <= 3; i = ++l) {
    ref2 = MapGen.generatePos(map), x = ref2.x, y = ref2.y;
    map.addEntity(CreatureGen.generateSpaceAnemone(x, y));
  }
  for (i = m = 1; m <= 3; i = ++m) {
    ref3 = MapGen.generatePos(map), x = ref3.x, y = ref3.y;
    map.addEntity(ItemGen.generatePeculiarObject().asMapItem(x, y));
  }
  ref4 = MapGen.generatePos(map), x = ref4.x, y = ref4.y;
  return map.addEntity(ItemGen.generateGun().asMapItem(x, y));
};

module.exports = {
  generateMap: generateMap,
  generateEntities: generateEntities
};
