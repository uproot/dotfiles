import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import AstalNetwork from "gi://AstalNetwork"
import AstalWp from "gi://AstalWp"
import AstalMpris from "gi://AstalMpris"
import AstalBattery from "gi://AstalBattery"
import { createBinding, createState, For, With, onCleanup } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import { closeOnUnfocus } from "./autoClose"

function shellQuote(s: string): string {
  return `'${s.replace(/'/g, "'\\''")}'`
}

async function nmConnect(ssid: string, password?: string) {
  const args = password
    ? ["sh", "-c", `nmcli device wifi connect ${shellQuote(ssid)} password ${shellQuote(password)}`]
    : ["sh", "-c", `nmcli device wifi connect ${shellQuote(ssid)}`]
  try { await execAsync(args) } catch (e) { console.error(e) }
}

async function notify(summary: string, body = "") {
  try { await execAsync(["notify-send", "-a", "ags", summary, body]) } catch {}
}

async function readBrightness(): Promise<number | null> {
  try {
    const cur = parseInt(await execAsync(["brightnessctl", "g"]))
    const max = parseInt(await execAsync(["brightnessctl", "m"]))
    if (!max || isNaN(cur) || isNaN(max)) return null
    return cur / max
  } catch { return null }
}
async function writeBrightness(frac: number) {
  const pct = Math.round(Math.max(0.01, Math.min(1, frac)) * 100)
  try { await execAsync(["brightnessctl", "s", `${pct}%`]) } catch {}
}

function SectionTitle({ label, action }: { label: string; action?: () => void }) {
  return (
    <box class="SectionTitle" spacing={6}>
      <label hexpand xalign={0} label={label} />
      {action && (
        <button class="iconbtn" onClicked={action} tooltipText="Refresh">
          <image iconName="view-refresh-symbolic" />
        </button>
      )}
    </box>
  )
}

function VolumeRow({
  device, label, mutedIcon, icon,
}: {
  device: AstalWp.Endpoint
  label: string
  mutedIcon: string
  icon: string
}) {
  const volume = createBinding(device, "volume")
  const mute = createBinding(device, "mute")
  return (
    <box class="Row" spacing={10}>
      <button
        class="iconbtn"
        tooltipText={`${label}: mute`}
        onClicked={() => device.set_mute(!device.mute)}
      >
        <image iconName={mute((m) => (m ? mutedIcon : icon))} />
      </button>
      <slider
        hexpand
        value={volume}
        onChangeValue={({ value }) => device.set_volume(value)}
      />
      <label
        class="trail"
        widthChars={4}
        label={volume((v) => `${Math.round(v * 100)}`)}
      />
    </box>
  )
}

function AudioSection() {
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker
  const mic = wp?.defaultMicrophone
  return (
    <box class="Section" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <SectionTitle label="Audio" />
      {speaker && (
        <VolumeRow
          device={speaker}
          label="Output"
          icon="audio-volume-high-symbolic"
          mutedIcon="audio-volume-muted-symbolic"
        />
      )}
      {mic && (
        <VolumeRow
          device={mic}
          label="Input"
          icon="audio-input-microphone-symbolic"
          mutedIcon="microphone-disabled-symbolic"
        />
      )}
    </box>
  )
}

function BrightnessSection() {
  const [initial, setInitial] = createState<number | null>(null)
  let mounted = true
  readBrightness().then((v) => { if (mounted) setInitial(v) })
  onCleanup(() => { mounted = false })

  return (
    <With value={initial}>
      {(v) =>
        v === null ? null : (
          <box class="Section" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            <SectionTitle label="Brightness" />
            <box class="Row" spacing={10}>
              <image iconName="display-brightness-symbolic" />
              <slider
                hexpand
                value={v}
                onChangeValue={({ value }) => writeBrightness(value)}
              />
            </box>
          </box>
        )
      }
    </With>
  )
}

