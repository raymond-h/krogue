var FeatureGen, _;

_ = require('lodash');

FeatureGen = require('./features');

exports.GenerationManager = (function() {
  function GenerationManager(connections1) {
    this.connections = connections1 != null ? connections1 : {};
  }

  GenerationManager.prototype.addConnection = function(map0, p0, map1, p1) {
    var base, base1, positions;
    positions = (base = this.connections)[map0] != null ? base[map0] : base[map0] = {};
    positions[p0] = [map1, p1];
    positions = (base1 = this.connections)[map1] != null ? base1[map1] : base1[map1] = {};
    return positions[p1] = [map0, p0];
  };

  GenerationManager.prototype.getConnections = function(map, position) {
    if (position != null) {
      return this.connections[map][position];
    } else {
      return this.connections[map];
    }
  };

  GenerationManager.prototype.generateMap = function(id) {
    var level, map, path, ref;
    ref = id.split('-'), path = ref[0], level = ref[1];
    level = Number(level);
    this.generateConnections(id, path, level);
    map = this.handleMap(id, path, level);
    map.id = id;
    return map;
  };

  GenerationManager.prototype.generateConnections = function(thisMap, path, level) {
    var exits, map, name, ref, results, target;
    exits = path === 'main' ? {
      exit: ["main-" + (level + 1), 'entrance']
    } : void 0;
    results = [];
    for (name in exits) {
      ref = exits[name], map = ref[0], target = ref[1];
      results.push(this.addConnection(thisMap, name, map, target));
    }
    return results;
  };

  GenerationManager.prototype.handleMap = function(id, path, level) {
    var connections, map;
    connections = this.getConnections(id);
    map = level === 1 ? this.generateStart(path, 1, connections) : level > 1 ? this.generateCave(path, level - 1, connections) : void 0;
    FeatureGen.generateFeatures(path, level, map);
    return map;
  };

  GenerationManager.prototype.generateStart = function(path, level, connections) {
    return (require('./generator-start')).generateMap(path, level, connections);
  };

  GenerationManager.prototype.generateCave = function(path, level, connections) {
    return (require('./generator-cave')).generateMap(path, level, connections);
  };

  return GenerationManager;

})();
