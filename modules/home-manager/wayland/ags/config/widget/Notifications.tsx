import app from "ags/gtk4/app";
import GLib from "gi://GLib";
import Astal from "gi://Astal?version=4.0";
import Gtk from "gi://Gtk?version=4.0";
import AstalNotifd from "gi://AstalNotifd";
import { createBinding, createState, For, With, onCleanup } from "ags";
import { createPoll } from "ags/time";
import { closeOnUnfocus } from "./autoClose";

const TOAST_TIMEOUT_MS = 5000;
const MAX_TOASTS = 4;

function urgencyClass(n: AstalNotifd.Notification): string {
	switch (n.urgency) {
		case AstalNotifd.Urgency.CRITICAL:
			return "Notif critical";
		case AstalNotifd.Urgency.LOW:
			return "Notif low";
		default:
			return "Notif";
	}
}

function relativeTime(epochSec: number): string {
	if (!epochSec) return "";
	const diff = Math.floor(Date.now() / 1000 - epochSec);
	if (diff < 60) return "just now";
	if (diff < 3600) return `${Math.floor(diff / 60)} min ago`;
	if (diff < 86_400) return `${Math.floor(diff / 3600)} h ago`;
	return `${Math.floor(diff / 86_400)} d ago`;
}

function NotifIcon({ n }: { n: AstalNotifd.Notification }) {
	if (n.image && n.image.length > 0) {
		if (n.image.startsWith("/")) return <image file={n.image} pixelSize={36} />;
		return <image iconName={n.image} pixelSize={36} />;
	}
	const fallback = n.appIcon || n.desktopEntry || "dialog-information-symbolic";
	if (fallback.startsWith("/")) return <image file={fallback} pixelSize={28} />;
	return <image iconName={fallback} pixelSize={28} />;
}

function NotifCard({
	n,
	compact = false,
}: {
	n: AstalNotifd.Notification;
	compact?: boolean;
}) {
	return (
		<box
			class={urgencyClass(n)}
			orientation={Gtk.Orientation.VERTICAL}
			spacing={6}
		>
			<box spacing={10}>
				<NotifIcon n={n} />
				<box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={2}>
					<box spacing={6}>
						<label
							hexpand
							xalign={0}
							class="appname"
							ellipsize={3}
							maxWidthChars={32}
							label={n.appName || "Notification"}
						/>
						<label class="time" label={relativeTime(n.time)} />
					</box>
					<label
						xalign={0}
						class="summary"
						ellipsize={3}
						maxWidthChars={42}
						label={n.summary || ""}
					/>
					{n.body ? (
						<label
							xalign={0}
							class="body"
							wrap
							useMarkup
							maxWidthChars={42}
							ellipsize={compact ? 3 : 0}
							label={n.body}
						/>
					) : null}
				</box>
				<button
					class="iconbtn dismiss"
					tooltipText="Dismiss"
					onClicked={() => n.dismiss()}
				>
					<image iconName="window-close-symbolic" />
				</button>
			</box>
			{n.actions && n.actions.length > 0 && (
				<box class="actions" spacing={6}>
					{n.actions.map((a) => (
						<button
							class="action"
							onClicked={() => {
								n.invoke(a.id);
								if (n.urgency !== AstalNotifd.Urgency.CRITICAL) n.dismiss();
							}}
						>
							<label label={a.label} />
						</button>
					))}
				</box>
			)}
		</box>
	);
}

interface Toast {
	id: number;
	notif: AstalNotifd.Notification;
	timer: number | null;
}

