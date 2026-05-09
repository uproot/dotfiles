// Custom entry point for our Quickshell desktop shell.
//
// This file is OUR override — at activation, home-manager symlinks it into
// `~/.config/quickshell/ii/shell.qml`, on top of the rest of `./ii/` (the
// vendored end-4/dots-hyprland source).  All `import "modules/..."` paths
// below resolve into the vendored tree through those symlinks, so editing
// either this file OR anything under `./ii/` takes effect immediately
// (no rebuild needed for QML edits — `qs -c ii` reloads on file change).
//
// Starting point is intentionally a near-copy of end-4's shell.qml.  Trim
// or replace panel families / loaders here to customize the layout; drop
// component overrides into `../overrides/` and import them as needed.

//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Uncomment to override the UI scale factor:
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
    }

    // Available panel families.  Set the active one in
    // ~/.config/illogical-impulse/config.json (Config.options.panelFamily),
    // or cycle at runtime with the `panelFamilyCycle` global shortcut.
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        Config.options.panelFamily = families[nextIndex]
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }

    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    PanelFamilyLoader {
        identifier: "waffle"
        component: WaffleFamily {}
    }

    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}
