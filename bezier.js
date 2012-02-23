var utilities = (function(){
  var Point = function(x, y) {
    var translate = function(vector) {
      return Point(
        this.x + vector.length * Math.cos(vector.angle),
        this.y + vector.length * Math.sin(vector.angle)
      );
    };
    var vectorFrom = function(point) {
      return Vector(this.distanceTo(point), Math.atan2(this.y - point.y, this.x - point.x));
    };
    var distanceTo = function (point) {
      return Math.sqrt((this.x - point.x)*(this.x - point.x) + (this.y - point.y)*(this.y - point.y));
    };
    var relativeTo = function (element) {
      var offset = $(element).offset();
      return Point(this.x - offset.left, this.y - offset.top);
    };
    return {
      translate: translate,
      vectorFrom: vectorFrom,
      distanceTo: distanceTo,
      relativeTo: relativeTo,
      x: x,
      y: y
    };
  };
  var Vector = function(length, angle) {
    var rotate = function(radians) {
      return Vector(this.length, this.angle + radians); // TODO: might try to keep new angle in the range [-PI:PI] later
    };
    var scaleTo = function(len) {
      return Vector(len, this.angle);
    };
    var scale = function(percentage) {
      return Vector(this.length*percentage, this.angle);
    };
    var draw = function(context, startPoint) {
      context.moveTo(startPoint.p.x, startPoint.p.y);
      context.lineTo(startPoint.p.translate(this.rotate(startPoint.h)).x, startPoint.p.translate(this.rotate(startPoint.h)).y);
    };
    return {
      rotate: rotate,
      scaleTo: scaleTo,
      scale: scale,
      draw: draw,
      length: length, // pixels?
      angle: angle // radians!
    };
  };
  var Segment = function(v1, v2, startWidth, endWidth) {
    var draw = function(context, start, options) {
      options = options || {};
      var drawVectors = options.drawVectors || false;
      var wireFrames = options.wireFrames || false;
      var curves = bezierPoints(start, this);
      context.strokeStyle = "rgb(0,0,0)";
      context.beginPath();
      curves.bez1.draw(context);
      context.lineTo(curves.bez2.end.x,curves.bez2.end.y);
      curves.bez2.drawReverse(context);
      context.lineTo(curves.bez1.start.x,curves.bez1.start.y);
      wireFrames ? context.stroke() : context.fill();
      if (drawVectors) {
        context.strokeStyle = "rgba(255,0,0,0.5)";
        context.beginPath();
        this.v1.draw(context, start);
        this.v2.draw(context, start.advance(this.v1));
        context.stroke();
      }
      return curves.heading;
    };
    return {
      draw: draw,
      v1: v1,
      v2: v2,
      startWidth: startWidth || 5,
      endWidth: endWidth || 5
    }
  };
  var Tangle = function(v1, v2, tail) {
    var add = function(node) {
      if (this.tail) {
        this.tail.add(node);
      } else {
        this.tail = node;
      }
      return this.tail;
    };
    var extend = function(v3) {
      if (this.tail) {
        this.tail.extend(v3);
      } else {
        this.tail = Tangle(Vector(v3.length * 0.2,0), v3);
      }
      // Every time we extend the tangle, make it a little thicker
      this.segment.endWidth = this.tail.segment.startWidth;
      this.segment.startWidth = calculateNewThickness(this.segment.startWidth);
      return this.tail;
    };
    var lastPoint = function(start) {
      var nextStart = start.advance(this.segment.v1, this.segment.v2);
      if (this.tail) {
        return this.tail.lastPoint(nextStart);
      } else {
        return nextStart;
      }
    };
    var draw = function(context, start, options) {
      this.segment.draw(context, start,options);
      if (this.tail) {
        this.tail.draw(context, start.advance(this.segment.v1, this.segment.v2), options);
      }
    };
    var lastNode = function () {
      if (this.tail) {
        return this.tail.lastNode();
      } else {
        return this;
      }
    };
    var calculateNewThickness = function(width) {
      var maxWidth = 5;
      if (width < 0) width = 0;
      if (width > maxWidth) width = maxWidth;
      var tmp = (width/maxWidth - 0.5) * Math.PI; // value in the range [-PI/2, PI/2]
      tmp = Math.atan(Math.tan(tmp) + 0.07); // still in the range [-PI/2, PI/2], but slightly more positive
      tmp = (tmp / Math.PI + 0.5) * maxWidth; // now in the range [0, maxWidth]
      return tmp;
    };
    return {
      add: add,
      extend: extend,
      lastPoint: lastPoint,
      draw: draw,
      lastNode: lastNode,
      segment: Segment(v1, v2, 1, 0.1),
      tail: tail // a list of vectors! (max one to start, then two. probably no more)
    };
  };
  var Bezier = function(startPoint, startControlVector, endPoint, endControlVector){
    var draw = function(context) {
      context.moveTo(this.start.x, this.start.y);
      context.bezierCurveTo(this.startCP.x, this.startCP.y, this.endCP.x, this.endCP.y, this.end.x, this.end.y);
    };
    var drawReverse = function(context) {
      context.moveTo(this.end.x, this.end.y);
      context.bezierCurveTo(this.endCP.x, this.endCP.y, this.startCP.x, this.startCP.y, this.start.x, this.start.y);
    };
    return {
      start: startPoint,
      startCP: startPoint.translate(startControlVector),
      end: endPoint,
      endCP: endPoint.translate(endControlVector),
      draw: draw,
      drawReverse: drawReverse
    }
  };
  var Start = function(p, h) {
    var advance = function(v1, v2) {
      v2 = v2 || Vector(0,0);
      return Start(
        this.p.translate(v1.rotate(this.h)).translate(v2.rotate(v1.angle+this.h)),
        (this.h + v1.angle + v2.angle) % (2 * Math.PI)
      );
    };
    return {
      p: p || Point(0,0),
      h: h || 0,
      advance: advance
    }
  };
  var bezierPoints = function(start, segment) {
    var w = 3;
    var v1 = segment.v1;
    var v2 = segment.v2;
    var cpInnerScale = 0.7;
    var cpOuterScale = 0.9;
    var p = start.p;
    var heading = start.h;
    var end_point = start.advance(v1, v2).p;
    v1 = v1.rotate(heading);
    v2 = v2.rotate(v1.angle);
    var bendLeft = (v1.angle - Math.PI < v2.angle && v2.angle < v1.angle) || (v1.angle + Math.PI < v2.angle);
    var cpLeftScale =  bendLeft ? cpInnerScale : cpOuterScale;
    var cpRightScale = bendLeft ? cpOuterScale : cpInnerScale;
    return {
      bez1: Bezier(
        p.translate(v1.rotate(-Math.PI / 2).scaleTo(segment.startWidth)),
        v1.scale(cpLeftScale),
        end_point.translate(v2.rotate(-Math.PI / 2).scaleTo(segment.endWidth)),
        v2.rotate(Math.PI).scale(cpLeftScale)
      ),
      bez2: Bezier(
        p.translate(v1.rotate(Math.PI / 2).scaleTo(segment.startWidth)),
        v1.scale(cpRightScale),
        end_point.translate(v2.rotate(Math.PI / 2).scaleTo(segment.endWidth)),
        v2.rotate(Math.PI).scale(cpRightScale)
      ),
      heading: v2.angle % (Math.PI * 2)
    };
  };
  return {
    Point: Point,
    Vector: Vector,
    Tangle: Tangle,
    Bezier: Bezier,
    Start: Start
  }
})();

