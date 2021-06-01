GNOME Shell container
=====================

Fedora container for testing GNOME Shell extensions on GitHub Actions (and also
locally).

Based on https://github.com/Schneegans/gnome-shell-pod

How to use
----------

1. Start the container using Podman, mount extension sources into
`~/.local/share/gnome-shell/extensions/`:

    SOURCE_DIR="${PWD}"
    EXTENSION_UUID="ddterm@amezin.github.com"
    IMAGE="ghcr.io/amezin/gnome-shell-pod-34:master"
    PACKAGE_MOUNTPATH="/home/gnomeshell/.local/share/gnome-shell/extensions/${EXTENSION_UUID}"

    POD=$(podman run --rm --cap-add=SYS_NICE --cap-add=IPC_LOCK -v "${SOURCE_DIR}:${PACKAGE_MOUNTPATH}:ro" -td "${IMAGE}")

2. Wait for user systemd and D-Bus to start:

    podman exec --user gnomeshell "${POD}" set-env.sh wait-user-bus.sh

3. Start GNOME Shell:

    podman exec --user gnomeshell "${POD}" set-env.sh systemctl --user start "gnome-xsession@:99"

This command starts X11 GNOME session. It is also possible to start a Wayland
session:

    podman exec --user gnomeshell "${POD}" set-env.sh systemctl --user start "gnome-wayland-nested@:99"

It still runs in Xvfb, but in nested mode. Without window manager running on
the "top level", the window has no decorations, and is effectively full screen.

4. Wait for GNOME Shell to complete startup:

    podman exec --user gnomeshell "${POD}" set-env.sh wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions

`org.gnome.Shell.Extensions` interface is necessary to enable the extension.

`wait-dbus-interface.sh` can be used to wait for any D-Bus interface to become
available. For example, if your extension exports a D-Bus interface, you could
use this script to wait for it.

5. Enable the extension:

    gnome-extensions enable "${EXTENSION_UUID}"

Example
-------

See https://github.com/amezin/gnome-shell-extension-ddterm:

- https://github.com/amezin/gnome-shell-extension-ddterm/blob/master/run_test_podman.sh

- https://github.com/amezin/gnome-shell-extension-ddterm/blob/master/.github/workflows/test.yml
