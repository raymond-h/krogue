var _, aStar, direction, distance, distanceMaps, getNeighbouringTiles, offsets, posToStr, vectorMath;

_ = require('lodash');

aStar = require('a-star');

direction = require('rl-directions');

vectorMath = require('./vector-math');

distance = require('./util').distance;

offsets = ['up', 'down', 'left', 'right', 'up-left', 'up-right', 'down-left', 'down-right'].map(function(dir) {
  return direction.parse(dir);
});

posToStr = function(arg) {
  var x, y;
  x = arg.x, y = arg.y;
  return x + ";" + y;
};

getNeighbouringTiles = function(arg, map, tileFn) {
  var i, j, k, len, pos, ref, result, x, y;
  x = arg.x, y = arg.y;
  if (tileFn != null) {
    result = [];
    for (k = 0, len = offsets.length; k < len; k++) {
      ref = offsets[k], i = ref.x, j = ref.y;
      pos = {
        x: x + i,
        y: y + j
      };
      if (tileFn(map, pos)) {
        result.push(pos);
      }
    }
    return result;
  } else {
    return offsets.map(function(arg1) {
      var i, j;
      i = arg1.x, j = arg1.y;
      return {
        x: x + i,
        y: y + j
      };
    });
  }
};

exports.aStar = function(map, start, end, tileFn) {
  var opts;
  if (tileFn == null) {
    tileFn = function(map, arg, data) {
      var x, y;
      x = arg.x, y = arg.y;
      return !data.collidable;
    };
  }
  opts = {
    start: start,
    isEnd: function(node) {
      return node.x === end.x && node.y === end.y;
    },
    neighbor: function(node) {
      var a;
      a = getNeighbouringTiles(node).filter(function(arg) {
        var x, y;
        x = arg.x, y = arg.y;
        return ((0 <= x && x < map.w) && (0 <= y && y < map.h)) && tileFn(map, {
          x: x,
          y: y
        }, map.data[y][x]);
      });
      return a;
    },
    distance: distance,
    heuristic: function(node) {
      return distance(node, end);
    },
    hash: posToStr
  };
  return aStar(opts);
};

exports.aStarOverDistanceMap = function(map, start, end, tileFn) {
  var distMap, opts;
  distMap = exports.getDistanceMap(map, [end], tileFn);
  opts = {
    start: start,
    isEnd: function(node) {
      return node.x === end.x && node.y === end.y;
    },
    neighbor: function(node) {
      return getNeighbouringTiles(node);
    },
    distance: function(a, b) {
      return Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y));
    },
    heuristic: function(arg) {
      var x, y;
      x = arg.x, y = arg.y;
      return distMap[y][x];
    },
    hash: posToStr
  };
  return aStar(opts);
};

distanceMaps = {};

exports.getDistanceMap = function(map, goals, tileFn) {
  var calcDist, dist, distMaps, goal, goalId, k, len, name, nodes, pending, pos, ref, ref1, ref2, x, y;
  if (tileFn == null) {
    tileFn = function(map, arg) {
      var ref, x, y;
      x = arg.x, y = arg.y;
      return !((ref = map.data[y]) != null ? ref[x].collidable : void 0);
    };
  }
  distMaps = distanceMaps[name = map.id] != null ? distanceMaps[name] : distanceMaps[name] = {};
  goalId = goals.map(posToStr).join('_');
  if (distMaps[goalId] != null) {
    return distMaps[goalId];
  }
  distMaps[goalId] = nodes = (function() {
    var k, ref, results;
    results = [];
    for (y = k = 0, ref = map.h; 0 <= ref ? k < ref : k > ref; y = 0 <= ref ? ++k : --k) {
      results.push((function() {
        var l, ref1, results1;
        results1 = [];
        for (x = l = 0, ref1 = map.w; 0 <= ref1 ? l < ref1 : l > ref1; x = 0 <= ref1 ? ++l : --l) {
          results1.push(Infinity);
        }
        return results1;
      })());
    }
    return results;
  })();
  pending = (function() {
    var k, len, results;
    results = [];
    for (k = 0, len = goals.length; k < len; k++) {
      goal = goals[k];
      nodes[goal.y][goal.x] = 0;
      results.push([goal, 0]);
    }
    return results;
  })();
  while (pending.length > 0) {
    ref = pending.shift(), pos = ref[0], dist = ref[1];
    calcDist = dist + 1;
    ref1 = getNeighbouringTiles(pos, map, tileFn);
    for (k = 0, len = ref1.length; k < len; k++) {
      ref2 = ref1[k], x = ref2.x, y = ref2.y;
      if (nodes[y][x] > calcDist) {
        nodes[y][x] = calcDist;
        pending.push([
          {
            x: x,
            y: y
          }, calcDist
        ]);
      }
    }
  }
  return nodes;
};
