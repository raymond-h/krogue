var Map, Stairs, _, cellAuto, convertMapData, generatePos, random, recursiveMap, repeat,
  slice = [].slice;

_ = require('lodash');

random = require('../random');

Map = require('../map').Map;

Stairs = require('../entities').Stairs;

repeat = require('../util').repeat;

cellAuto = require('./cellular-automata');

exports.generatePos = generatePos = function(w, h, data) {
  var ref, ref1, x, y;
  if (h == null) {
    ref = w, w = ref.w, h = ref.h, data = ref.data;
  }
  while (true) {
    x = random.range(0, w);
    y = random.range(0, h);
    if (!((ref1 = data[y][x].collidable) != null ? ref1 : false)) {
      break;
    }
  }
  return {
    x: x,
    y: y
  };
};

exports.createMapData = function(w, h, tileCb) {
  var i, ref, results, x, y;
  results = [];
  for (y = i = 0, ref = h; 0 <= ref ? i < ref : i > ref; y = 0 <= ref ? ++i : --i) {
    results.push((function() {
      var j, ref1, results1;
      results1 = [];
      for (x = j = 0, ref1 = w; 0 <= ref1 ? j < ref1 : j > ref1; x = 0 <= ref1 ? ++j : --j) {
        results1.push(tileCb(x, y, w, h));
      }
      return results1;
    })());
  }
  return results;
};


/*
Generation functions
 */

exports.generateExits = function(map, path, level, connections) {
  var name, position, ref, ref1, ref2, results, stairs, targetMap, x, y;
  map.positions = {
    'entrance': generatePos(map),
    'exit': generatePos(map)
  };
  results = [];
  for (name in connections) {
    ref = connections[name], targetMap = ref[0], position = ref[1];
    ref2 = (ref1 = map.positions[name]) != null ? ref1 : generatePos(map), x = ref2.x, y = ref2.y;
    stairs = new Stairs({
      map: map,
      x: x,
      y: y
    });
    stairs.target = {
      map: targetMap,
      position: position
    };
    stairs.down = name === 'exit';
    results.push(map.addEntity(stairs));
  }
  return results;
};

exports.generateBigRoom = function(path, level, connections, w, h) {
  var data, map, tileCb;
  map = new Map(w, h);
  tileCb = function(x, y, w, h) {
    if (!((0 < x && x < w - 1) && (0 < y && y < h - 1))) {
      return 1;
    } else {
      return 0;
    }
  };
  data = exports.createMapData(map.w, map.h, tileCb);
  map.data = convertMapData(data, [
    {
      collidable: false,
      seeThrough: true,
      type: 'floor'
    }, {
      collidable: true,
      seeThrough: false,
      type: 'wall'
    }
  ]);
  exports.generateExits(map, path, level, connections);
  return map;
};

exports.generateCellularAutomata = function(path, level, connections, w, h) {
  var data, initProb, map, rules;
  map = new Map(w, h);
  initProb = 0.44;
  rules = _.flatten([
    repeat(6, function() {
      var neighbours;
      neighbours = arguments[arguments.length - 1];
      return neighbours >= 5;
    }), repeat(3, function() {
      var neighbours;
      neighbours = arguments[arguments.length - 1];
      return neighbours >= 4;
    })
  ]);
  data = cellAuto.createMap({
    width: w,
    height: h,
    initProbability: initProb,
    rules: rules,
    randomFn: function() {
      return random.rnd();
    }
  });
  map.data = convertMapData(data, [
    {
      collidable: false,
      seeThrough: true,
      type: 'floor'
    }, {
      collidable: true,
      seeThrough: false,
      type: 'wall'
    }
  ]);
  exports.generateExits(map, path, level, connections);
  return map;
};

recursiveMap = function(data, fn) {
  var map;
  map = function() {
    var a;
    a = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    if (_.isArray(a[0])) {
      return a[0].map(map);
    } else {
      return fn.apply(null, a);
    }
  };
  return data.map(map);
};

convertMapData = function(data, values) {
  return recursiveMap(data, function(v) {
    switch (false) {
      case !_.isArray(values):
        return values[v];
      case !_.isFunction(values):
        return values(v);
    }
  });
};
