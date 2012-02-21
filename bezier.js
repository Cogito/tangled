(function($) {
  var drawVectors = false;
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

  var Point = function(x, y) {
    return {
      x: x,
      y: y,
      translate: function(vector) {
        return Point(
          this.x + vector.length * Math.cos(vector.angle),
          this.y + vector.length * Math.sin(vector.angle)
        );
      },
      vectorFrom: function(point) {
        return Vector(this.distanceTo(point), Math.atan2(this.y - point.y, this.x - point.x));
      },
      distanceTo: function (point) {
        return Math.sqrt((this.x - point.x)*(this.x - point.x) + (this.y - point.y)*(this.y - point.y));
      }
    }
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
      length: length, // pixels?
      angle: angle, // radians!
      rotate: rotate,
      scaleTo: scaleTo,
      scale: scale,
      draw: draw
    };
  };
  var Node = function(v1, v2, tail) {
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
        this.tail = Node(Vector(10,0), v3);
      }
      return this.tail;
    };
    var lastPoint = function(start) {
      var nextStart = start.advance(this.v1, this.v2);
      if (this.tail) {
        return this.tail.lastPoint(nextStart);
      } else {
        return nextStart;
      }
    };
    var draw = function(context, start) {
      drawPoints(context, start, this.v1, this.v2);
      if (this.tail) {
        this.tail.draw(context, start.advance(this.v1, this.v2));
      }
    };
    return {
      v1: v1,
      v2: v2,
      tail: tail, // a list of vectors! (max one to start, then two. probably no more)
      add: add,
      extend: extend,
      lastPoint: lastPoint,
      draw: draw
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
  var bezierPoints = function(start, v1, v2) {
    var w = 3;
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
        p.translate(v1.rotate(-Math.PI / 2).scaleTo(w)),
        v1.scale(cpLeftScale),
        end_point.translate(v2.rotate(-Math.PI / 2).scaleTo(w)),
        v2.rotate(Math.PI).scale(cpLeftScale)
      ),
      bez2: Bezier(
        p.translate(v1.rotate(Math.PI / 2).scaleTo(w)),
        v1.scale(cpRightScale),
        end_point.translate(v2.rotate(Math.PI / 2).scaleTo(w)),
        v2.rotate(Math.PI).scale(cpRightScale)
      ),
      heading: v2.angle % (Math.PI * 2)
    }
  };
  var drawPoints = function(context, start, v1, v2) {
    var curves = bezierPoints(start, v1, v2);
    context.strokeStyle = "rgb(0,0,0)";
    context.beginPath();
    curves.bez1.draw(context);
    context.lineTo(curves.bez2.end.x,curves.bez2.end.y);
    curves.bez2.drawReverse(context);
    context.lineTo(curves.bez1.start.x,curves.bez1.start.y);
    //context.stroke();
    context.fill();
    if (drawVectors) {
      context.strokeStyle = "rgba(255,0,0,0.5)";
      context.beginPath();
      v1.draw(context, start);
      v2.draw(context, start.advance(v1));
      context.stroke();
    }
    return curves.heading;
  };
  var draw = function(canvas, start, vectors) {
    if (canvas.getContext){
      var context = canvas.getContext('2d');
      clearCanvas(canvas, context);
      vectors.draw(context, start);
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
  var start = Start(Point(0, 50), 0);
  var vectors = Node(Vector(20, 0), Vector(40, 1));
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
    draw($canvas[0], start, vectors);
    draw($straight[0], Start(Point(14,23), -Math.PI/2), Node(Vector(9,0), Vector(9,0)));
    draw($left[0], Start(Point(20,23), -Math.PI/2), Node(Vector(15,0), Vector(15,-Math.PI/2)));
    draw($right[0], Start(Point(8,23), -Math.PI/2), Node(Vector(15,0), Vector(15,Math.PI/2)));
    var lastNode;
    var lp;
    $canvas.mousedown(function(e) {
      var parentOffset = $(this).offset();
      //or $(this).offset(); if you really just want the current element's offset
      var relX = e.pageX - parentOffset.left;
      var relY = e.pageY - parentOffset.top;

      lp = vectors.lastPoint(start);
      vectors.extend(Point(relX, relY).vectorFrom(lp.p).rotate(-lp.h));
      draw($canvas[0], start, vectors);
      lastNode = vectors;
      while (lastNode.tail) {
        lastNode = lastNode.tail;
      }
    });
    $canvas.mousemove(function(e) {
      if (lastNode) {
        var parentOffset = $(this).offset();
        var relX = e.pageX - parentOffset.left;
        var relY = e.pageY - parentOffset.top;
        lastNode.v2 = Point(relX, relY).vectorFrom(lp.p.translate(lastNode.v1.rotate(lp.h))).rotate(-lp.h);
        lastNode.v1.length = lastNode.v2.length/2;
        draw($canvas[0], start, vectors);
        //$("#angles").html((lastNode.v1.angle + (2 * Math.PI)) % (2 * Math.PI));
      }
    });
    $canvas.mouseup(function() {
      draw($canvas[0], start, vectors);
      lastNode = undefined;
    });
    $straight.click(function() {
      vectors.add(Node(Vector(9,0), Vector(9,0)));
      draw($canvas[0], start, vectors);
    });
    $left.click(function() {
      vectors.add(Node(Vector(15,0), Vector(15,-Math.PI/2)));
      draw($canvas[0], start, vectors);
    });
    $right.click(function() {
      vectors.add(Node(Vector(15,0), Vector(15,Math.PI/2)));
      draw($canvas[0], start, vectors);
    });
  });
})(jQuery);