function WifiNetworkRow({
  ap, wifi,
}: {
  ap: AstalNetwork.AccessPoint
  wifi: AstalNetwork.Wifi
}) {
  const isActive = createBinding(wifi, "activeAccessPoint")(
    (a) => a?.bssid === ap.bssid,
  )
  return (
    <button
      class={isActive((a) => (a ? "WifiItem active" : "WifiItem"))}
      onClicked={async () => {
        if (isActive.get()) return
        await nmConnect(ap.ssid)
      }}
    >
      <box spacing={8}>
        <image iconName={ap.iconName ?? "network-wireless-symbolic"} />
        <label hexpand xalign={0} label={ap.ssid ?? "(hidden)"} />
        <With value={isActive}>
          {(a) => (a ? <image iconName="object-select-symbolic" /> : null)}
        </With>
        <label class="dim" label={`${Math.round(ap.strength)}%`} />
      </box>
    </button>
  )
}

function WifiSection() {
  const network = AstalNetwork.get_default()
  const wifi = createBinding(network, "wifi")

  return (
    <With value={wifi}>
      {(w) => {
        if (!w) return null

        const enabled = createBinding(w, "enabled")
        const aps = createBinding(w, "accessPoints")

        const visible = aps((list) => {
          const best = new Map<string, AstalNetwork.AccessPoint>()
          for (const ap of list) {
            const key = ap.ssid ?? ap.bssid
            if (!key) continue
            const prev = best.get(key)
            if (!prev || ap.strength > prev.strength) best.set(key, ap)
          }
          return Array.from(best.values()).sort((a, b) => b.strength - a.strength)
        })

        return (
          <box class="Section" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            <box class="SectionTitle" spacing={6}>
              <label hexpand xalign={0} label="Wi-Fi" />
              <button
                class="iconbtn"
                tooltipText="Scan"
                onClicked={() => w.scan()}
              >
                <image iconName="view-refresh-symbolic" />
              </button>
              <button
                class="iconbtn"
                tooltipText="Network settings"
                onClicked={() => execAsync(["nm-connection-editor"]).catch(() => {})}
              >
                <image iconName="preferences-system-symbolic" />
              </button>
              <switch
                active={enabled}
                onStateSet={(_self, state) => { w.set_enabled(state); return false }}
              />
            </box>

            <Gtk.ScrolledWindow
              heightRequest={180}
              hscrollbarPolicy={Gtk.PolicyType.NEVER}
              class="WifiList"
            >
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <For each={visible}>
                  {(ap) => <WifiNetworkRow ap={ap} wifi={w} />}
                </For>
              </box>
            </Gtk.ScrolledWindow>
          </box>
        )
      }}
    </With>
  )
}

function PlayerSection() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <With value={players}>
      {(list) => {
        const active = list?.find((p) => p.playbackStatus === AstalMpris.PlaybackStatus.PLAYING) ?? list?.[0]
        if (!active) return null

        const title = createBinding(active, "title")
        const artist = createBinding(active, "artist")
        const status = createBinding(active, "playbackStatus")

        return (
          <box class="Section" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            <SectionTitle label="Now playing" />
            <box class="Row PlayerRow" spacing={10}>
              <image iconName="audio-x-generic-symbolic" />
              <box orientation={Gtk.Orientation.VERTICAL} hexpand>
                <label
                  xalign={0}
                  ellipsize={3}
                  maxWidthChars={32}
                  label={title((t) => t || "Unknown")}
                />
                <label
                  xalign={0}
                  class="dim"
                  ellipsize={3}
                  maxWidthChars={32}
                  label={artist((a) => a || active.identity || "")}
                />
              </box>
              <button class="iconbtn" onClicked={() => active.previous()}>
                <image iconName="media-skip-backward-symbolic" />
              </button>
              <button class="iconbtn" onClicked={() => active.play_pause()}>
                <image iconName={status((s) =>
                  s === AstalMpris.PlaybackStatus.PLAYING
                    ? "media-playback-pause-symbolic"
                    : "media-playback-start-symbolic",
                )} />
              </button>
              <button class="iconbtn" onClicked={() => active.next()}>
                <image iconName="media-skip-forward-symbolic" />
              </button>
            </box>
          </box>
        )
      }}
    </With>
  )
}

function BatterySection() {
  const bat = AstalBattery.get_default()
  if (!bat || !bat.isPresent) return null

  const percent = createBinding(bat, "percentage")
  const charging = createBinding(bat, "charging")
  const icon = createBinding(bat, "iconName")

  return (
    <box class="Section" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <SectionTitle label="Battery" />
      <box class="Row" spacing={10}>
        <image iconName={icon} />
        <label
          hexpand
          xalign={0}
          label={percent((p) => `${Math.round(p * 100)}%`)}
        />
        <label
          class="dim"
          label={charging((c) => (c ? "Charging" : "On battery"))}
        />
      </box>
    </box>
  )
}

