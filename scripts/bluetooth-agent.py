#!/usr/bin/env python3
"""BlueZ pairing agent for the Bluetooth dropdown (run by quickshell/widgets/BluetoothAgent.qml).

Registers as bluetoothd's default agent with the KeyboardDisplay capability, so pairing with a
device that has a screen or keyboard goes through a code the user compares or types
(MITM-protected Secure Simple Pairing); devices with neither pair "just works" on any agent.

Each request is one JSON line on stdout and waits for the user's answer on stdin,
`{"id": N, "accept": true|false, "value": "PIN or passkey"}`. Nothing is accepted on its own
except a connection from a device that is already bonded (paired, with a stored link key).
Codes the user types on a keyboard go out as `display` lines (no id: nothing waits on them),
and bluetoothd giving up on a request as a `cancel` line. Exits when stdin closes.
"""

import json
import sys

from gi.repository import Gio, GLib

AGENT_PATH = "/qs/bluetooth/agent"
CAPABILITY = "KeyboardDisplay"
REJECTED = "org.bluez.Error.Rejected"

INTERFACE = Gio.DBusNodeInfo.new_for_xml("""
<node>
  <interface name="org.bluez.Agent1">
    <method name="Release"/>
    <method name="RequestPinCode">
      <arg type="o" direction="in"/><arg type="s" direction="out"/>
    </method>
    <method name="DisplayPinCode">
      <arg type="o" direction="in"/><arg type="s" direction="in"/>
    </method>
    <method name="RequestPasskey">
      <arg type="o" direction="in"/><arg type="u" direction="out"/>
    </method>
    <method name="DisplayPasskey">
      <arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/>
    </method>
    <method name="RequestConfirmation">
      <arg type="o" direction="in"/><arg type="u" direction="in"/>
    </method>
    <method name="RequestAuthorization">
      <arg type="o" direction="in"/>
    </method>
    <method name="AuthorizeService">
      <arg type="o" direction="in"/><arg type="s" direction="in"/>
    </method>
    <method name="Cancel"/>
  </interface>
</node>
""").interfaces[0]

# Agent methods that wait on the user, by the request kind the dropdown shows.
KINDS = {
    "RequestConfirmation": "confirm",
    "RequestAuthorization": "pair",
    "RequestPinCode": "pin",
    "RequestPasskey": "passkey",
    "AuthorizeService": "service",
}

# Profiles a device asks to connect, by the 16-bit part of their UUID.
SERVICES = {
    "1105": "file transfer",
    "1108": "calls",
    "110a": "audio",
    "110b": "audio",
    "110c": "media controls",
    "110e": "media controls",
    "1112": "calls",
    "1115": "networking",
    "1116": "networking",
    "111e": "calls",
    "111f": "calls",
    "1124": "input",
}


class Agent:
    def __init__(self, bus, loop):
        self.bus = bus
        self.loop = loop
        self.bluez = None  # bluetoothd's unique bus name; only it may call the agent
        self.pending = {}  # request id -> (invocation, method)
        self.last_id = 0
        bus.register_object(AGENT_PATH, INTERFACE, self.on_call)

    def emit(self, message):
        print(json.dumps(message), flush=True)

    def device(self, path):
        """The device's Device1 properties, or {} once it is gone."""
        try:
            reply = self.bus.call_sync(
                "org.bluez",
                path,
                "org.freedesktop.DBus.Properties",
                "GetAll",
                GLib.Variant("(s)", ("org.bluez.Device1",)),
                GLib.VariantType("(a{sv})"),
                Gio.DBusCallFlags.NONE,
                2000,
                None,
            )
        except GLib.Error:
            return {}
        return reply.unpack()[0]

    def on_bluez(self, bus, name, owner):
        self.bluez = owner
        try:
            for method, args in (
                ("RegisterAgent", GLib.Variant("(os)", (AGENT_PATH, CAPABILITY))),
                ("RequestDefaultAgent", GLib.Variant("(o)", (AGENT_PATH,))),
            ):
                bus.call_sync(
                    "org.bluez",
                    "/org/bluez",
                    "org.bluez.AgentManager1",
                    method,
                    args,
                    None,
                    Gio.DBusCallFlags.NONE,
                    -1,
                    None,
                )
        except GLib.Error as error:
            print(f"bluetooth-agent: {error.message}", file=sys.stderr)

    def on_bluez_gone(self, bus, name):
        self.bluez = None
        self.cancel()

    def cancel(self):
        for invocation, _ in self.pending.values():
            invocation.return_dbus_error("org.bluez.Error.Canceled", "Canceled")
        if self.pending:
            self.pending.clear()
            self.emit({"kind": "cancel"})

    def on_call(self, bus, sender, path, interface, method, params, invocation):
        if sender != self.bluez:
            invocation.return_dbus_error(REJECTED, "Only bluetoothd may use this agent")
            return
        if method in ("Release", "Cancel"):
            if method == "Cancel":
                self.cancel()
            invocation.return_value(None)
            return

        args = params.unpack()
        props = self.device(args[0])
        about = {
            "device": args[0],
            "name": props.get("Alias") or props.get("Address") or "Unknown device",
        }
        if method in ("DisplayPasskey", "DisplayPinCode"):
            passkey = method == "DisplayPasskey"
            code = f"{args[1]:06d}" if passkey else args[1]
            entered = args[2] if passkey else 0
            self.emit({"kind": "display", **about, "code": code, "entered": entered})
            invocation.return_value(None)
        elif method == "AuthorizeService" and props.get("Bonded"):
            invocation.return_value(None)
        else:
            self.last_id += 1
            self.pending[self.last_id] = (invocation, method)
            message = {"id": self.last_id, "kind": KINDS[method], **about}
            if method == "RequestConfirmation":
                message["code"] = f"{args[1]:06d}"
            elif method == "AuthorizeService":
                message["service"] = SERVICES.get(args[1][4:8].lower(), "")
            self.emit(message)

    def on_answer(self, channel, condition):
        line = channel.readline()
        if not line:  # Quickshell closed stdin: it exited or reloaded
            self.loop.quit()
            return False
        try:
            answer = json.loads(line)
            invocation, method = self.pending.pop(answer["id"])
        except (ValueError, KeyError, TypeError):
            return True  # a request bluetoothd already cancelled
        value = str(answer.get("value", ""))
        if not answer.get("accept"):
            invocation.return_dbus_error(REJECTED, "Rejected by the user")
        elif method == "RequestPinCode" and 1 <= len(value) <= 16:
            invocation.return_value(GLib.Variant("(s)", (value,)))
        elif method == "RequestPasskey" and value.isdigit() and int(value) <= 999999:
            invocation.return_value(GLib.Variant("(u)", (int(value),)))
        elif method in ("RequestPinCode", "RequestPasskey"):
            invocation.return_dbus_error(REJECTED, "Invalid code")
        else:
            invocation.return_value(None)
        return True


def main():
    loop = GLib.MainLoop()
    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM)
    agent = Agent(bus, loop)
    # Registers now and again whenever bluetoothd restarts.
    Gio.bus_watch_name_on_connection(
        bus,
        "org.bluez",
        Gio.BusNameWatcherFlags.NONE,
        agent.on_bluez,
        agent.on_bluez_gone,
    )
    stdin = GLib.IOChannel.unix_new(sys.stdin.fileno())
    GLib.io_add_watch(
        stdin,
        GLib.PRIORITY_DEFAULT,
        GLib.IOCondition.IN | GLib.IOCondition.HUP,
        agent.on_answer,
    )
    loop.run()


if __name__ == "__main__":
    main()
