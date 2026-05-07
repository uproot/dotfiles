import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import { createState, For, onCleanup } from "ags"
import { execAsync } from "ags/process"
import EMOJIS from "./emoji-data"
import { closeOnUnfocus } from "./autoClose"

async function copy(text: string) {
  try {
    await execAsync(["bash", "-c", `printf '%s' '${text.replace(/'/g, "'\\''")}' | wl-copy > /dev/null 2>&1`])
  } catch (e) {
    console.error(e)
  }
}

export default function EmojiPicker() {
  let win: Astal.Window
  let entry: Gtk.Entry
  const [query, setQuery] = createState("")

  const filtered = query((q) => {
    const needle = q.trim().toLowerCase()
    if (!needle) return EMOJIS.slice(0, 200)
    return EMOJIS.filter((e) =>
      e.k.some((k) => k.toLowerCase().includes(needle)),
    ).slice(0, 200)
  })

  const close = () => {
    if (win) win.visible = false
  }

  const pick = async (emoji: string) => {
    close()
    await copy(emoji)
  }

  onCleanup(() => win?.destroy())

  return (
    <window
      $={(self) => {
        win = self
        closeOnUnfocus(self)
        self.connect("notify::visible", () => {
          if (self.visible) {
            setQuery("")
            entry?.set_text("")
            entry?.grab_focus()
          }
        })
      }}
      name="emoji"
      namespace="ags-emoji"
      visible={false}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={Astal.WindowAnchor.TOP}
      marginTop={48}
      application={app}
      class="Popup Emoji"
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={460}
        cssClasses={["PopupInner"]}
      >
        <box class="PopupHeader" spacing={8}>
          <image iconName="face-smile-symbolic" />
          <entry
            $={(self) => (entry = self)}
            hexpand
            placeholderText="Search emoji…"
            onNotifyText={(self) => setQuery(self.text)}
            onActivate={() => {
              const list = filtered.get()
              if (list.length > 0) pick(list[0].e)
            }}
          />
          <button onClicked={close} tooltipText="Close">
            <image iconName="window-close-symbolic" />
          </button>
        </box>
        <Gtk.ScrolledWindow
          vexpand
          heightRequest={360}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
        >
          <Gtk.FlowBox
            class="EmojiGrid"
            maxChildrenPerLine={10}
            minChildrenPerLine={8}
            selectionMode={Gtk.SelectionMode.NONE}
            rowSpacing={4}
            columnSpacing={4}
          >
            <For each={filtered}>
              {(item) => (
                <button
                  class="EmojiBtn"
                  tooltipText={item.k[0]}
                  onClicked={() => pick(item.e)}
                >
                  <label class="emoji" label={item.e} />
                </button>
              )}
            </For>
          </Gtk.FlowBox>
        </Gtk.ScrolledWindow>
      </box>
    </window>
  )
}
