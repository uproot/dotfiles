import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import { createState, For, onCleanup } from "ags"
import { execAsync } from "ags/process"
import { closeOnUnfocus } from "./autoClose"

interface Entry {
  id: string
  preview: string
}

function parseList(raw: string): Entry[] {
  return raw
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const tab = line.indexOf("\t")
      if (tab === -1) return { id: line, preview: line }
      return { id: line.slice(0, tab), preview: line.slice(tab + 1) }
    })
}

async function refresh(): Promise<Entry[]> {
  try {
    const out = await execAsync(["cliphist", "list"])
    return parseList(out)
  } catch {
    return []
  }
}

async function copyEntry(id: string) {
  try {
    await execAsync(["bash", "-c", `cliphist decode <<<'${id.replace(/'/g, "'\\''")}' | wl-copy > /dev/null 2>&1`])
  } catch (e) {
    console.error(e)
  }
}

async function deleteEntry(id: string) {
  try {
    await execAsync(["sh", "-c", `cliphist delete <<<'${id.replace(/'/g, "'\\''")}'`])
  } catch (e) {
    console.error(e)
  }
}

export default function Clipboard() {
  let win: Astal.Window
  let entry: Gtk.Entry
  const [items, setItems] = createState<Entry[]>([])
  const [query, setQuery] = createState("")

  const reload = async () => setItems(await refresh())

  const filtered = items((all) =>
    query.get().trim().length === 0
      ? all.slice(0, 100)
      : all
          .filter((e) =>
            e.preview.toLowerCase().includes(query.get().toLowerCase()),
          )
          .slice(0, 100),
  )

  const close = () => {
    if (win) win.visible = false
  }

  const pick = async (e: Entry) => {
    close()
    await copyEntry(e.id)
  }

  onCleanup(() => win?.destroy())

  return (
    <window
      $={(self) => {
        win = self
        closeOnUnfocus(self)
        self.connect("notify::visible", () => {
          if (self.visible) {
            reload()
            setQuery("")
            entry?.set_text("")
            entry?.grab_focus()
          }
        })
      }}
      name="clipboard"
      namespace="ags-clipboard"
      visible={false}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={Astal.WindowAnchor.TOP}
      marginTop={48}
      application={app}
      class="Popup Clipboard"
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={520}
        cssClasses={["PopupInner"]}
      >
        <box class="PopupHeader" spacing={8}>
          <image iconName="edit-paste-symbolic" />
          <entry
            $={(self) => (entry = self)}
            hexpand
            placeholderText="Search clipboard…"
            onNotifyText={(self) => setQuery(self.text)}
            onActivate={() => {
              const list = filtered.get()
              if (list.length > 0) pick(list[0])
            }}
          />
          <button onClicked={close} tooltipText="Close (Esc)">
            <image iconName="window-close-symbolic" />
          </button>
        </box>
        <Gtk.ScrolledWindow
          vexpand
          heightRequest={420}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
            <For each={filtered}>
              {(item) => (
                <button
                  class="ClipItem"
                  onClicked={() => pick(item)}
                >
                  <box spacing={8}>
                    <label
                      hexpand
                      xalign={0}
                      maxWidthChars={60}
                      ellipsize={3}
                      label={item.preview}
                    />
                    <button
                      class="iconbtn"
                      onClicked={async () => {
                        await deleteEntry(item.id)
                        reload()
                      }}
                      tooltipText="Delete"
                    >
                      <image iconName="user-trash-symbolic" />
                    </button>
                  </box>
                </button>
              )}
            </For>
          </box>
        </Gtk.ScrolledWindow>
      </box>
    </window>
  )
}