(function($, utilities, options) {
  // import some utility class function thingos
  var Point = utilities.Point;
  var Vector = utilities.Vector;
  var Tangle = utilities.Tangle;
  var Bezier = utilities.Bezier;
  var Start = utilities.Start;

  // set module options up
  options = options || {};
  var ticksEnabled = options.ticksEnabled || false;
  var frameRate = options.frameRate || 24;
  var clearCanvas = function (canvas, context) {
    context = context || canvas.getContext?canvas.getContext('2d'):undefined;
    // Store the current transformation matrix
    context.save();

    // Use the identity matrix while clearing the canvas
    context.setTransform(1, 0, 0, 1, 0, 0);
    context.clearRect(0, 0, canvas.width, canvas.height);

    // Restore the transform
    context.restore();
  };
  var draw = function(canvas, start, vectors) {
    if (canvas.getContext){
      var context = canvas.getContext('2d');
      clearCanvas(canvas, context);
      vectors.draw(context, start, {drawVectors: options.drawVectors, wireFrames: options.wireFrames});
    }
  };


  var tick = function(canvas, start, vectors) {
    var range = 1;
    if (ticksEnabled){
      vectors.extend(Vector(5,(Math.random() - 0.5) * range));
      draw(canvas, start, vectors);
    }
  };
  var start = Start(Point(0, 50), 0);
  var vectors = Tangle(Vector(20, 0), Vector(40, 1));
  vectors.extend(Vector(35,-1))
    .extend(Vector(15,0))
    .extend(Vector(25,1.4))
    .extend(Vector(15,-.3))
    .extend(Vector(35,-.7))
    .extend(Vector(55,Math.PI/2));
  $(function() {
    var $canvas = $("#myCanvas");
    var $straight = $("#straight");
    var $left = $("#left");
    var $right = $("#right");
    $('#growth-status')[0].textContent = ticksEnabled?"ON":"OFF";
    $('#wireframes-status')[0].textContent = options.wireFrames?"ON":"OFF";
    draw($canvas[0], start, vectors);
    draw($straight[0], Start(Point(14,23), -Math.PI/2), Tangle(Vector(9,0), Vector(9,0)));
    draw($left[0], Start(Point(20,23), -Math.PI/2), Tangle(Vector(15,0), Vector(15,-Math.PI/2)));
    draw($right[0], Start(Point(8,23), -Math.PI/2), Tangle(Vector(15,0), Vector(15,Math.PI/2)));
    setInterval(tick, 1000/frameRate, $canvas[0],start, vectors);
    var lastSegment;
    var lp;
    $canvas.mousedown(function(e) {
      lp = vectors.lastPoint(start);
      vectors.extend(Point(e.pageX, e.pageY).relativeTo(this).vectorFrom(lp.p).rotate(-lp.h));
      draw($canvas[0], start, vectors);
      lastSegment = vectors.lastNode().segment;
    });
    $canvas.mousemove(function(e) {
      if (lastSegment) {
        lastSegment.v2 = Point(e.pageX, e.pageY).relativeTo(this).vectorFrom(lp.p.translate(lastSegment.v1.rotate(lp.h))).rotate(-lp.h);
        lastSegment.v1.length = lastSegment.v2.length/2;
        draw($canvas[0], start, vectors);
        //$("#angles").html((lastSegment.v1.angle + (2 * Math.PI)) % (2 * Math.PI));
      }
    });
    $canvas.mouseup(function() {
      draw($canvas[0], start, vectors);
      lastSegment = undefined;
    });
    $straight.click(function() {
      vectors.add(Tangle(Vector(9,0), Vector(9,0)));
      draw($canvas[0], start, vectors);
    });
    $left.click(function() {
      vectors.add(Tangle(Vector(15,0), Vector(15,-Math.PI/2)));
      draw($canvas[0], start, vectors);
    });
    $right.click(function() {
      vectors.add(Tangle(Vector(15,0), Vector(15,Math.PI/2)));
      draw($canvas[0], start, vectors);
    });
    $("#growth-toggle").click(function() {
      ticksEnabled = !ticksEnabled;
      $('#growth-status')[0].textContent = ticksEnabled?"ON":"OFF";
    });
    $("#wireframes-toggle").click(function() {
      options.wireFrames = !options.wireFrames;
      $('#wireframes-status')[0].textContent = options.wireFrames?"ON":"OFF";
      draw($canvas[0], start, vectors);
    });
  });
})(jQuery, utilities, {drawVectors: false, ticksEnabled: false, frameRate: 5, wireFrames: true});
