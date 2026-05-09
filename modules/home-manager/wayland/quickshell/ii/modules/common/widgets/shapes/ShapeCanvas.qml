// Fallback stub for the missing `shapes` package.  Upstream end-4
// references `qs.modules.common.widgets.shapes` (and four .js files under
// it) but never commits the implementation.  This stub satisfies the
// import so the shell can load — MaterialShape / MaterialCookie callers
// will render a plain rounded rectangle instead of the bespoke material
// shape, which is acceptable until upstream ships the real thing.
//
// Inheriting from Rectangle gives callers `color`, `border.*`, and the
// rest of the Rectangle API for free, which is what they expect from the
// real ShapeCanvas.
import QtQuick

Rectangle {
    id: root
    property var roundedPolygon: null
    property bool polygonIsNormalized: true
    // Real ShapeCanvas accepts an Animation here to drive shape morphs.
    // Stubbed as a plain `var` so callers can assign without errors.
    property var animation: null
    implicitWidth: 24
    implicitHeight: 24
    radius: Math.min(width, height) / 4
    color: "transparent"
}
