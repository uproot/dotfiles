// Stubs for end-4's never-committed material-shapes JS.  Each getter
// returns null so the calling MaterialShape simply renders the
// ShapeCanvas-stub fallback (a plain rounded rectangle).
//
// `rotate30` is referenced by MaterialCookie via `.map(...)`, so we
// expose an object with a no-op map.
.pragma library

function _stub() { return null; }

var rotate30 = {
    map: function (_pt) { return _pt; }
};

function getCircle()        { return _stub(); }
function getSquare()        { return _stub(); }
function getSlanted()       { return _stub(); }
function getArch()          { return _stub(); }
function getFan()           { return _stub(); }
function getArrow()         { return _stub(); }
function getSemiCircle()    { return _stub(); }
function getOval()          { return _stub(); }
function getPill()          { return _stub(); }
function getTriangle()      { return _stub(); }
function getDiamond()       { return _stub(); }
function getClamShell()     { return _stub(); }
function getPentagon()      { return _stub(); }
function getGem()           { return _stub(); }
function getSunny()         { return _stub(); }
function getVerySunny()     { return _stub(); }
function getCookie4Sided()  { return _stub(); }
function getCookie6Sided()  { return _stub(); }
function getCookie7Sided()  { return _stub(); }
function getCookie9Sided()  { return _stub(); }
function getCookie12Sided() { return _stub(); }
function getGhostish()      { return _stub(); }
function getClover4Leaf()   { return _stub(); }
function getClover8Leaf()   { return _stub(); }
function getBurst()         { return _stub(); }
function getSoftBurst()     { return _stub(); }
function getBoom()          { return _stub(); }
function getSoftBoom()      { return _stub(); }
function getFlower()        { return _stub(); }
function getPuffy()         { return _stub(); }
function getPuffyDiamond()  { return _stub(); }
function getPixelCircle()   { return _stub(); }
function getPixelTriangle() { return _stub(); }
function getBun()           { return _stub(); }
function getHeart()         { return _stub(); }