export function NotificationToasts() {
	let win: Astal.Window;
	const notifd = AstalNotifd.get_default();
	const [toasts, setToasts] = createState<Toast[]>([]);

	const dismiss = (id: number) => {
		setToasts((cur) => {
			const t = cur.find((x) => x.id === id);
			if (t?.timer) {
				try {
					GLib.source_remove(t.timer);
				} catch (e) {}
			}
			return cur.filter((x) => x.id !== id);
		});
	};

	const handleNew = (id: number) => {
		const n = notifd.get_notification(id);
		if (!n) return;
		if (notifd.dontDisturb && n.urgency !== AstalNotifd.Urgency.CRITICAL)
			return;

		const toast: Toast = { id, notif: n, timer: null };
		if (n.urgency !== AstalNotifd.Urgency.CRITICAL) {
			toast.timer = GLib.timeout_add(
				GLib.PRIORITY_DEFAULT,
				TOAST_TIMEOUT_MS,
				() => {
					dismiss(id);
					return false;
				},
			);
		}
		setToasts((cur) => [toast, ...cur].slice(0, MAX_TOASTS));
	};

	const handleResolved = (id: number) => dismiss(id);

	const sigNew = notifd.connect("notified", (_, id) => handleNew(id));
	const sigRes = notifd.connect("resolved", (_, id) => handleResolved(id));

	onCleanup(() => {
		notifd.disconnect(sigNew);
		notifd.disconnect(sigRes);
		toasts.get().forEach((t) => t.timer && GLib.source_remove(t.timer));
		win?.destroy();
	});

	return (
		<window
			$={(self) => (win = self)}
			visible={toasts((ts) => ts.length > 0)}
			name="notification-toasts"
			namespace="ags-toasts"
			anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
			marginTop={52}
			marginRight={12}
			layer={Astal.Layer.OVERLAY}
			application={app}
			class="Popup ToastLayer"
			keymode={Astal.Keymode.NONE}
		>
			<With value={toasts}>
				{(ts: Toast[]) => (
					<box
						orientation={Gtk.Orientation.VERTICAL}
						spacing={8}
						widthRequest={360}
						cssClasses={["ToastStack"]}
					>
						{ts.map((t) => (
							<box cssClasses={["ToastWrap"]}>
								<NotifCard n={t.notif} compact />
							</box>
						))}
					</box>
				)}
			</With>
		</window>
	);
}

export function NotificationCenter() {
	let win: Astal.Window;
	const notifd = AstalNotifd.get_default();
	const list = createBinding(notifd, "notifications");

	const time = createPoll(
		"",
		1000,
		() => GLib.DateTime.new_now_local().format("%-I:%M %p")!,
	);
	const date = createPoll(
		"",
		30_000,
		() => GLib.DateTime.new_now_local().format("%A, %B %-d")!,
	);

	let closeTimer: number | null = null;

	onCleanup(() => {
		if (closeTimer !== null) GLib.source_remove(closeTimer);
		win?.destroy();
	});

	return (
		<window
			$={(self) => {
				win = self;
				closeOnUnfocus(self);
			}}
			name="notification-center"
			namespace="ags-noticenter"
			visible={false}
			keymode={Astal.Keymode.ON_DEMAND}
			layer={Astal.Layer.OVERLAY}
			anchor={Astal.WindowAnchor.TOP}
			marginTop={52}
			application={app}
			class="Popup NotificationCenter"
		>
			<box
				orientation={Gtk.Orientation.VERTICAL}
				widthRequest={420}
				cssClasses={["PopupInner", "NCInner"]}
				spacing={12}
			>
				<box class="NCHeader" spacing={10}>
					<box orientation={Gtk.Orientation.VERTICAL} hexpand>
						<label xalign={0} class="time" label={time} />
						<label xalign={0} class="dim" label={date} />
					</box>
					<With value={createBinding(notifd, "dontDisturb")}>
						{(dnd) => (
							<button
								class="iconbtn"
								tooltipText={dnd ? "Resume notifications" : "Do not disturb"}
								onClicked={() => notifd.set_dont_disturb(!notifd.dontDisturb)}
							>
								<image
									iconName={
										dnd
											? "notifications-disabled-symbolic"
											: "preferences-system-notifications-symbolic"
									}
								/>
							</button>
						)}
					</With>
				</box>

				<Gtk.Calendar class="NCCalendar" />

				<box class="NCSubhead" spacing={6}>
					<label hexpand xalign={0} label="Notifications" />
					<With value={list}>
						{(items) => (
							<label
								class="dim"
								label={items.length === 0 ? "" : `${items.length}`}
							/>
						)}
					</With>
					<With value={list}>
						{(items) =>
							items.length > 0 ? (
								<button
									class="iconbtn"
									tooltipText="Clear all"
									onClicked={() => items.forEach((n) => n.dismiss())}
								>
									<image iconName="user-trash-symbolic" />
								</button>
							) : null
						}
					</With>
				</box>

				<With value={list}>
					{(items) =>
						items.length === 0 ? (
							<box
								class="NCEmpty"
								orientation={Gtk.Orientation.VERTICAL}
								spacing={6}
							>
								<image
									iconName="preferences-system-notifications-symbolic"
									pixelSize={28}
								/>
								<label class="dim" label="No new notifications" />
							</box>
						) : (
							<Gtk.ScrolledWindow
								vexpand
								heightRequest={360}
								hscrollbarPolicy={Gtk.PolicyType.NEVER}
							>
								<box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
									{items.map((n) => <NotifCard n={n} />)}
								</box>
							</Gtk.ScrolledWindow>
						)
					}
				</With>
			</box>
		</window>
	);
}
