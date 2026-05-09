// Stub for the never-committed shapes/shapes/rounded-polygon.js.
// Provides the chainable surface MaterialCookie touches:
//   RoundedPolygon.RoundedPolygon.star(...).transformed(...).normalized()
.pragma library

function RoundedPolygon(points, perVertexRounding) {
    this.points = points || [];
    this.perVertexRounding = perVertexRounding || [];
}

RoundedPolygon.star = function (numVerticesPerRadius, radius, innerRadius, rounding) {
    return new RoundedPolygon([], []);
};

RoundedPolygon.prototype.transformed = function (_fn) { return this; };
RoundedPolygon.prototype.normalized = function () { return this; };
RoundedPolygon.prototype.map = function (_fn) { return this; };
