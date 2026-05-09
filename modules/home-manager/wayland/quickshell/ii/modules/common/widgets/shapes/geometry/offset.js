// Stub for the never-committed shapes/geometry/offset.js.  Provides a
// minimal Offset class so MaterialCookie loads without errors.
.pragma library

function Offset(x, y) {
    this.x = x || 0;
    this.y = y || 0;
}
