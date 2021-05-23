#!/bin/bash

# -------------------------------------------------------------------------------------- #
# This is a little helper script to install and enable a GNOME Shell extension in this   #
# container. It assumes that you have copied your extension package to /home/gnomeshell  #
# and that the package is called <UUID of the extnesion>.zip                             #
#                                                                                        #
# This could be done with the following command:                                         #
# podman cp foo@bar.org.zip $(podman ps -q -n 1):/home/gnomeshell/                       #
#                                                                                        #
# Then you can run this script inside of the container with:                             #
# podman exec --user gnomeshell $(podman ps -q -n 1) /home/gnomeshell/set-env.sh \       #
#              /home/gnomeshell/enable-extension.sh foo@bar.org                          #
# -------------------------------------------------------------------------------------- #

# Check that an argumemt is given.
if [ $# -eq 0 ]
  then
    echo "Please give the zip archive of your extension as parameter!"
    exit 0
fi

# Exit on error.
set -ex

UUID=$(unzip -p "$1" metadata.json | jq -r .uuid)

wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions -t 10

# First install the extension.
gnome-extensions install $1

# Then restart GNOME Shell. We wait some seconds afterwards to make sure that this has
# finished. Is there an easier way to reload newly installed extensions?
IS_WAYLAND="$(busctl --user call -j org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.is_wayland_compositor()' | jq -r '.data[1]')"

if [[ "$IS_WAYLAND" == "true" ]]; then
    systemctl --user restart 'gnome-wayland-nested@*'
    systemctl --user restart 'gnome-wayland-nested-highdpi@*'
else
    busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting…")'
fi

sleep 1
wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions -t 10

# Finally enable the extension.
gnome-extensions enable $UUID
