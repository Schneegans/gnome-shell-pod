# Make sure the D-Bus knows where our display will be.
export DISPLAY=:99

# Start a custom session bus and export it's address.
eval "export $(/usr/bin/dbus-launch)"

# Run GNOME Shell in the background.
xvfb-run --server-args='-ac -screen 0 1600x900x24 -fbdir /home/gnomeshell' gnome-shell &