function QuickGrid() {
  const toggle = (name: string) => () => {
    const w = app.get_window(name)
    if (w) w.visible = !w.visible
  }
  const screenshot = async () => {
    // Close settings panel first so it's not captured
    const settingsWin = app.get_window("settings")
    if (settingsWin) settingsWin.visible = false

    // Small delay to let the panel animate out
    await new Promise((r) => setTimeout(r, 200))

    try {
      await execAsync([
        "sh", "-c",
        'grim -g "$(slurp -d -c \\#c8d2ffdd -b \\#00000066 -s \\#c8d2ff11)" - | wl-copy && notify-send -a "Screenshot" "Region" "Copied to clipboard"',
      ])
    } catch {}
  }
  return (
    <box class="Section QuickGrid" spacing={6}>
      <button class="QuickTile" onClicked={toggle("clipboard")} tooltipText="Clipboard history">
        <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <image iconName="edit-paste-symbolic" />
          <label class="qlabel" label="Clipboard" />
        </box>
      </button>
      <button class="QuickTile" onClicked={toggle("emoji")} tooltipText="Emoji picker">
        <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <image iconName="face-smile-symbolic" />
          <label class="qlabel" label="Emoji" />
        </box>
      </button>
      <button class="QuickTile" onClicked={toggle("launcher")} tooltipText="Launcher">
        <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <image iconName="system-search-symbolic" />
          <label class="qlabel" label="Launch" />
        </box>
      </button>
      <button class="QuickTile" onClicked={screenshot} tooltipText="Region screenshot">
        <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <image iconName="camera-photo-symbolic" />
          <label class="qlabel" label="Screenshot" />
        </box>
      </button>
    </box>
  )
}

function SessionRow() {
  const cmd = (c: string[]) => () => execAsync(c).catch(() => {})
  return (
    <box class="Section SessionRow" spacing={6}>
      <button class="SessionBtn" tooltipText="Lock" onClicked={cmd(["loginctl", "lock-session"])}>
        <image iconName="system-lock-screen-symbolic" />
      </button>
      <button class="SessionBtn" tooltipText="Suspend" onClicked={cmd(["systemctl", "suspend"])}>
        <image iconName="weather-clear-night-symbolic" />
      </button>
      <button class="SessionBtn" tooltipText="Log out" onClicked={cmd(["hyprctl", "dispatch", "exit"])}>
        <image iconName="system-log-out-symbolic" />
      </button>
      <button class="SessionBtn" tooltipText="Restart" onClicked={cmd(["systemctl", "reboot"])}>
        <image iconName="system-reboot-symbolic" />
      </button>
      <button class="SessionBtn danger" tooltipText="Power off" onClicked={cmd(["systemctl", "poweroff"])}>
        <image iconName="system-shutdown-symbolic" />
      </button>
    </box>
  )
}

function Header() {
  const time = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%A, %B %-d  ·  %H:%M")!,
  )
  return (
    <box class="SettingsHeader" spacing={8}>
      <box orientation={Gtk.Orientation.VERTICAL} hexpand>
        <label xalign={0} class="title" label="Settings" />
        <label xalign={0} class="dim" label={time} />
      </box>
    </box>
  )
}

export default function Settings() {
  let win: Astal.Window

  onCleanup(() => {
    win?.destroy()
  })

  return (
    <window
      $={(self) => {
        win = self
        closeOnUnfocus(self)
      }}
      name="settings"
      namespace="ags-settings"
      visible={false}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
      marginTop={8}
      marginRight={12}
      application={app}
      class="Popup Settings"
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={380}
        cssClasses={["PopupInner", "SettingsInner"]}
        spacing={10}
      >
        <Header />
        <Gtk.ScrolledWindow
          vexpand
          heightRequest={560}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={10}>
            <QuickGrid />
            <AudioSection />
            <BrightnessSection />
            <WifiSection />
            <PlayerSection />
            <BatterySection />
          </box>
        </Gtk.ScrolledWindow>
        <SessionRow />
      </box>
    </window>
  )
}
