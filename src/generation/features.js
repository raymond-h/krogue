var CreatureGen, log, random, randomArea, randomPoint;

random = require('../random');

log = require('../log');

CreatureGen = require('./creatures');

randomPoint = function(map, pred) {
  var p;
  if (pred != null) {
    p = randomPoint(map);
    while (!pred(p)) {
      p = randomPoint(map);
    }
    return p;
  }
  if ((map.top != null) && (map.bottom != null) && (map.left != null) && (map.right != null)) {
    return {
      x: random.range(map.left, map.right),
      y: random.range(map.top, map.bottom)
    };
  } else {
    return {
      x: random.range(0, map.w),
      y: random.range(0, map.h)
    };
  }
};

randomArea = function(map) {
  var max, min, p1, p2;
  p1 = randomPoint(map);
  p2 = randomPoint(map);
  min = {
    x: Math.min(p1.x, p2.x),
    y: Math.min(p1.y, p2.y)
  };
  max = {
    x: Math.max(p1.x, p2.x),
    y: Math.max(p1.y, p2.y)
  };
  return {
    top: min.y,
    left: min.x,
    right: max.x,
    bottom: max.y
  };
};

exports.generateFeatures = function(path, level, map) {
  log.info('Generating features...');
  if (random.chance(1)) {
    return exports.generateSpaceBeeHive(path, level, map);
  }
};

exports.generateSpaceBeeHive = function(path, level, map) {
  var bees, bottom, floor, group, i, j, k, l, left, p, ref, ref1, ref2, ref3, ref4, ref5, right, top, wall, x, y;
  ref = randomArea(map), top = ref.top, left = ref.left, right = ref.right, bottom = ref.bottom;
  wall = {
    collidable: true,
    seeThrough: false,
    type: 'honeycombWall'
  };
  floor = {
    collidable: false,
    seeThrough: true,
    type: 'honeycombFloor'
  };
  for (y = j = ref1 = top, ref2 = bottom; ref1 <= ref2 ? j < ref2 : j > ref2; y = ref1 <= ref2 ? ++j : --j) {
    for (x = k = ref3 = left, ref4 = right; ref3 <= ref4 ? k < ref4 : k > ref4; x = ref3 <= ref4 ? ++k : --k) {
      map.data[y][x] = map.data[y][x].collidable ? wall : floor;
    }
  }
  group = "space-bee-" + (random.range(0, 100000));
  bees = [];
  p = randomPoint({
    top: top,
    left: left,
    right: right,
    bottom: bottom
  }, function(arg) {
    var x, y;
    x = arg.x, y = arg.y;
    return !map.collidable(x, y);
  });
  bees.push(CreatureGen.generateSpaceBee(p.x, p.y, {
    monarch: true,
    group: group
  }));
  for (i = l = 1, ref5 = random.range(20, 30); 1 <= ref5 ? l <= ref5 : l >= ref5; i = 1 <= ref5 ? ++l : --l) {
    p = randomPoint({
      top: top,
      left: left,
      right: right,
      bottom: bottom
    }, function(arg) {
      var x, y;
      x = arg.x, y = arg.y;
      return !map.collidable(x, y);
    });
    bees.push(CreatureGen.generateSpaceBee(p.x, p.y, {
      group: group
    }));
  }
  map.addEntity.apply(map, bees);
  return log.info("Generated space bee hive (" + group + ") @", {
    top: top,
    left: left,
    right: right,
    bottom: bottom
  });
};
